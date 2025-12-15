import 'package:apricus_lifestylee/Screens/Chat_Room_Widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PeerChatSelectionPage extends StatelessWidget {
  const PeerChatSelectionPage({super.key});

  final List<Map<String, dynamic>> chatRooms = const [
    {
      "id": "The Phoenix Nest 🔥", // Firestore-friendly ID
      "name": "The Phoenix Nest 🔥",
      "description": "Rebuilding after loss & grief.",
      "primaryColor": Colors.deepOrangeAccent,
      "secondaryColor": Colors.orangeAccent,
    },
    {
      "id": "The Lighthouse 💡",
      "name": "The Lighthouse 💡",
      "description": "A safe space for those battling depression.",
      "primaryColor": Colors.blueAccent,
      "secondaryColor": Colors.lightBlueAccent,
    },
    {
      "id": "Zen Den ☁️",
      "name": "Zen Den ☁️",
      "description": "Find peace and manage your anxiety here.",
      "primaryColor": Colors.deepPurpleAccent,
      "secondaryColor": Colors.purpleAccent,
    },
    {
      "id": "Level Up 🚀",
      "name": "Level Up 🚀",
      "description": "Self-improvement & personal growth.",
      "primaryColor": Colors.teal,
      "secondaryColor": Colors.blueGrey,
    },
    {
      "id": "Unfiltered Talks 🎭",
      "name": "Unfiltered Talks 🎭",
      "description": "A judgment-free space for open discussions.",
      "primaryColor": Colors.pinkAccent,
      "secondaryColor": Colors.deepOrangeAccent,
    },
  ];

  /// Function to join a chatroom and save it to Firestore
  Future<void> joinChatRoom(BuildContext context, Map<String, dynamic> chatRoom) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'joinedChatRoom': chatRoom["name"], // ✅ Stores name with emoji
          'chatroomId': chatRoom["id"], // ✅ Stores Firestore ID
        });

        // ✅ Fetch updated user document before navigating
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String updatedChatroomId = userDoc.data()?['chatroomId'] ?? '';

        if (updatedChatroomId.isEmpty) {
          throw Exception("Chatroom ID not found after update.");
        }

        // ✅ Navigate to Chatroom with correct chatroomId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomWidget(
              chatroomId: updatedChatroomId, // ✅ Pass correct chatroomId
              chatRoomName: chatRoom["name"], // Name WITH emoji
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error joining chatroom: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose a Peer Chat Room"),
        backgroundColor: Colors.amber.shade700, // Warmer theme
      ),
      body: ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          var chatRoom = chatRooms[index];
          return Card(
            color: chatRoom["primaryColor"].withOpacity(0.1), // Soft background effect
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                chatRoom["name"], // ✅ Displays Name with Emoji
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(chatRoom["description"]),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black54),
              onTap: () => joinChatRoom(context, chatRoom),
            ),
          );
        },
      ),
    );
  }
}
