import 'package:apricus_lifestylee/Screens/Chat_Room_Widget.dart';
import 'package:apricus_lifestylee/Screens/PeerChatSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apricus_lifestylee/Screens/userprofile_page.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  ClientHomePageState createState() => ClientHomePageState();
}

class ClientHomePageState extends State<ClientHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();


  String anonymousName = 'User';
  String mood = 'not set';
  String joinedChatroom = '';// Replace with actual value
  String? avatar =''; // Replace with actual value
  Map<String, bool> expandedStates = {};
  Map<String, bool> commentVisibility = {};




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
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; // Explicitly cast to a Map
        setState(() {
          anonymousName = userData?['anonymousName'] ?? 'User';
          mood = userData?['mood']?.toLowerCase() ?? 'not set';
          joinedChatroom = userData?['joinedChatRoom'] ?? ''; 
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMoodDisplay(),
            Expanded(child: _buildArticlesSection()), // Mood-Based Articles
          ],
        ),
      ),
    );
  }
  String _timeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hrs ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${time.day}/${time.month}/${time.year}';
    }


  /// 🔹 **Header Section - Displays Anonymous Name**
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
              'assets/logo.png',
              height: 50,  // Adjust size as needed
            ),
          Text(
            "Welcome, $anonymousName 👋",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black87, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 **Mood Display Section**
  Widget _buildMoodDisplay() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEB3B),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Your Current Mood:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              mood.toUpperCase(),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 10), // ✅ Corrected placement
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFBC02D), // Button color
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            print("Joined chatroom ID: $joinedChatroom");
            if (joinedChatroom.isNotEmpty) {
              // ✅ If user has joined a chatroom, navigate there
              DocumentSnapshot chatroomDoc = await _firestore
                .collection('chatRooms')
                .doc(joinedChatroom)
                .get();
              if (!chatroomDoc.exists) {
                print("Chatroom not found! Check Firestore database.");
                return;
              }
              if (chatroomDoc.exists) {
                Map<String, dynamic>? chatroomData = chatroomDoc.data() as Map<String, dynamic>?;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomWidget(
                      chatroomId: joinedChatroom, 
                      chatRoomName: joinedChatroom, // ✅ You can fetch actual name later
                    ),
                  ),
                );
            } 
          }
              else {
              // ✅ If user has not joined, navigate to chatroom selection
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PeerChatSelectionPage()),
              );
            }
          },
          child: Text(
            joinedChatroom.isNotEmpty ? "Go to Chatroom" : "Join a Chatroom",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}


  /// 🔹 **Mood-Based Articles Section**
  Widget _buildArticlesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('articles')
          .where('moodTags', arrayContains: mood)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No articles available for this mood.",
                  style: TextStyle(fontSize: 16)));
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var article = snapshot.data!.docs[index];
            var data = article.data() as Map<String, dynamic>;
            return _buildArticleCard(data, article.id);
          },
        );
      },
    );
  }

  /// 🔹 **Article Card (Includes Like & Comment Buttons)**
  Widget _buildArticleCard(Map<String, dynamic> article, String articleId) {
    bool isExpanded = expandedStates[articleId] ?? false;
    bool showComments = commentVisibility[articleId] ?? false;

    int likes = article['likes'] ?? 0;
    List<dynamic> comments = article['comments'] ?? [];
    String authorName = article['author'] ?? 'Anonymous';
    String? avatar = article['avatar']; // nullable now
    DateTime? timestamp = article['timestamp']?.toDate();

    return Card(
      color: const Color(0xFFFFF9C4), // Soft yellow
      elevation: 3,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 👤 Author Row
            Row(
              children: [
                avatar != null && avatar.isNotEmpty
                    ? CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(avatar),
                      )
                    : CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFFBC02D),
                        child: Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _timeAgo(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// 📝 Title & Content
            Text(
              article['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 8),
            Text(
            article['content'] ?? '',
            maxLines: isExpanded ? null : 5,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
            if ((article['content'] as String).length > 150)
              TextButton(
                child: Text(isExpanded ? "Read Less" : "Read More"),
                onPressed: () {
                  setState(() {
                    expandedStates[articleId] = !isExpanded;
                  });
                },
              ),

            const SizedBox(height: 16),

            /// ❤️‍🔥 Likes & Comments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 👍 Like
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      onPressed: () async {
                        await _firestore.collection('articles').doc(articleId).update({
                          'likes': FieldValue.increment(1),
                        });
                        setState(() {});
                      },
                    ),
                    Text(
                      likes.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                /// 💬 Comment Button
                TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
                  label: const Text("Comment"),
                  onPressed: () => _showCommentDialog(articleId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal.shade700,
                  ),
                ),
              ],
            ),

            /// 💭 Comments Preview (if any)
            TextButton.icon(
              icon: Icon(showComments ? Icons.expand_less : Icons.expand_more, color: Colors.teal),
              label: Text(showComments ? "Hide Comments" : "Show Comments"),
              onPressed: () {
                setState(() {
                  commentVisibility[articleId] = !showComments;
                });
              },
            ),
            if (showComments && comments.isNotEmpty) _buildCommentsSection(comments),

            // ✍️ Write a Comment Section
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟡 Avatar or Initial
                avatar != null && avatar!.isNotEmpty
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(avatar!),
                      )
                    : CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFFBC02D),
                        child: Text(
                          anonymousName.isNotEmpty ? anonymousName[0].toUpperCase() : '?',

                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(width: 10),

                // 🟡 Comment Box + Send
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: "Write a comment...",
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: () async {
                            final text = _commentController.text.trim();
                            if (text.isEmpty) return;

                            final newComment = {
                              'userName': anonymousName,
                              'avatar': avatar ?? '',
                              'text': text,
                              'timestamp': Timestamp.now(),
                            };

                            await _firestore.collection('articles').doc(articleId).update({
                              'comments': FieldValue.arrayUnion([newComment]),
                            });

                            _commentController.clear();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  /// 🔹 **Comment Button**
Widget _buildCommentsSection(List<dynamic> comments) {
  if (comments.isEmpty) return const SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(height: 24, thickness: 1, color: Colors.grey),
      const Text(
        "Comments",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Color(0xFF5D4037),
        ),
      ),
      const SizedBox(height: 10),

      ...comments.map<Widget>((comment) {
        String userName = comment['userName'] ?? 'Anonymous';
        String content = comment['text'] ?? '';
        String? avatar = comment['avatar'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar != null && avatar.isNotEmpty
                  ? CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(avatar),
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFBC02D),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}


  /// 🔹 **Comment Dialog with Fixed Timestamp**
  void _showCommentDialog(String articleId) {
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add a Comment"),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: "Write your comment..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.isNotEmpty) {
                await _firestore.collection('articles').doc(articleId).set({
                  'comments': FieldValue.arrayUnion([
                    {
                      'userName': anonymousName,
                      'avatar': avatar ?? '',
                      'text': commentController.text,
                      'timestamp': DateTime.now().toIso8601String(), // ✅ FIXED TIMESTAMP
                    }
                  ])
                }, SetOptions(merge: true)); // ✅ FIXED UPDATE ERROR
                Navigator.pop(context);
                setState(() {}); // Refresh UI
              }
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }
}

