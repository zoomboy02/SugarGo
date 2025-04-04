import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationScreen extends StatelessWidget { // screen to verify user account
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "An email has been sent to verify your account. Please check your inbox and verify your email address.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.currentUser!.sendEmailVerification(); // sends verification to users email
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Verification email resent.")));
                },
                child: const Text("Resend Email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
