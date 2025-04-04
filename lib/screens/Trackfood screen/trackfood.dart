import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackFoodScreen extends StatefulWidget {
  @override
  _TrackFoodScreenState createState() => _TrackFoodScreenState();
}

class _TrackFoodScreenState extends State<TrackFoodScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _selectedDate = DateTime.now();
  String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  String _selectedSort = "Time"; // Default sorting option

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSort = prefs.getString('selectedSort') ?? "Time";
      String? savedDate = prefs.getString('selectedDate');
      if (savedDate != null) {
        _selectedDate = DateTime.parse(savedDate);
      }
    });
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSort', _selectedSort);
    await prefs.setString('selectedDate', _selectedDate.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Food Logs',
          style: TextStyle(fontFamily: 'ABeeZee', fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          _buildCalendar(),
          _buildSortDropdown(), // Filter dropdown
          Expanded(child: _buildFoodLogs()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      focusedDay: _selectedDate,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {CalendarFormat.week: 'Week'},
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontFamily: 'ABeeZee', fontSize: 18),
      ),
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
        });
        _savePreferences(); // Save the selected date
      },
    );
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Sort by:",
            style: TextStyle(fontFamily: 'ABeeZee', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _selectedSort,
            items: ["Time", "Sugar: Highest", "Sugar: Lowest"]
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontFamily: 'ABeeZee')),
                    ))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSort = newValue!;
              });
              _savePreferences(); // Save the selected sorting option
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLogs() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('sugarLogs')
          .orderBy('time', descending: false) // Default ordering by time
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No food logs for this day.',
              style: TextStyle(fontFamily: 'ABeeZee', fontSize: 16),
            ),
          );
        }

        // Filter logs by selected date
        String formattedDate = DateFormat('yyyyMMdd').format(_selectedDate);
        var filteredLogs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime logDate = (data['time'] as Timestamp).toDate();
          return DateFormat('yyyyMMdd').format(logDate) == formattedDate;
        }).toList();

        // Sort logs based on selected filter
        if (_selectedSort == "Sugar: Highest") {
          filteredLogs.sort((a, b) {
            var sugarA = (a.data() as Map<String, dynamic>)['sugarLevel'] ?? 0;
            var sugarB = (b.data() as Map<String, dynamic>)['sugarLevel'] ?? 0;
            return sugarB.compareTo(sugarA); // Descending order
          });
        } else if (_selectedSort == "Sugar: Lowest") {
          filteredLogs.sort((a, b) {
            var sugarA = (a.data() as Map<String, dynamic>)['sugarLevel'] ?? 0;
            var sugarB = (b.data() as Map<String, dynamic>)['sugarLevel'] ?? 0;
            return sugarA.compareTo(sugarB); // Ascending order
          });
        }

        if (filteredLogs.isEmpty) {
          return Center(child: Text('No food logs for this day.'));
        }

        return ListView(
          children: filteredLogs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.all(8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: _getMealIcon(data['tag']),
                title: Text(
                  data['mealName'],
                  style: TextStyle(fontFamily: 'ABeeZee', fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  "${data['tag']} - ${data['sugarLevel']}g sugar",
                  style: TextStyle(fontFamily: 'ABeeZee', fontSize: 16),
                ),
                trailing: Text(
                  DateFormat.jm().format((data['time'] as Timestamp).toDate()),
                  style: TextStyle(fontFamily: 'ABeeZee', fontSize: 14, color: Colors.grey),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _getMealIcon(String tag) { // icons to display different types of meals, e.g breakfast, dinner , lunch
    switch (tag.toLowerCase()) {
      case 'breakfast':
        return Icon(Icons.free_breakfast, color: Colors.orange);
      case 'snack':
        return Icon(Icons.cookie, color: Colors.brown);
      case 'lunch':
        return Icon(Icons.lunch_dining, color: Colors.green);
      case 'dinner':
        return Icon(Icons.dinner_dining, color: Colors.red);
      case 'tea':
        return Icon(Icons.local_cafe, color: Colors.teal);
      default:
        return Icon(Icons.restaurant, color: Colors.blueGrey);
    }
  }
}
