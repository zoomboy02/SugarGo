import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMealScreen extends StatefulWidget {
  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>(); //  Created a GlobalKey that uniquely identifies the Form widget and allows validation
  String _mealName = '';
  String _selectedTag = 'Breakfast';
  String _sugarLevel = '';
  String _unit = 'g';
  DateTime? _selectedTime;

  final List<String> _tags = ['Breakfast', 'Snack', 'Lunch', 'Tea', 'Dinner']; // list of selectable meals


void _submit() async {
  if (_formKey.currentState!.validate()) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    double sugarInGrams = 0.0;
    try {
      sugarInGrams = double.parse(_sugarLevel);
      if (_unit == 'mg') {
        sugarInGrams /= 1000; // Convert mg to g
      }
    } catch (e) {
      print('Invalid sugar level input: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid sugar level')));
      return;
    }

    DateTime now = DateTime.now();
    String todayKey = DateFormat('yyyyMMdd').format(now); // Get the current date in YYYYMMDD format
    String selectedKey = _selectedTime != null ? DateFormat('yyyyMMdd').format(_selectedTime!) : todayKey; // Use selected date if available


    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Fetch existing user data
    DocumentSnapshot snapshot = await userDoc.get();

    // Ensure that the data is a Map before accessing
    Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;
    if (userData == null) {
      print('No user data found');
      return;
    }

    // Get existing `totalSugarPerDay` map, or initialize it as an empty map if it's null
    Map<String, dynamic> totalSugarPerDay = userData['totalSugarPerDay'] ?? {};

    // Initialize the updated daily sugar value
    double updatedDailySugar = sugarInGrams; // Default to the sugar level of the meal

    // Add or update sugar for the selected day
    if (totalSugarPerDay.containsKey(selectedKey)) {
      // If the selected day already has sugar logged, accumulate the sugar level
      double currentSugarForDay = totalSugarPerDay[selectedKey] ?? 0.0;
      updatedDailySugar = currentSugarForDay + sugarInGrams;
    }

    // Update the `totalSugarPerDay` for the selected day
    await userDoc.update({
      'totalSugarPerDay': {
        ...totalSugarPerDay,  // Keep existing data
        selectedKey: updatedDailySugar, // Add/update the selected day's sugar level
      },
    });
    print('Total sugar for $selectedKey updated to $updatedDailySugar');

    // Prepare the meal data
    Map<String, dynamic> mealData = {
      'mealName': _mealName,
      'tag': _selectedTag,
      'sugarLevel': sugarInGrams,
      'time': _selectedTime,
      'userId': user.uid,
      'updatedDailySugar': updatedDailySugar, // This will be the sugar level for the selected day
    };

    // Add meal data to the sugarLogs collection
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sugarLogs')
        .add(mealData)
        .then((docRef) {
      print('Meal added with ID: ${docRef.id}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Meal added successfully!')));
    }).catchError((error) {
      print('Error adding meal: $error');
    });
  }
}







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your meal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Abeezee'),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Meal Name',
                  border: OutlineInputBorder(),
                ),
                maxLength: 20,
                onChanged: (value) {
                  setState(() {
                    _mealName = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a meal name';
                  }
                  return null;
                },
                style: TextStyle(fontFamily: 'Abeezee'),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedTag,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  border: OutlineInputBorder(),
                ),
                items: _tags.map((String tag) {
                  return DropdownMenuItem<String>(
                    value: tag,
                    child: Text(tag, style: TextStyle(fontFamily: 'Abeezee')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTag = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Sugar level',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sugarLevel = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a sugar level';
                        }
                        if (value.contains(RegExp(r'[a-zA-Z\s]'))) {
                          return 'Sugar level cannot contain letters or spaces';
                        }
                        return null;
                      },
                      style: TextStyle(fontFamily: 'Abeezee'),
                    ),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _unit,
                    onChanged: (String? newValue) {
                      setState(() {
                        _unit = newValue!;
                      });
                    },
                    items: <String>['g', 'mg'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontFamily: 'Abeezee')),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  // Show the date picker
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    // Show the time picker after date is picked
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(pickedDate),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : '${_selectedTime!.toLocal()}',
                        style: TextStyle(fontFamily: 'Abeezee'),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Center(
                child: ElevatedButton(
                  onPressed: _mealName.isNotEmpty &&
                          _sugarLevel.isNotEmpty &&
                          _selectedTime != null
                      ? _submit
                      : null,
                  child: Text('Add Meal', style: TextStyle(fontFamily: 'Abeezee',color: const Color.fromARGB(255, 0, 0, 0),)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
