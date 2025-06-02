import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';

class VenueMapWidget extends StatelessWidget {
  final String currentBuilding;
  final String destination;
  final int estimatedWalkTime;

  const VenueMapWidget({
    Key? key,
    required this.currentBuilding,
    required this.destination,
    required this.estimatedWalkTime,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchVenueData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(destination)
          .get();

      if (doc.exists) {
        return doc.data()!;
      } else {
        throw Exception("Venue data not found");
      }
    } catch (e) {
      throw Exception("Error fetching venue data: $e");
    }
  }

  Future<void> _logNavigationHistory() async {
    try {
      await FirebaseFirestore.instance.collection('navigation_history').add({
        "currentBuilding": currentBuilding,
        "destination": destination,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error logging navigation history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchVenueData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          );
        }

        final venueData = snapshot.data!;
        final directions = venueData["directions"] as List<dynamic>? ?? [];

        return Stack(
          children: [
            // Map background
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.neutral100,
              child: CustomImageWidget(
                imageUrl: venueData["mapImageUrl"] ??
                    "https://images.unsplash.com/photo-1577702312572-5bb9328a9f15?q=80&w=1000&auto=format&fit=crop",
                fit: BoxFit.cover,
              ),
            ),

            // Navigation overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Directions to $destination',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const CustomIconWidget(
                            iconName: 'directions_walk',
                            color: AppTheme.primary600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${venueData["estimatedWalkTime"] ?? estimatedWalkTime} min walk',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'From your current location to $destination',
                                style: AppTheme.lightTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Directions steps
                    ...directions.asMap().entries.map((entry) {
                      final stepNumber = entry.key + 1;
                      final instruction = entry.value as String;
                      return _buildDirectionStep(
                        stepNumber: stepNumber,
                        instruction: instruction,
                        isLast: stepNumber == directions.length,
                      );
                    }).toList(),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const CustomIconWidget(
                          iconName: 'navigation',
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text('Start Navigation'),
                        onPressed: () {
                          _logNavigationHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Navigation started!"),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location markers
            Positioned(
              top: 100,
              left: 150,
              child: _buildLocationMarker(
                label: 'You are here',
                isCurrentLocation: true,
              ),
            ),
            Positioned(
              top: 200,
              right: 100,
              child: _buildLocationMarker(
                label: destination,
                isDestination: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectionStep({
    required int stepNumber,
    required String instruction,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instruction,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              if (!isLast) ...[
                Container(
                  margin: const EdgeInsets.only(left: 2, top: 4, bottom: 16),
                  width: 2,
                  height: 24,
                  color: AppTheme.primary200,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMarker({
    required String label,
    bool isCurrentLocation = false,
    bool isDestination = false,
  }) {
    final Color markerColor = isCurrentLocation
        ? AppTheme.primary600
        : isDestination
            ? AppTheme.success600
            : AppTheme.neutral600;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: markerColor.withAlpha(77),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
