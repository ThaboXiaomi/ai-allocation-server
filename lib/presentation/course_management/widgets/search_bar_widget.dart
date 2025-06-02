import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onSearchResults;

  const SearchBarWidget({
    Key? key,
    required this.onSearchResults,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      widget.onSearchResults([]);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('courses') // Replace with your collection name
          .where('keywords', arrayContains: query.toLowerCase())
          .get();

      final results = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();

      widget.onSearchResults(results);
    } catch (e) {
      print('Error performing search: $e');
      widget.onSearchResults([]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search courses, lecturers...",
              prefixIcon: const CustomIconWidget(
                iconName: 'search',
                color: AppTheme.neutral500,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.neutral500,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          widget.onSearchResults([]);
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              _performSearch(value);
            },
            onSubmitted: _performSearch,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
