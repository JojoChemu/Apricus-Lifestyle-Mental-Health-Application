import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apricus_lifestylee/Screens/PeerChatSelectionPage.dart';
import 'package:apricus_lifestylee/Screens/client_homepage.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String name = 'User';
  String avatarUrl = ''; // This will hold the asset path for the user's avatar.
  String joinedChatroom = '';
  List<Map<String, dynamic>> savedArticles = [];

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  /// Fetch user details and saved articles from Firestore.
  Future<void> fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          name = data?['anonymousName'] ?? 'User';
          avatarUrl = data?['avatar'] ?? ''; // Fetched avatar image.
          joinedChatroom = data?['joinedChatRoom'] ?? '';
        });

        // Fetch saved articles using a list of article IDs stored in 'savedArticles'
        List<String> articleIds =
            List<String>.from(data?['savedArticles'] ?? []);
        List<Map<String, dynamic>> articlesList = [];
        for (String id in articleIds) {
          DocumentSnapshot articleDoc =
              await _firestore.collection('articles').doc(id).get();
          if (articleDoc.exists) {
            articlesList.add(articleDoc.data() as Map<String, dynamic>);
          }
        }
        setState(() {
          savedArticles = articlesList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with a Home icon button to navigate back to the homepage.
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const ClientHomePage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileHeader(),
              _buildChatRoomSection(),
              _buildSavedArticlesSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile header shows the user's avatar and name.
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade200, Colors.yellow.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: avatarUrl.isNotEmpty
                ? AssetImage(avatarUrl)
                : const AssetImage('assets/fox.png'),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Button for chatroom functionality.
  /// If the user has already joined a chatroom, it shows "Go to Chatroom" (and navigates there);
  /// otherwise it shows "Join a Chatroom" (and navigates to the Peer Chat Selection page).
  Widget _buildChatRoomSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          if (joinedChatroom.isNotEmpty) {
            // Navigate to the specific chatroom.
            Navigator.pushNamed(context, '/chat-room',
                arguments: {'chatroomId': joinedChatroom, 'chatRoomName': joinedChatroom});
          } else {
            // Navigate to chatroom selection.
            Navigator.pushNamed(context, '/peer-chat-selection');
          }
        },
        icon: const Icon(Icons.chat),
        label: Text(joinedChatroom.isNotEmpty ? "Go to Chatroom" : "Join a Chatroom"),
      ),
    );
  }

  /// Displays saved articles in a creative and attractive list.
  Widget _buildSavedArticlesSection() {
    if (savedArticles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No saved articles yet.",
            style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(10),
          child: Text("Saved Articles",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: savedArticles.length,
          itemBuilder: (context, index) {
            var article = savedArticles[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(article['title'] ?? "Untitled",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(
                  article['content'] ?? "No content available",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.orange),
                onTap: () {
                  // Optionally, add a navigation to view the full article.
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
