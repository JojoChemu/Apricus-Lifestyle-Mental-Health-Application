import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'articles_page.dart'; // Import screen for publishing articles

class TherapistHomePage extends StatefulWidget {
  const TherapistHomePage({super.key});

  @override
  TherapistHomePageState createState() => TherapistHomePageState();
}

class TherapistHomePageState extends State<TherapistHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String therapistName = 'Therapist';
  String expertise = 'Mental Health';

  @override
  void initState() {
    super.initState();
    fetchTherapistDetails();
  }

  Future<void> fetchTherapistDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot therapistDoc = await _firestore.collection('therapists').doc(user.uid).get();
      if (therapistDoc.exists) {
        setState(() {
          therapistName = therapistDoc['name'] ?? 'Therapist';
          expertise = therapistDoc['expertise'] ?? 'Mental Health';
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
            _buildExpertiseDisplay(),
            Expanded(child: _buildArticlesSection()),
            _buildPublishButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF8D6E63),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Text(
        "Welcome, Dr. $therapistName 👩‍⚕️",
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildExpertiseDisplay() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology, color: Colors.orange, size: 24),
          const SizedBox(width: 10),
          Text("Expertise: $expertise",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildArticlesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('articles').where('authorRole', isEqualTo: 'therapist').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var articles = snapshot.data!.docs;
        if (articles.isEmpty) {
          return const Center(child: Text("No articles available. Publish your first article!"));
        }
        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            var article = articles[index];
            return ListTile(
              title: Text(article['title']),
              subtitle: Text(article['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
            );
          },
        );
      },
    );
  }

  Widget _buildPublishButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ArticlesPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        child: const Text("Publish Article", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
