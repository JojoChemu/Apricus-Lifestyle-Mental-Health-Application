// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'articles_page.dart'; // Import the article editor page

class TherapistProfilePage extends StatefulWidget {
  final String uid;
  final String role;
  const TherapistProfilePage({super.key, required this.uid, required this.role});

  @override
  State<TherapistProfilePage> createState() => _TherapistProfilePageState();
}

class _TherapistProfilePageState extends State<TherapistProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  String name = '';
  String title = '';
  List<DocumentSnapshot> articles = [];
  bool isEditing = false; // Track if editing mode is enabled

  @override
  void initState() {
    super.initState();
    fetchTherapistDetails();
  }

  Future<void> fetchTherapistDetails() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.uid).get();

      if (userDoc.exists) {
        var userData = userDoc.data();
        if (userData != null && userData is Map<String, dynamic>) {
          setState(() {
            name = userData['name'] ?? 'Therapist';
            title = userData['title'] ?? 'Therapist';
          });
        } else {
          print("User document is empty or has unexpected data structure.");
        }
      } else {
        print("User document does not exist.");
      }

      QuerySnapshot articlesSnapshot = await _firestore
          .collection('articles')
          .where('authorId', isEqualTo: widget.uid)
          .get();

      setState(() {
        articles = articlesSnapshot.docs;
      });
    } catch (e) {
      print("Error fetching therapist data: $e");
    }
  }


  Future<void> _editProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(widget.uid).update({
        'name': name,
        'title': title,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
    setState(() {
      isEditing = false; // Exit editing mode
    });
  }

  void _navigateToArticleEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ArticlesPage(articleId: '')),
    ).then((_) => fetchTherapistDetails()); // Refresh articles after writing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Therapist Profile"),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = !isEditing; // Toggle edit mode
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 10),
          _buildWriteArticleButton(),
          Expanded(child: _buildArticlesSection()),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          isEditing
              ? TextField(
                  decoration: const InputDecoration(labelText: "Name"),
                  onChanged: (value) => name = value,
                  controller: TextEditingController(text: name),
                )
              : Text("Name: $name", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          isEditing
              ? TextField(
                  decoration: const InputDecoration(labelText: "Title"),
                  onChanged: (value) => title = value,
                  controller: TextEditingController(text: title),
                )
              : Text("Title: $title", style: const TextStyle(fontSize: 16)),

          if (isEditing)
            ElevatedButton(
              onPressed: _editProfile,
              child: const Text("Save Changes"),
            ),
        ],
      ),
    );
  }

  Widget _buildWriteArticleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: _navigateToArticleEditor,
        icon: const Icon(Icons.edit),
        label: const Text("Write an Article"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    return articles.isEmpty
        ? const Center(child: Text("No articles written yet."))
        : ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              var data = articles[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Icon(Icons.arrow_forward, color: Colors.orange[700]),
                  onTap: () {
                    // Navigate to full article page (if needed)
                  },
                ),
              );
            },
          );
  }
}
