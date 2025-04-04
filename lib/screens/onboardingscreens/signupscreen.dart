import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; 
import 'verificationscreen.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _doPasswordsMatch = false;
  bool _isFirstNameValid = false;
  bool _isLastNameValid = false;

  String defaultProfileImageUrl = "https://i.pinimg.com/474x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg"; 
  File? _imageFile; // Variable to hold the selected image



  @override
  void initState() {
    super.initState();
    _checkFormValidity();
  }

  // Email validation
  void _validateEmail() {
    setState(() {
      _isEmailValid = _emailController.text.contains('@');
      _checkFormValidity();
    });
  }

  // Password validation
  void _validatePassword() {
    String password = _passwordController.text;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    setState(() {
      _isPasswordValid = password.length >= 8 && hasUppercase && hasSpecialCharacter;
      _checkFormValidity();
    });
  }

  // Password match validation
  void _validatePasswordMatch() {
    setState(() {
      _doPasswordsMatch = _passwordController.text == _confirmPasswordController.text;
      _checkFormValidity();
    });
  }

  // First name validation
  void _validateFirstName() {
    setState(() {
      _isFirstNameValid = _firstNameController.text.isNotEmpty && !_firstNameController.text.contains(' ');
      _checkFormValidity();
    });
  }

  // Last name validation
  void _validateLastName() {
    setState(() {
      _isLastNameValid = _lastNameController.text.isNotEmpty && !_lastNameController.text.contains(' ');
      _checkFormValidity();
    });
  }

  // Form validation check
  bool _isFormValid() {
    return _isFirstNameValid &&
        _isLastNameValid &&
        _isEmailValid &&
        _isPasswordValid &&
        _doPasswordsMatch;
  }

  // Rebuild the widget when form validity changes
  void _checkFormValidity() {
    setState(() {});
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setState(() {
      _imageFile = File(pickedFile.path);  // This assigns the picked image to  imageFile variable
    });

    // Now upload the image to Firebase Storage
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();  // Unique file name based on timestamp
      Reference storageReference = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      UploadTask uploadTask = storageReference.putFile(_imageFile!);

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        // Get the URL of the uploaded image
        String imageUrl = await storageReference.getDownloadURL();
        setState(() {
          defaultProfileImageUrl = imageUrl;  // Set the URL of the uploaded image
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error uploading image. Please try again.")));
    }
  }
}

Future<void> _createUserAccount() async {
  try {
    var result = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text);
    if (result.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email already exists. Please try another.")));
      return;
    }

    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Used profile image URL set during the image pick
    String profileImageUrl = defaultProfileImageUrl;

    // Upload to Firestore
    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'profileImage': profileImageUrl,  //   uploaded image URL
      'sugarLogs': [],
      'sugarTarget': 0.0, 
      'totalSugarPerDay': {},
      'calorieTarget': 0.0 ,// Store sugar target as a string
    });

    await userCredential.user!.sendEmailVerification();

    // Navigate to the verification screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const VerificationScreen()),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred during the signup process. Please try again")));
  }
}





  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Profile Image Picker
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) // Display  picked image
                            : NetworkImage(defaultProfileImageUrl) as ImageProvider, // Display  default image
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.add_a_photo),
                          onPressed: _pickImage, // Trigger image picker
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // First Name Text Field
                TextField(
                  controller: _firstNameController,
                  onChanged: (_) => _validateFirstName(),
                  decoration: InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _isFirstNameValid ? null : "First name cannot be empty or contain spaces.",
                  ),
                ),
                const SizedBox(height: 20),

                // Last Name Text Field
                TextField(
                  controller: _lastNameController,
                  onChanged: (_) => _validateLastName(),
                  decoration: InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _isLastNameValid ? null : "Last name cannot be empty or contain spaces.",
                  ),
                ),
                const SizedBox(height: 20),

                // Email Text Field
                TextField(
                  controller: _emailController,
                  onChanged: (_) => _validateEmail(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _isEmailValid ? null : "Enter a valid email",
                  ),
                ),
                const SizedBox(height: 20),

                // Password Text Field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (_) => _validatePassword(),
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _isPasswordValid ? null : "Password does not meet requirements",
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password Text Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  onChanged: (_) => _validatePasswordMatch(),
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    errorText: _doPasswordsMatch ? null : "Passwords do not match.",
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isFormValid() ? _createUserAccount : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(width, 50),
                    backgroundColor: _isFormValid() ? Colors.blue : Colors.grey,
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
