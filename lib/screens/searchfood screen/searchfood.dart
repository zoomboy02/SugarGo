import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FoodDetailScreen.dart';

class SearchFoodScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (RouteSettings settings) {
        WidgetBuilder builder;

        switch (settings.name) {
          case '/':
            builder = (BuildContext _) => SearchFoodMainContent();
            break;
          case '/foodDetails':
            final Map<String, dynamic> foodData = settings.arguments as Map<String, dynamic>;
            builder = (BuildContext _) => FoodDetailScreen(foodData);
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }

        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class SearchFoodMainContent extends StatefulWidget {
  @override
  _SearchFoodMainContentState createState() => _SearchFoodMainContentState();
}

class _SearchFoodMainContentState extends State<SearchFoodMainContent> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousSearch();
  }

  // Load previous search query and results from SharedPreferences
  Future<void> _loadPreviousSearch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedQuery = prefs.getString('searchQuery');
    if (savedQuery != null && savedQuery.isNotEmpty) {
      _searchController.text = savedQuery;
      _searchFood(savedQuery);
    } else {
      setState(() {
        _searchResults = []; // Clear results if no saved query
      });
    }
  }

  // Save search query and results to SharedPreferences
  Future<void> _saveSearchData(String query, List<dynamic> results) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isNotEmpty && results.isNotEmpty) {
      prefs.setString('searchQuery', query);
      prefs.setStringList('searchResults', results.map((e) => e.toString()).toList());
    } else {
      prefs.remove('searchQuery');
      prefs.remove('searchResults');
    }
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = []; // Clear results if query is empty
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await Dio().get(
        "https://world.openfoodfacts.org/cgi/search.pl",
        queryParameters: {
          "search_terms": query,
          "json": 1,
          "page_size": 10, // Limit results to 10, to prevent app from being unresponsive
        },
      );

      setState(() {
        _searchResults = response.data["products"] ?? [];
        _isLoading = false;
      });

      // Save the query and results to SharedPreferences
      _saveSearchData(query, _searchResults);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching food data: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Food', style: TextStyle(fontFamily: 'ABeeZee', fontSize: 20),
        ),
         
 
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(fontFamily: 'AbeeZee'),
              decoration: InputDecoration(
                labelText: "Search for food...",
                border: OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear(); // Clear search text
                            _searchResults = []; // Clear search results
                          });
                          _saveSearchData("", []); // Save the empty state to SharedPreferences
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchFood(_searchController.text);
                        } else {
                          setState(() {
                            _searchResults = []; // Clear results when search bar is empty
                          });
                          _saveSearchData("", []); // Save the empty state to SharedPreferences
                        }
                      },
                    ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchFood(value);
                } else {
                  setState(() {
                    _searchResults = []; // Clear results when search bar is empty
                  });
                  _saveSearchData("", []); // Save the empty state to SharedPreferences
                }
              },
            ),
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? "Enter a search term to find food."
                                  : "No food found for '${_searchController.text}'.",
                              style: TextStyle(fontSize: 16,  fontFamily: 'AbeeZee'),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              var food = _searchResults[index];
                              return Card(
                                child: ListTile(
                                  leading: food["image_url"] != null
                                      ? Image.network(food["image_url"], width: 50, height: 50)
                                      : Icon(Icons.fastfood),
                                  title: Text(food["product_name"] ?? "Unknown", style: TextStyle(fontFamily: 'AbeeZee')),
                                  subtitle: Text(food["brands"] ?? "No brand info", style: TextStyle(fontFamily: 'AbeeZee')),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FoodDetailScreen(food),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}