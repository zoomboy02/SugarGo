import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sugarlevels/screens/onboardingscreens/loginscreen.dart';
class SettingsScreen extends StatelessWidget {
   final Function(String?) onThemeChanged; 

  SettingsScreen({required this.onThemeChanged}); //  constructor
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;

        switch (settings.name) {
          case '/':
            builder = (BuildContext _) => SettingsMainScreen(onThemeChanged: onThemeChanged);
            break;
          
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
class SettingsMainScreen extends StatefulWidget {
   final Function(String?) onThemeChanged; 

  SettingsMainScreen({required this.onThemeChanged}); //  constructor
  @override
  _SettingsMainScreenState createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {

  String firstName = "";
  String lastName = "";
  String profileImageUrl = "";
  double sugarTarget = 0.0;
  bool isLoading = true;
 File? _imageFile;
   // Theme mode variables
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  final List<String> _themeOptions = ['System', 'Light', 'Dark'];
  @override
  void initState() {
    super.initState();
     _loadThemePreference(); // Load saved theme preference
    _fetchUserData();
  }
  // Load the theme from SharedPreferences
  // Load the saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('themeMode');
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
  }

  void _onThemeChanged(String? newValue) {
  if (newValue != null) {
    print("Theme changed to: $newValue"); // Debug log
    setState(() {
      _themeMode = newValue == 'Light'
          ? ThemeMode.light
          : newValue == 'Dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    });
    _saveThemePreference(newValue); // Save the selected theme
    widget.onThemeChanged(newValue); // Propagate the change to MyApp
  }
}

 Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageReference = FirebaseStorage.instance.ref().child('profile_images/$fileName');
        UploadTask uploadTask = storageReference.putFile(_imageFile!);

        await uploadTask.whenComplete(() async {
          String imageUrl = await storageReference.getDownloadURL();
          setState(() {
            profileImageUrl = imageUrl;
          });

          await _updateField('profileImage', imageUrl);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error uploading image. Please try again.")));
      }
    }
  }
  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            firstName = userDoc['firstName'] ?? "User";
            lastName = userDoc['lastName'] ?? "";
            profileImageUrl = userDoc['profileImage'] ?? "";
            sugarTarget = userDoc['sugarTarget'] ?? 0.0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> _updateField(String field, dynamic value) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Updating field: $field with value: $value');
      
      String path = 'users/${user.uid}';
      print('Firestore path: $path');
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({field: value});
      
      print('Field updated successfully');
      
      // Fetch the document again to verify the update
      DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      print('Updated Document: ${updatedDoc.data()}');
      
      _fetchUserData(); // Refresh data after update
    } else {
      print("No user is logged in");
    }
  } catch (e) {
    print("Error updating $field: $e");
  }
}




 // Edit first name
void _editFirstName() async {
  TextEditingController firstNameController = TextEditingController(text: firstName); // Create a controller

  final newFirstName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Edit First Name"),
      content: TextField(
        controller: firstNameController, // Use the controller to track input
        decoration: InputDecoration(hintText: "Enter new first name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            // Return the text from the controller (which holds the user input)
            Navigator.pop(context, firstNameController.text); 
          },
          child: Text("Save"),
        ),
      ],
    ),
  );

  if (newFirstName != null && newFirstName.isNotEmpty) {
    await _updateField('firstName', newFirstName);
  }
}



// Edit last name
void _editLastName() async {
  TextEditingController lastNameController = TextEditingController(text: lastName); //  controller 

  final newLastName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Edit Last Name"),
      content: TextField(
        controller: lastNameController, // Use the controller to track input
        decoration: InputDecoration(hintText: "Enter new last name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            // Return the text from the controller (which holds the user input)
            Navigator.pop(context, lastNameController.text); 
          },
          child: Text("Save"),
        ),
      ],
    ),
  );

  if (newLastName != null && newLastName.isNotEmpty) {
    await _updateField('lastName', newLastName);
  }
}

Future<void> _signOut(BuildContext context) async {
  try {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Clear 'isLoggedIn' from SharedPreferences to mark the user as logged out
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false); // Set 'isLoggedIn' to false

    // Replace the current screen with LoginScreen
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen(onThemeChanged: widget.onThemeChanged)),
    );
  } catch (e) {
    print("Error during logout: $e");
  }
}

void _editSugarTarget() async {
  TextEditingController sugarTargetController =
      TextEditingController(text: sugarTarget.toString());

  String? errorMessage; // To display validation errors

  final String? result = await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edit Sugar Target"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sugarTargetController,
                decoration: InputDecoration(
                  hintText: "Enter new sugar target",
                  errorText: errorMessage, // Show error if invalid
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String input = sugarTargetController.text.trim();
                double? parsedValue = double.tryParse(input);

                if (parsedValue != null) {
                  Navigator.pop(context, input); // Return as a string
                } else {
                  setState(() {
                    errorMessage = 'Please enter a valid number';
                  });
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      );
    },
  );

  if (result != null && result.isNotEmpty) {
    double? newSugarTarget = double.tryParse(result);
    if (newSugarTarget != null) {
      await _updateField('sugarTarget', newSugarTarget);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : AssetImage('assets/profile.png') as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  TextButton(
                   
                    onPressed: _pickImage,
                    child: Text(
                      'Change Photo',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'First Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: _editFirstName,
                ),
              ],
            ),
            Text(firstName),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: _editLastName,
                ),
              ],
            ),
            Text(lastName),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sugar Target',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: _editSugarTarget,
                ),
              ],
            ),
            Text('$sugarTarget g'),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Theme',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<String>(
  value: _themeMode == ThemeMode.system
      ? 'System'
      : _themeMode == ThemeMode.light
          ? 'Light'
          : 'Dark',
  onChanged: (newValue) {
    if (newValue != null) {
      _onThemeChanged(newValue); // Pass the selected value
    }
  },
  items: _themeOptions.map((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text(value),
    );
  }).toList(),
),
              ],
            ),
            Spacer(),
            

            Center(
              child: ElevatedButton(
  onPressed: () async {
    // Show confirmation dialog before logging out
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);  // User selected 'No'
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);  // User selected 'Yes'
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    // If the user confirms, sign out
    if (shouldLogout == true) {
      await _signOut(context);
    }
  },
  child: Text('Log out'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
  ),
),

            ),
          ],
        ),
      ),
    );
  }
}