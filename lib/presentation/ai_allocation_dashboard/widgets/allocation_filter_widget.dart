import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AllocationFilterWidget extends StatefulWidget {
  final String selectedFaculty;
  final String selectedBuilding;
  final String selectedTimeframe;
  final Function(String) onFacultyChanged;
  final Function(String) onBuildingChanged;
  final Function(String) onTimeframeChanged;

  const AllocationFilterWidget({
    Key? key,
    required this.selectedFaculty,
    required this.selectedBuilding,
    required this.selectedTimeframe,
    required this.onFacultyChanged,
    required this.onBuildingChanged,
    required this.onTimeframeChanged,
  }) : super(key: key);

  @override
  _AllocationFilterWidgetState createState() => _AllocationFilterWidgetState();
}

class _AllocationFilterWidgetState extends State<AllocationFilterWidget> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late Future<List<String>> facultiesFuture;
  late Future<List<String>> buildingsFuture;
  late Future<List<String>> timeframesFuture;

  @override
  void initState() {
    super.initState();
    facultiesFuture = _fetchFilterOptions('faculties');
    buildingsFuture = _fetchFilterOptions('buildings');
    timeframesFuture = _fetchFilterOptions('timeframes');
  }

  /// Fetch filter options from Firestore
  Future<List<String>> _fetchFilterOptions(String collectionName) async {
    try {
      final querySnapshot = await firestore.collection(collectionName).get();
      return querySnapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching $collectionName: $e');
      return [];
    }
  }

  /// Fetch additional filter options from Gemini API (optional)
  Future<List<String>> _fetchOptionsFromGeminiAPI(String endpoint) async {
    try {
      // Replace with your Gemini API endpoint
      final String apiUrl = 'https://api.gemini.com/$endpoint';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((item) => item['name'] as String).toList();
      } else {
        throw Exception('Failed to fetch data from Gemini API');
      }
    } catch (e) {
      print('Error fetching data from Gemini API: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<List<String>>(
            future: facultiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Error loading faculties.'));
              }
              return _buildFilterDropdown(
                'Faculty',
                widget.selectedFaculty,
                snapshot.data!,
                widget.onFacultyChanged,
                'school',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: buildingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Error loading buildings.'));
              }
              return _buildFilterDropdown(
                'Building',
                widget.selectedBuilding,
                snapshot.data!,
                widget.onBuildingChanged,
                'apartment',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: timeframesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Error loading timeframes.'));
              }
              return _buildFilterDropdown(
                'Timeframe',
                widget.selectedTimeframe,
                snapshot.data!,
                widget.onTimeframeChanged,
                'calendar_today',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> items,
    Function(String) onChanged,
    String iconName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.neutral600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.neutral300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              icon: const CustomIconWidget(
                iconName: 'keyboard_arrow_down',
                color: AppTheme.neutral600,
                size: 20,
              ),
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(8),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: iconName,
                        color: AppTheme.neutral600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
