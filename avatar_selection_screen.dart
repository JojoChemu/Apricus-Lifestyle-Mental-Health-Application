import 'package:apricus_lifestylee/Screens/therapistprofile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:apricus_lifestylee/Screens/mood_selection.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String uid;
  final String role;

  const AvatarSelectionScreen({super.key, required this.uid, required this.role});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> with SingleTickerProviderStateMixin {
  String? selectedAvatar;
  late AnimationController _controller;
  late Animation<double> _borderAnimation;

  final List<String> avatarList = [
    'assets/fox.png',
    'assets/rabbit.png',
    'assets/Chiken.png',
    'assets/dem.png',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _borderAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (selectedAvatar == null) {
      print("No avatar selected!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an avatar.")),
      );
      return;
    }

    try {
      print("Saving avatar to Firestore...");
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'avatar': selectedAvatar,
      });
      print("Avatar saved successfully!");

      if (!mounted) return;

      print("Navigating to the next screen...");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.role == "Therapist"
              ? TherapistProfilePage(uid: widget.uid, role: widget.role)
              : MoodSelectionScreen(uid: widget.uid),
        ),
      );
    } catch (e) {
      print("Error while saving avatar or navigating: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to continue. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      appBar: AppBar(
        title: const Text("Choose Your Avatar"),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: avatarList.map((avatarPath) {
                    final isSelected = selectedAvatar == avatarPath;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = avatarPath;
                          print("Avatar Selected: $selectedAvatar"); // Debug
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 140,
                        height: 170,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                            width: isSelected ? _borderAnimation.value : 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Center(
                              child: Image.asset(
                                avatarPath,
                                fit: BoxFit.contain,
                                height: 100,
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ),
                            if (isSelected)
                              const Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Selected",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedAvatar == null 
              ? null
              : () {
                  print("Continue Button Pressed!");  
                  _continue();
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                disabledBackgroundColor: Colors.orange[200],
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
