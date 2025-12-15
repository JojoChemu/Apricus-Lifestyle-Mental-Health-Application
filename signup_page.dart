import 'dart:developer';
import 'package:apricus_lifestylee/Screens/avatar_selection_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController anonymousNameController = TextEditingController();

  String? selectedAnonymousName;
  String selectedRole = 'Client';
  bool isLoading = false;
  List<String> anonymousNames = [
    "IamCool",
    "Wanderer",
    "LiveLoveLaugh",
    "dadada",
    "SilentEcho",
    "HiddenGem",
    "BraveSpirit",
    "DreamChaser",
    "SereneMind",
  ];
  List<String> usedNames = [];

  @override
  void initState() {
    super.initState();
    fetchUsedNames();
  }

  // Fetch already used names from Firestore
  Future<void> fetchUsedNames() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<String> takenNames = snapshot.docs.map((doc) => doc['anonymousName'] as String).toList();

      setState(() {
        usedNames = takenNames;
        anonymousNames = anonymousNames.where((name) => !usedNames.contains(name)).toList();
      });
    } catch (e) {
      log("❌ Error fetching used names: $e");
    }
  }

  // Check if anonymous name is already taken
  Future<bool> isNameTaken(String name) async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('anonymousName', isEqualTo: name)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> signup() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String finalName = anonymousNameController.text.isNotEmpty
        ? anonymousNameController.text.trim()
        : selectedAnonymousName ?? "";

    if (email.isEmpty || password.isEmpty || finalName.isEmpty) {
      log("⚠️ Signup Failed: Fields cannot be empty");
      return;
    }

    if (!_isPasswordValid(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be 8+ characters and include a special character!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if the name is already taken before creating the user
      if (await isNameTaken(finalName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This anonymous name is already taken. Please choose another.")),
        );
        setState(() => isLoading = false);
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'anonymousName': finalName,
          'email': email,
          'role': selectedRole,
          'mood': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 🔹 Only remove the selected name **after successful signup**
        setState(() {
          anonymousNames.remove(finalName);
        });

        if (mounted) {
          log("✅ Signup successful! Redirecting to Mood Selection...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AvatarSelectionScreen(
                uid: userCredential.user!.uid,
                role: 'client',
              ),
            ),
          );
        }
      }
    } catch (e) {
      log("🔥 Signup Failed: $e");
    }

    setState(() => isLoading = false);
  }

  // Password validation function
  bool _isPasswordValid(String password) {
    return password.length >= 8 && RegExp(r'[\W_]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 100,  // Adjust size as needed
                ),
                const SizedBox(height: 10),
                Text("Sign Up", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                const SizedBox(height: 20),

                // Anonymous Name Dropdown
                if (anonymousNames.isNotEmpty) ...[
                  DropdownButton<String>(
                    value: anonymousNames.contains(selectedAnonymousName) ? selectedAnonymousName : null,
                    hint: const Text("Select an Anonymous Name"),
                    items: anonymousNames.map((name) {
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAnonymousName = value!;
                        anonymousNameController.text = value;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 10),
                Text("Or create your own anonymous name:"),

                _buildTextField(anonymousNameController, "Enter Anonymous Name"),
                const SizedBox(height: 15),

                _buildTextField(emailController, "Email"),
                const SizedBox(height: 15),

                _buildTextField(passwordController, "Password", obscureText: true),
                const SizedBox(height: 15),

                DropdownButton<String>(
                  value: selectedRole,
                  items: ['Client', 'Therapist'].map((String role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),

                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
