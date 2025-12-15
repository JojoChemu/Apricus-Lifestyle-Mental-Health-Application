import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticlesPage extends StatefulWidget {
  final String? articleId;
  const ArticlesPage({super.key, this.articleId});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  String? selectedMood; // 1. Declare selectedMood

final List<Map<String, String>> moods = [ // 2. Declare moods
  {'emoji': '😊', 'mood': 'happy'},
  {'emoji': '😔', 'mood': 'sad'},
  {'emoji': '😡', 'mood': 'angry'},
  {'emoji': '😰', 'mood': 'anxious'},
  {'emoji': '🤩', 'mood': 'excited'},
  {'emoji': '😌', 'mood': 'calm'},
  {'emoji': '😴', 'mood': 'tired'},
  {'emoji': '🥺', 'mood': 'lonely'},
];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String role = '';
  String mood = '';
  String anonymousName = '';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          role = userDoc['role'] ?? 'Unknown';
          mood = userDoc['mood']?.toLowerCase() ?? 'not set';
          anonymousName = userDoc['anonymousName'] ?? 'User';
        });
      }
    }
  }

  Future<void> postArticle() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = anonymousName;
    if (role == "Therapist") {
      DocumentSnapshot therapistDoc =
          await _firestore.collection('therapists').doc(user.uid).get();
      if (therapistDoc.exists) {
        userName = therapistDoc['name'] ?? anonymousName;
      }
    }

    await _firestore.collection('articles').add({
      'title': _titleController.text,
      'content': _contentController.text,
      'author': anonymousName,
      'authorName': userName,
      'authorRole': role,
      'timestamp': FieldValue.serverTimestamp(),
      'moodTags': [selectedMood?.toLowerCase()],//Error in selected mood...IDKW
      'likes': 0,
      'comments': []
    });


    _titleController.clear();
    _contentController.clear();
  }

  Stream<QuerySnapshot> getMoodBasedArticles() {
    if (role == "Therapist") {
      return _firestore
          .collection('articles')
          .where('author', isEqualTo: anonymousName)
          .snapshots();
    } else {
      return _firestore
          .collection('articles')
          .where('moodTags', arrayContains: mood)
          .snapshots();
    }
  }

  Future<void> _likeArticle(String articleId, int currentLikes) async {
    await _firestore.collection('articles').doc(articleId).update({
      'likes': currentLikes + 1,
    });
  }

  void _showCommentsDialog(String articleId) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController commentController = TextEditingController();
        return AlertDialog(
          title: const Text("Comments"),
          content: SizedBox(
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('articles').doc(articleId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      List<dynamic> comments = snapshot.data!['comments'] ?? [];
                      return ListView(
                        children: comments.map((comment) {
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.blue),
                            title: Text(comment['text']),
                            subtitle: Text("By ${comment['user']}"),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: "Write a comment..."),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () async {
                if (commentController.text.isNotEmpty) {
                  await _addComment(articleId, commentController.text);
                  commentController.clear();
                }
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addComment(String articleId, String commentText) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String userName = anonymousName;
    if (role == "Therapist") {
      DocumentSnapshot therapistDoc =
          await _firestore.collection('therapists').doc(user.uid).get();
      if (therapistDoc.exists) {
        userName = therapistDoc['name'] ?? anonymousName;
      }
    }

    await _firestore.collection('articles').doc(articleId).update({
      'comments': FieldValue.arrayUnion([{'user': userName, 'text': commentText}]),
    });
  }

Widget _buildArticleCard(String articleId, Map<String, dynamic> data) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'No Title',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "By ${data['authorName'] ?? 'Anonymous'}",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Text(
            data['content'] ?? 'No Content',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: (data['moodTags'] as List<dynamic>? ?? []).map((tag) {
              final emoji = moods.firstWhere((m) => m['mood']!.toLowerCase() == tag.toLowerCase(),//another error in firstWhere
                  orElse: () => {'emoji': '💬'})['emoji'];
              return Chip(
                label: Text('$emoji ${tag[0].toUpperCase()}${tag.substring(1)}'),
                backgroundColor: const Color(0xFFFFF176),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up, color: Colors.blue),
                    onPressed: () => _likeArticle(articleId, data['likes'] ?? 0),
                  ),
                  Text("${data['likes'] ?? 0} Likes"),
                ],
              ),
              TextButton(
                onPressed: () => _showCommentsDialog(articleId),
                child: const Text("Comments", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildArticleForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Post an Article",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedMood,//another error here..yap you guessed it on selectedMood
            decoration: const InputDecoration(
              labelText: "Select Mood",
              border: OutlineInputBorder(),
            ),
            items: moods.map((moodMap) {//another error on moods
              return DropdownMenuItem<String>(
                value: moodMap['mood']!,
                child: Text('${moodMap['emoji']} ${moodMap['mood']}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedMood = value;//and lastly...wiat for it...on selectedMood
                });
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Content",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: postArticle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBC02D),
              foregroundColor: Colors.white,
            ),
            child: const Text("Post Article"),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        title: const Text(
          "Articles",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFBC02D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (role == "Therapist") _buildArticleForm(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMoodBasedArticles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No articles available.",
                          style: TextStyle(fontSize: 16)));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildArticleCard(doc.id, data);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
