import 'package:flutter/material.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;

  FoodDetailScreen(this.foodData);

  @override
  _FoodDetailScreenState createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  String _selectedUnit = '100g'; // Default unit
  Map<String, dynamic> _nutriments = {};

  @override
  void initState() {
    super.initState();
    _nutriments = widget.foodData['nutriments'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.foodData["product_name"] ?? "Food Details",
          style: TextStyle(fontFamily: 'AbeeZee'),
        ),
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: widget.foodData["image_url"] != null
              ? Image.network(widget.foodData["image_url"], height: 150)
              : Icon(Icons.fastfood, size: 100),
        ),
        SizedBox(height: 10),
        Text(
          "Product: ${widget.foodData["product_name"] ?? "Unknown"}",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'AbeeZee'),
        ),
        Text(
          "Brand: ${widget.foodData["brands"] ?? "No brand info"}",
          style: TextStyle(fontSize: 16, fontFamily: 'AbeeZee'),
        ),
        SizedBox(height: 10),

        // Dropdown for selecting unit
        DropdownButton<String>(
          value: _selectedUnit,
          items: <String>['100g', 'per serving']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(fontFamily: 'AbeeZee')),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedUnit = newValue!;
            });
          },
        ),

        SizedBox(height: 10),

        // Display nutrition info
        _buildNutritionInfo(Icons.cake, "Sugar", _selectedUnit),
        _buildNutritionInfo(Icons.local_fire_department, "Calories", _selectedUnit),
        _buildNutritionInfo(Icons.fastfood, "Fat", _selectedUnit),
        _buildNutritionInfo(Icons.fitness_center, "Protein", _selectedUnit),
        _buildNutritionInfo(Icons.grain, "Carbs", _selectedUnit),
      ],
    ),
  ),
),

    );
  }

  Widget _buildNutritionInfo(IconData icon, String label, String unit) {
    String key = _getNutrientKey(label, unit);
    String value = _nutriments[key]?.toString() ?? "N/A";
    String unitLabel = _getUnit(label);

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          "$label: $value $unitLabel",
          style: TextStyle(fontSize: 16, fontFamily: 'AbeeZee'),
        ),
        subtitle: Text("(${unit.toLowerCase()})", style: TextStyle(fontFamily: 'AbeeZee')),
      ),
    );
  }

  String _getUnit(String label) { // units for each label
    switch (label) {
      case 'Calories':
        return 'kcal';
      case 'Sugar':
      case 'Fat':
      case 'Protein':
      case 'Carbs':
        return 'g';
      default:
        return '';
    }
  }

  String _getNutrientKey(String label, String unit) {
    switch (label) {
      case 'Sugar':
        return unit == '100g' ? 'sugars_100g' : 'sugars_serving';
      case 'Calories':
        return unit == '100g' ? 'energy-kcal_100g' : 'energy-kcal_serving';
      case 'Fat':
        return unit == '100g' ? 'fat_100g' : 'fat_serving';
      case 'Protein':
        return unit == '100g' ? 'proteins_100g' : 'proteins_serving';
      case 'Carbs':
        return unit == '100g' ? 'carbohydrates_100g' : 'carbohydrates_serving';
      default:
        return '';
    }
  }
}
