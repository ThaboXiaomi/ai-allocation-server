import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Add this for blur effects
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class VenueMapWidget extends StatelessWidget {
  final String fromVenue;
  final String toVenue;

  const VenueMapWidget({
    Key? key,
    required this.fromVenue,
    required this.toVenue,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchVenueDetails(String venue) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('venues')
              .doc(venue)
              .get();

      if (snapshot.exists) {
        return snapshot.data()!;
      } else {
        throw Exception('Venue details not found.');
      }
    } catch (e) {
      debugPrint('Error fetching venue details: $e');
      return {};
    }
  }

  static const LatLng lerotholiPolytechnic = LatLng(-29.3167, 27.4833);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _fetchVenueDetails(fromVenue),
        _fetchVenueDetails(toVenue),
      ]).then((results) => {
            'from': results[0],
            'to': results[1],
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading venue details.'));
        }

        final fromDetails = snapshot.data!['from'];
        final toDetails = snapshot.data!['to'];

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neutral300, width: 1.5),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Google Map background
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: lerotholiPolytechnic,
                    zoom: 17,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('lerotholi'),
                      position: lerotholiPolytechnic,
                      infoWindow: const InfoWindow(
                        title: 'Lerotholi Polytechnic',
                        snippet: 'Maseru, Lesotho',
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  liteModeEnabled: true, // Optional: for a lightweight map
                  mapType: MapType.normal,
                  onMapCreated: (controller) {},
                ),
              ),

              // Soft overlay for glass effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        // ignore: deprecated_member_use
                        Colors.white.withOpacity(0.08),
                        // ignore: deprecated_member_use
                        Colors.black.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Map overlay with route
              Positioned.fill(
                child: CustomPaint(
                  painter: RoutePainter(
                    fromPosition: Offset(
                      fromDetails['x'] ?? 0.0,
                      fromDetails['y'] ?? 0.0,
                    ),
                    toPosition: Offset(
                      toDetails['x'] ?? 0.0,
                      toDetails['y'] ?? 0.0,
                    ),
                  ),
                ),
              ),

              // From marker
              Positioned(
                left: fromDetails['x'] ?? 0.0,
                top: fromDetails['y'] ?? 0.0,
                child: _buildMarker(
                  venue: fromVenue,
                  isOrigin: true,
                ),
              ),

              // To marker
              Positioned(
                left: toDetails['x'] ?? 0.0,
                top: toDetails['y'] ?? 0.0,
                child: _buildMarker(
                  venue: toVenue,
                  isOrigin: false,
                ),
              ),

              // Glassmorphic Legend
              Positioned(
                top: 24,
                right: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buildings',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem('A Block', AppTheme.primary600),
                          _buildLegendItem('B Block', AppTheme.success600),
                          _buildLegendItem('C Block', AppTheme.warning600),
                          _buildLegendItem('D Block', AppTheme.info600),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarker({required String venue, required bool isOrigin}) {
    final Color markerColor = isOrigin ? AppTheme.error600 : AppTheme.success600;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                markerColor.withOpacity(0.95),
                markerColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: markerColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: CustomIconWidget(
            iconName: isOrigin ? 'location_off' : 'location_on',
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: markerColor.withOpacity(0.10),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            venue,
            style: TextStyle(
              color: markerColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(20, 10),
          painter: MarkerTrianglePainter(
            color: markerColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.95),
                  color.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final Offset fromPosition;
  final Offset toPosition;

  RoutePainter({
    required this.fromPosition,
    required this.toPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint routePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.warning600.withOpacity(0.85),
          AppTheme.primary600.withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(fromPosition, toPosition))
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(fromPosition.dx, fromPosition.dy);
    path.lineTo(toPosition.dx, toPosition.dy);

    canvas.drawShadow(path, Colors.black.withOpacity(0.18), 6, false);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MarkerTrianglePainter extends CustomPainter {
  final Color color;

  MarkerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
