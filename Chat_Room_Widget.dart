import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomWidget extends StatefulWidget {
  final String chatroomId; // Use chatroom ID
  final String chatRoomName;

  const ChatRoomWidget({
    super.key,
    required this.chatroomId,
    required this.chatRoomName,
  });

  @override
  _ChatRoomWidgetState createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String userAnonymousName = "Anonymous"; // Default anonymous name
  String userAvatar = ""; // Will hold the avatar path or URL (if any)
  Color primaryColor = Colors.grey;  // Default color (will update from Firestore)
  Color secondaryColor = Colors.grey;  // Default color (will update from Firestore)

  @override
  void initState() {
    super.initState();
    if (widget.chatroomId.isNotEmpty) {
      _fetchChatRoomData();
    }
  }

  /// Fetch chat room data and user info from Firestore.
  Future<void> _fetchChatRoomData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch user's anonymous name and avatar.
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          userAnonymousName = userDoc.data()?['anonymousName'] ?? "Anonymous";
          userAvatar = userDoc.data()?['avatar'] ?? ""; // Update with avatar field
        });

        // Fetch chat room colors from Firestore and convert hex to Color.
        var chatRoomDoc =
            await _firestore.collection('chatRooms').doc(widget.chatroomId).get();
        if (chatRoomDoc.exists) {
          setState(() {
            primaryColor = _hexToColor(chatRoomDoc['primaryColor'] ?? "#808080");
            secondaryColor = _hexToColor(chatRoomDoc['secondaryColor'] ?? "#B0BEC5");
          });
        }

        // Ensure user is added to chatroom members (if not already added).
        var memberRef = _firestore.collection('chatRooms')
            .doc(widget.chatroomId)
            .collection('members')
            .doc(user.uid);
        var memberDoc = await memberRef.get();
        if (!memberDoc.exists) {
          await memberRef.set({
            'anonymousName': userAnonymousName,
            'avatar': userAvatar,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Error fetching chat room data: $e");
    }
  }

  /// Convert hex color string to Color.
  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    return Color(int.parse("0xFF$hex"));
  }

  /// Send a message to the chat room.
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('chatRooms')
            .doc(widget.chatroomId)
            .collection('messages')
            .add({
          'text': _messageController.text.trim(),
          'sender': userAnonymousName,
          'uid': user.uid,
          'avatar': userAvatar, // Save avatar along with message
          'timestamp': FieldValue.serverTimestamp(),
        });
        _messageController.clear();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no chatroomId is provided, show an error message.
    if (widget.chatroomId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chat Room"),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text(
            "Error: Chatroom ID is missing.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomName),
        backgroundColor: primaryColor,
        actions: [
          // Home button leading to the homepage
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              // Navigate to homepage; adjust route if needed
              Navigator.pushReplacementNamed(context, '/client-home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages list.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(widget.chatroomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet. Be the first to say something!",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['uid'] == _auth.currentUser?.uid;
                    // Display message as a Row with a CircleAvatar
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // If message is not from the current user, display sender's avatar on the left.
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: (message.data() as Map<String, dynamic>)['avatar'] != null &&
                                          ((message.data() as Map<String, dynamic>)['avatar'] as String).isNotEmpty
                                      ? AssetImage((message.data() as Map<String, dynamic>)['avatar'])
                                      : null,
                                  child: (((message.data() as Map<String, dynamic>)['avatar'] as String?) == null ||
                                          ((message.data() as Map<String, dynamic>)['avatar'] as String).isEmpty)
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              ),
                            // Message bubble
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe ? primaryColor : secondaryColor,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['sender'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isMe ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // If the message is from the current user, display avatar on the right.
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: userAvatar.isNotEmpty
                                      ? AssetImage(userAvatar)
                                      : null,
                                  child: userAvatar.isEmpty ? const Icon(Icons.person) : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: primaryColor, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
