import 'package:flutter/material.dart';
import 'package:sugarlevels/screens/homescreen/homescreen.dart';
import 'package:sugarlevels/screens/Trackfood screen/trackfood.dart';
import 'package:sugarlevels/screens/searchfood screen/searchfood.dart';
import 'package:sugarlevels/screens/settings screen/settings.dart';



class MainScreen extends StatefulWidget {
    final Function(String?) onThemeChanged; 

  MainScreen({required this.onThemeChanged}); // constructor 
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Tracks the selected tab

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of main screens for bottom navigation
    List<Widget> pages = [
      HomeScreen(onThemeChanged: widget.onThemeChanged),
      TrackFoodScreen(),
      SearchFoodScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped, // Handle navigation between tabs
        selectedItemColor: Colors.blue, // Highlight the selected icon
        unselectedItemColor: Colors.grey, // Grey out unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Track Food'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
