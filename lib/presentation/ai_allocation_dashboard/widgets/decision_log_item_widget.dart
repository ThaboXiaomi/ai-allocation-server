import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class DecisionLogItemWidget extends StatelessWidget {
  final Map<String, dynamic> decision;
  final VoidCallback onViewDetails;

  const DecisionLogItemWidget({
    Key? key,
    required this.decision,
    required this.onViewDetails,
  }) : super(key: key);

  /// Fetch decision details from Firestore
  Future<Map<String, dynamic>> _fetchDecisionDetails(String decisionId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('decisionLogs')
          .doc(decisionId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        throw Exception('Decision not found');
      }
    } catch (e) {
      print('Error fetching decision details: $e');
      return {};
    }
  }

  /// Fetch additional data from Gemini API (optional)
  Future<double> _fetchAIConfidenceFromGeminiAPI(String decisionId) async {
    try {
      // Replace with your Gemini API endpoint
      final String apiUrl = 'https://api.gemini.com/ai-confidence/$decisionId';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['confidence'] as double;
      } else {
        throw Exception('Failed to fetch AI confidence from Gemini API');
      }
    } catch (e) {
      print('Error fetching AI confidence from Gemini API: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isManual = decision['status'] == 'Manual';
    final Color statusColor =
        isManual ? AppTheme.warning600 : AppTheme.success600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: isManual ? 'person' : 'auto_awesome',
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          decision['action'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          decision['timestamp'],
                          style: const TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      decision['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                decision['description'],
                style: const TextStyle(
                  color: AppTheme.neutral700,
                  fontSize: 14,
                ),
              ),
              if (!isManual) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'AI Confidence:',
                      style: TextStyle(
                        color: AppTheme.neutral600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: decision['aiConfidence'],
                        backgroundColor: AppTheme.neutral200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConfidenceColor(decision['aiConfidence']),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(decision['aiConfidence'] * 100).toInt()}%',
                      style: TextStyle(
                        color: _getConfidenceColor(decision['aiConfidence']),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const CustomIconWidget(
                    iconName: 'visibility',
                    color: AppTheme.primary600,
                    size: 16,
                  ),
                  label: const Text('View Details'),
                  onPressed: () async {
                    // Fetch decision details from Firestore
                    final decisionDetails =
                        await _fetchDecisionDetails(decision['id']);
                    print('Decision Details: $decisionDetails');

                    // Optionally fetch AI confidence from Gemini API
                    final aiConfidence =
                        await _fetchAIConfidenceFromGeminiAPI(decision['id']);
                    print('AI Confidence: $aiConfidence');

                    // Trigger the onViewDetails callback
                    onViewDetails();
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppTheme.success600;
    } else if (confidence >= 0.6) {
      return AppTheme.primary600;
    } else if (confidence >= 0.4) {
      return AppTheme.warning600;
    } else {
      return AppTheme.error600;
    }
  }
}
