import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugarlevels/screens/homescreen/addmealscreen.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sugarlevels/screens/onboardingscreens/loginscreen.dart';

class HomeScreen extends StatelessWidget {
  final Function(String?) onThemeChanged; // Add this parameter
  HomeScreen({required this.onThemeChanged}); // Update constructor
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while Firebase initializes
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, show HomeMainContent
          return Navigator(
            onGenerateRoute: (RouteSettings settings) {
              WidgetBuilder builder;

              switch (settings.name) {
                case '/':
                  builder = (BuildContext _) => HomeMainContent();
                  break;
                case '/Addmeal':
                  builder = (BuildContext _) => AddMealScreen();
                  break;
                default:
                  throw Exception('Invalid route: ${settings.name}');
              }

              return MaterialPageRoute(builder: builder, settings: settings);
            },
          );
        } else {
          // User is not logged in, redirect to LoginScreen
          return LoginScreen(onThemeChanged: onThemeChanged);
        }
      },
    );
  }
}
class HomeMainContent extends StatefulWidget {
  @override
  _HomeMainContentState createState() => _HomeMainContentState();
}
class _HomeMainContentState extends State<HomeMainContent> {
  String firstName = "";
  String profileImageUrl = "";
double consumedSugar = 0;
  String selectedTimeFrame = 'Last 7 days'; // Default time frame
  List<FlSpot> sugarData = [];
   Map<String, double> totalSugarPerDay = {}; // Map to store total sugar per day
  List<BarChartGroupData> barGroups = []; // Data for the bar chart
bool isLoading = true; // Add a loading state

bool isConnected = true; // Track internet status
  @override
  void initState() {
    super.initState();
 
    _fetchUserData();

  }



Future<void> _fetchUserData() async {
  setState(() {
      isLoading = true; // Set loading to true when fetching data
    });
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          // Fetching user data
          firstName = userDoc['firstName'] ?? "User";
          profileImageUrl = userDoc['profileImage'] ?? "";
print("Fetched user data: ${userDoc.data()}");

          // Fetching totalSugarPerDay data and ensuring correct format
          var data = userDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('totalSugarPerDay')) {
            var sugarData = data['totalSugarPerDay'] as Map<String, dynamic>;

            // Safely convert values to double
            totalSugarPerDay = sugarData.map((key, value) {
              double sugarAmount = 0.0;
              if (value is String) {
                sugarAmount = double.tryParse(value) ?? 0.0; // Convert string to double if possible
              } else if (value is num) {
                sugarAmount = value.toDouble(); // If already a number, convert to double
              }
              return MapEntry(key, sugarAmount);
            });
          }
            isLoading = false; // Set loading to false after data is fetched
        });
      }
    }
  } catch (e) {
    print("Error fetching user data: $e");
    setState(() {
        isLoading = false; // Set loading to false even if there's an error
      });
  }
}
// This method handles the dropdown value change
  void _onTimeFrameChanged(String? newValue) {
    setState(() {
      selectedTimeFrame = newValue ?? selectedTimeFrame;
    });
  }
  void _showAddGlucoseTargetDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    bool isSaveButtonEnabled = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Enter Glucose Daily Target',
                style: TextStyle(
                  fontFamily: 'Abbeezee',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Enter a number',
                  hintStyle: TextStyle(
                    fontFamily: 'Abbeezee',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    isSaveButtonEnabled = value.isNotEmpty && double.tryParse(value) != null;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Abbeezee',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaveButtonEnabled
                      ? () {
                          double target = double.parse(_controller.text);
                          _saveGlucoseTarget(target);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSaveButtonEnabled ? Colors.blue : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Abbeezee',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveGlucoseTarget(double target) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'sugarTarget': target});
        print("Glucose target saved: $target");
      }
    } catch (e) {
      print("Error saving glucose target: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
     if (isLoading) {
      return Center(child: CircularProgressIndicator()); // Show loading indicator
    }
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 50),
            Text(
              "Hi, $firstName",
              style: TextStyle(
                fontFamily: 'Abbeezee',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : AssetImage("lib/images/default_group_icon.png") as ImageProvider,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildAddTargetButton(context);
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                double sugarTarget = (userData['sugarTarget'] ?? 0).toDouble();

                return sugarTarget == 0
                    ? _buildAddTargetButton(context)
                    : _buildGlucoseProgress(sugarTarget);
              },
            ),
            SizedBox(height:20),
             _buildSugarDataCard(),
            //
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/Addmeal');
        },
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
bool isBarChart = true; // Track which chart type is active

Widget _buildSugarDataCard() {
  List<FlSpot> lineChartData = [];
  List<BarChartGroupData> barGroups = [];

  DateTime now = DateTime.now();
  int daysBack = selectedTimeFrame == 'Last 7 days' ? 7 : 30; // Adjust based on selection
  DateTime startDate = now.subtract(Duration(days: daysBack));

  List<DateTime> days = List.generate(daysBack, (index) => startDate.add(Duration(days: index + 1)));

  for (var i = 0; i < days.length; i++) {
    String key = DateFormat('yyyyMMdd').format(days[i]);
    double sugarAmount = totalSugarPerDay[key] ?? 0.0;

    // Data for Bar Chart
    barGroups.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: sugarAmount,
            color: sugarAmount == 0.0 ? Colors.grey : Colors.blue,
            width: 16,
          ),
        ],
      ),
    );

    // Data for Line Chart
    lineChartData.add(FlSpot(i.toDouble(), sugarAmount));
  }

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sugar Consumption (g)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedTimeFrame,
                    items: ['Last 7 days', 'Last 30 days'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _onTimeFrameChanged,
                  ),
                  IconButton(
                    icon: Icon(isBarChart ? Icons.show_chart : Icons.bar_chart),
                    onPressed: () {
                      setState(() {
                        isBarChart = !isBarChart;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 250,
            child: isBarChart
                ? BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int dayIndex = value.toInt();
                              if (dayIndex >= 0 && dayIndex < days.length) {
                                return Text(DateFormat('MMM dd').format(days[dayIndex]));
                              }
                              return Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      barGroups: barGroups,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int dayIndex = value.toInt();
                              if (dayIndex >= 0 && dayIndex < days.length) {
                                return Text(DateFormat('MMM dd').format(days[dayIndex]));
                              }
                              return Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineChartData,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildAddTargetButton(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Center(
          child: ElevatedButton(
            onPressed: () => _showAddGlucoseTargetDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add Glucose Daily Target',
              style: TextStyle(
                fontFamily: 'Abbeezee',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }



Widget _buildGlucoseProgress(double sugarTarget) {
  User? user = FirebaseAuth.instance.currentUser;

  // Fetch today's sugar from Firestore
  Future<double> fetchTodaySugar() async {
    try {
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> totalSugarPerDay =
              Map<String, dynamic>.from(userDoc['totalSugarPerDay'] ?? {});
          String todayKey = DateFormat('yyyyMMdd').format(DateTime.now());
          return (totalSugarPerDay[todayKey] ?? 0).toDouble();
        }
      }
    } catch (e) {
      print("Error fetching today's sugar: $e");
    }
    return 0; // Return 0 if any error occurs
  }

  return FutureBuilder<double>(
    future: fetchTodaySugar(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error loading data'));
      }

      double consumedSugar = snapshot.data ?? 0;
      bool exceededTarget = consumedSugar > sugarTarget;
      double progress = (consumedSugar / sugarTarget).clamp(0.0, 1.0);
      Color progressColor = exceededTarget ? Colors.red : Colors.blue; // display red text if target has been exceeded

      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Abbeezee',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$consumedSugar grams of $sugarTarget grams',
                      style: TextStyle(
                        fontFamily: 'Abeezee',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exceededTarget)
                      Text(
                        'Daily sugar target has been exceeded!',
                        style: TextStyle(
                          fontFamily: 'Abeezee',
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 20),
                    Text( // displayed text 
                      'Grams (g) measure the amount of sugar or carbohydrates in food, helping track intake and its potential impact on blood sugar levels.',
                      style: TextStyle(
                        fontFamily: 'Abeezee',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



}

