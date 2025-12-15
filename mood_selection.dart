import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_homepage.dart';
import 'therapist_homepage.dart';

class MoodSelectionScreen extends StatefulWidget {
  final String uid;

  const MoodSelectionScreen({super.key, required this.uid});

  @override
  MoodSelectionScreenState createState() => MoodSelectionScreenState();
}

class MoodSelectionScreenState extends State<MoodSelectionScreen> {
  String? selectedMood;
  bool isSaving = false;

  // Mood Options with Emojis 🎭
  final List<Map<String, String>> moods = [
    {"mood": "Happy", "emoji": "😃"},
    {"mood": "Sad", "emoji": "😢"},
    {"mood": "Anxious", "emoji": "😟"},
    {"mood": "Excited", "emoji": "🤩"},
    {"mood": "Calm", "emoji": "😌"},
    {"mood": "Angry", "emoji": "😠"},
    {"mood": "Tired", "emoji": "😴"},
    {"mood": "Lonely", "emoji": "🥺"},
  ];

    Future<void> saveMood() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a mood.")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Reference to user document
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);

      // Save mood to mood_tracker subcollection
      await userRef.collection('mood_tracker').add({
        'mood': selectedMood,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's main mood field
      await userRef.update({'mood': selectedMood});

      // 🔍 Fetch role from Firestore
      DocumentSnapshot userDoc = await userRef.get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'];

      // 🎯 Navigate based on actual role value
      if (mounted) {
        if (role == "Therapist") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TherapistHomePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClientHomePage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save mood. Try again.\n$e")),
      );
    }

    setState(() => isSaving = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Mood"),
        backgroundColor: Colors.orange[800],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgroundmood.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.4), // Softens the background just a bit
          ),
          Center(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("How are you feeling today?", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: moods.map((moodData) {
                  bool isSelected = selectedMood == moodData["mood"];
                  return ChoiceChip(
                    label: Text(
                      "${moodData["emoji"]} ${moodData["mood"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedMood = selected ? moodData["mood"] : null;
                      });
                    },
                    backgroundColor: Colors.white.withOpacity(0.6),
                    selectedColor: Colors.orangeAccent.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.deepOrange : Colors.transparent,
                      ),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: saveMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      ),
                      child: const Text("Save Mood", style: TextStyle(fontSize: 16)),
                    ),
              ],
            ),
          ),
        ],
      ), 
    );
  }
}
