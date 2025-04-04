import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugarlevels/screens/onboardingscreens/onboardingscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:sugarlevels/widgets/bottomnavbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugarlevels/screens/onboardingscreens/loginscreen.dart';
import 'package:sugarlevels/widgets/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This Initialises Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // This enables Firestore caching
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Check if the user is logged in by FirebaseAuth
  User? currentUser = FirebaseAuth.instance.currentUser;

  // If there is no logged-in user, check SharedPreferences for login status
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = currentUser != null || (prefs.getBool('isLoggedIn') ?? false);
bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
  // Run the app with the correct screen based on login state
  runApp(MyApp(isLoggedIn: isLoggedIn, hasCompletedOnboarding: hasCompletedOnboarding,));
}

class MyApp extends StatefulWidget {
  final GlobalNavigationObserver _observer = GlobalNavigationObserver(); // Added observer (checks internet)
  final bool isLoggedIn;
final bool hasCompletedOnboarding;
  MyApp({Key? key, required this.isLoggedIn, required this.hasCompletedOnboarding}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
bool _hasCompletedOnboarding;

  _MyAppState() : _hasCompletedOnboarding = false;
  @override
  void initState() {
    super.initState();
    _hasCompletedOnboarding = widget.hasCompletedOnboarding;
    _loadThemePreference(); // Load saved theme preference
  }

  // Load the saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('themeMode');
    print("Loaded theme: $theme"); // Debug log
    setState(() {
      _themeMode = theme == 'light'
          ? ThemeMode.light
          : theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    });
  }

  // Save the selected theme preference to SharedPreferences
  Future<void> _saveThemePreference(String theme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', theme.toLowerCase());
    print("Theme saved: $theme"); // Debug log
  }

  // Handle theme change
  void _onThemeChanged(String? newValue) {
    if (newValue != null) {
      print("Theme changed to: $newValue"); // note to marker: Debug log (ignore)
      setState(() {
        _themeMode = newValue == 'Light'
            ? ThemeMode.light
            : newValue == 'Dark'
                ? ThemeMode.dark
                : ThemeMode.system;
      });
      _saveThemePreference(newValue); // Save the selected theme
    }
  }
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    setState(() {
      _hasCompletedOnboarding = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    print("MaterialApp rebuilding with theme: $_themeMode"); // Debug log
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sugar Tracker',
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: _themeMode, // Used  selected theme mode
      navigatorObservers: [widget._observer], 
       home: _hasCompletedOnboarding
          ? (widget.isLoggedIn
              ? MainScreen(onThemeChanged: _onThemeChanged)
              : LoginScreen(onThemeChanged: _onThemeChanged))
          : OnboardingScreen(onThemeChanged: _onThemeChanged, onOnboardingComplete: _completeOnboarding),
    );
  }
}