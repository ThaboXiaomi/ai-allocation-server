import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart' as ThemeAlias;
import '../../widgets/custom_icon_widget.dart' as CustomIcons;
import './widgets/allocation_card_widget.dart';
import './widgets/allocation_chart_widget.dart';
import './widgets/decision_log_item_widget.dart';
import './widgets/performance_indicator_widget.dart';
import './widgets/timeline_item_widget.dart';
import '../../services/allocation_initializer.dart'; // Add this import

// Moved Allocation class to the top level
class Allocation {
  final String id;
  final String eventName;
  final String description;
  final String room;
  final String status;
  final String decisionLog; // from decisionLogs
  final String timetable; // from timetables

  Allocation({
    required this.id,
    required this.eventName,
    required this.description,
    required this.room,
    required this.status,
    required this.decisionLog,
    required this.timetable,
  });
}

class AIAllocationDashboard extends StatefulWidget {
  const AIAllocationDashboard({Key? key}) : super(key: key);

  @override
  State<AIAllocationDashboard> createState() => _AIAllocationDashboardState();
}

class _AIAllocationDashboardState extends State<AIAllocationDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRealTimeUpdates = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize allocations collection if empty
    _initializeAllocationsIfNeeded();
  }

  Future<void> _initializeAllocationsIfNeeded() async {
    final allocationsSnapshot =
        await FirebaseFirestore.instance.collection('allocations').get();
    if (allocationsSnapshot.docs.isEmpty) {
      await initializeAllocationsCollection();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch allocations with related decisionLog and timetable
  Future<List<Allocation>> _fetchAllocationsWithDetails() async {
    final allocationsSnapshot =
        await FirebaseFirestore.instance.collection('allocations').get();

    List<Allocation> allocations = [];

    for (var doc in allocationsSnapshot.docs) {
      final data = doc.data();
      final allocationId = doc.id;

      // Fetch related decisionLog
      final decisionLogSnapshot = await FirebaseFirestore.instance
          .collection('decisionLogs')
          .where('allocationId', isEqualTo: allocationId)
          .limit(1)
          .get();
      final decisionLogData = decisionLogSnapshot.docs.isNotEmpty
          ? decisionLogSnapshot.docs.first.data()
          : null;

      String decisionLogText = decisionLogData != null
          ? decisionLogData['conflictDetails'] ?? 'No decision log details'
          : 'No decision log';

      // Fetch related timetable
      final timetableSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('allocationId', isEqualTo: allocationId)
          .limit(1)
          .get();

      final timetableData = timetableSnapshot.docs.isNotEmpty
          ? timetableSnapshot.docs.first.data()
          : null;

      String timetableText = timetableData != null
          ? timetableData['courseTitle'] ?? 'No timetable info'
          : 'No timetable';

      // Construct Allocation object
      allocations.add(Allocation(
        id: allocationId,
        eventName: data['eventName'] ?? 'No Event Name',
        description: data['description'] ?? '',
        room: data['room'] ?? '',
        status: data['status'] ?? '',
        decisionLog: decisionLogText,
        timetable: timetableText,
      ));
    }

    return allocations;
  }

  // Firestore streams for allocations and logs

  Stream<List<Map<String, dynamic>>> _fetchDecisionLogs() {
    return FirebaseFirestore.instance
        .collection('decisionLogs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
                'source': 'firebase',
              };
            }).toList());
  }

  Future<Map<String, dynamic>> _fetchPerformanceMetrics() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('performanceMetrics')
          .doc('metrics')
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        print('No performance metrics found.');
        return {};
      }
    } catch (e, stack) {
      print('Error loading performance metrics: $e');
      print('Stack trace: $stack');
      return {};
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchTimelineEvents() {
    return FirebaseFirestore.instance
        .collection('timelineEvents')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popAndPushNamed(context, '/admin-dashboard');
          },
        ),
        title: const Text('AI Allocation Dashboard'),
        actions: [
          Switch(
            value: _isRealTimeUpdates,
            onChanged: (value) {
              setState(() {
                _isRealTimeUpdates = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Real-time updates enabled'
                        : 'Real-time updates disabled',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text('Live'),
          IconButton(
            icon: const CustomIcons.CustomIconWidget(
              iconName: 'help_outline',
              color: Colors.white,
            ),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
          IconButton(
            icon: const CustomIcons.CustomIconWidget(
              iconName: 'home',
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/admin-dashboard');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Removed _buildFilterSection() call
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllocationTab(),
                  _buildPerformanceTab(),
                  _buildDecisionLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: Icon(Icons.event_seat, color: theme.colorScheme.primary),
            text: 'Allocations',
          ),
          Tab(
            icon: Icon(Icons.trending_up, color: theme.colorScheme.primary),
            text: 'Performance',
          ),
          Tab(
            icon: Icon(Icons.list_alt, color: theme.colorScheme.primary),
            text: 'Logs',
          ),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildAllocationTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllocationsWithFullDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading allocations: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No active allocations found.'));
        }
        final allocations = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Active & Recent Allocations",
                  style: ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allocations.length,
                itemBuilder: (context, index) {
                  final allocation = allocations[index];
                  // Defensive null checks for all expected fields
                  final safeAllocation = {
                    ...allocation,
                    'eventName': allocation['eventName'] ?? '',
                    'room': allocation['room'] ?? '',
                    'status': allocation['status'] ?? '',
                    'decisionLog': allocation['decisionLog'] ?? '',
                    'resolvedVenue': allocation['resolvedVenue'] ?? '',
                    'confidenceScore': allocation['confidenceScore'] ?? 0,
                    'description': allocation['description'] ?? '',
                    'distanceFactor': allocation['distanceFactor'] ?? 0,
                    'faculty': allocation['faculty'] ?? '',
                    'lecturer': allocation['lecturer'] ?? '',
                    'studentCount': allocation['studentCount'] ?? 0,
                    'timetable': allocation['timetable'] ?? '',
                    'time': allocation['time'] ?? '',
                  };
                  return AllocationCardWidget(
                    allocation: safeAllocation,
                    documentId: allocation['id'],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildTimelineSection(),
            ],
          ),
        );
      },
    );
  }

  // Add this new method to fetch all required fields for AllocationCardWidget
  Future<List<Map<String, dynamic>>> _fetchAllocationsWithFullDetails() async {
    final allocationsSnapshot =
        await FirebaseFirestore.instance.collection('allocations').get();

    List<Map<String, dynamic>> allocations = [];

    for (var doc in allocationsSnapshot.docs) {
      final data = doc.data();
      final allocationId = doc.id;

      // Fetch related decisionLog
      final decisionLogSnapshot = await FirebaseFirestore.instance
          .collection('decisionLogs')
          .where('allocationId', isEqualTo: allocationId)
          .limit(1)
          .get();
      final decisionLogData = decisionLogSnapshot.docs.isNotEmpty
          ? decisionLogSnapshot.docs.first.data()
          : {};

      // Fetch related timetable
      final timetableSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('allocationId', isEqualTo: allocationId)
          .limit(1)
          .get();
      final timetableData = timetableSnapshot.docs.isNotEmpty
          ? timetableSnapshot.docs.first.data()
          : {};

      // Merge all relevant fields into one map
      allocations.add({
        'id': allocationId,
        'course': timetableData['courseTitle'] ?? data['eventName'] ?? '',
        'lecturer': timetableData['lecturer'] ?? '',
        'faculty': timetableData['faculty'] ?? '',
        'time': timetableData['time'] ?? '',
        'room': data['room'] ?? '',
        'resolvedVenue': decisionLogData['suggestedVenue'] ?? '',
        'studentCount': timetableData['studentCount'] ?? 0,
        'venueCapacity': timetableData['venueCapacity'] ?? 0,
        'distanceFactor': decisionLogData['distanceFactor'] ?? 0,
        'reason': decisionLogData['conflictDetails'] ?? '',
        'confidenceScore': decisionLogData['confidenceScore'] ?? 0.0,
        'status': data['status'] ?? '',
        // Add other fields as needed
      });
    }

    return allocations;
  }

  Widget _buildTimelineSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchTimelineEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('TimelineSection Firestore error: ${snapshot.error}');
          return Center(
              child: Text('Error loading timeline events: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No timeline events found.'));
        }
        final events = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return TimelineItemWidget(
              timeSlotId: events[index]['id'],
              isLast: index == events.length - 1,
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchPerformanceMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('PerformanceTab Firestore error: ${snapshot.error}');
          return Center(
              child:
                  Text('Error loading performance metrics: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No performance metrics found.'));
        }

        final metrics = snapshot.data!;
        // Example: allocationSpeed in seconds (add this field in Firestore if not present)
        final allocationSpeed = metrics['allocationSpeed'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // New section for allocation speed
              Row(
                children: [
                  Icon(Icons.speed, color: ThemeAlias.AppTheme.primary600),
                  const SizedBox(width: 8),
                  Text(
                    'Allocation Speed',
                    style: ThemeAlias.AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    allocationSpeed > 0 ? '$allocationSpeed seconds' : 'N/A',
                    style: ThemeAlias.AppTheme.lightTheme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem(
                  'optimizationRate', 'Optimization Rate'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem(
                  'venueUtilization', 'Venue Utilization'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem(
                  'conflictResolutionRate', 'Conflict Resolution'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem(
                  'avgWalkingDistance', 'Avg. Walking Distance'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Performance Trends",
                      style:
                          ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.show_chart_outlined,
                        color: ThemeAlias.AppTheme.neutral500),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Chart showing performance trends over time.')),
                      );
                    },
                    tooltip: 'Chart Details',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: AllocationChartWidget(
                  tooltipBgColor: ThemeAlias.AppTheme.neutral800.withAlpha(204),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularMetric(
      {required double value, required String label, required Color color}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: value > 1 ? value / 100 : value,
                strokeWidth: 7,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              value > 1
                  ? '${value.toStringAsFixed(0)}%'
                  : '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: ThemeAlias.AppTheme.lightTheme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildPerformanceIndicatorItem(String documentId, String title) {
    return Row(
      children: [
        Expanded(
          child: PerformanceIndicatorWidget(documentId: documentId),
        ),
        IconButton(
          icon: const CustomIcons.CustomIconWidget(
              iconName: 'insights', color: ThemeAlias.AppTheme.neutral500),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Detailed view for $title (document ID: $documentId).')),
            );
          },
          tooltip: 'View details for $title',
        ),
      ],
    );
  }

  Widget _buildDecisionLogTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchDecisionLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('DecisionLogTab Firestore error: ${snapshot.error}');
          return Center(
              child: Text('Error loading decision logs: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No decision logs found.'));
        }
        final decisionLogs = snapshot.data!;
        final Map<String, int> statusCounts = {};
        for (final log in decisionLogs) {
          final status = log['status']?.toString() ?? 'unknown';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Allocation Log Summary',
                  style: ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Logs by Status',
                  style: ThemeAlias.AppTheme.lightTheme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: statusCounts.entries.map((entry) {
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: (entry.value * 18.0).clamp(12, 120),
                          width: 24,
                          decoration: BoxDecoration(
                            color: entry.key == 'resolved'
                                ? Colors.green
                                : entry.key == 'diverted'
                                    ? Colors.orange
                                    : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(entry.key,
                            style: ThemeAlias
                                .AppTheme.lightTheme.textTheme.bodySmall),
                        Text(entry.value.toString(),
                            style: ThemeAlias
                                .AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('All Allocation Logs',
                  style: ThemeAlias.AppTheme.lightTheme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: decisionLogs.length,
                itemBuilder: (context, index) {
                  final decision = decisionLogs[index];
                  // Defensive null checks for all expected String fields
                  final safeDecision = {
                    ...decision,
                    'description': decision['description'] ?? '',
                    'conflictDetails': decision['conflictDetails'] ?? '',
                    'suggestedVenue': decision['suggestedVenue'] ?? '',
                    'status': decision['status'] ?? '',
                    'resolvedBy': decision['resolvedBy'] ?? '',
                    // Add other fields as needed
                  };
                  return DecisionLogItemWidget(
                    decision: safeDecision,
                    onViewDetails: () {
                      _showDecisionDetailsDialog(context, safeDecision);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDecisionDetailsDialog(
      BuildContext context, Map<String, dynamic> decision) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decision Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(decision['description'] ?? 'No details available.'),
              const SizedBox(height: 8),
              if (decision['conflictDetails'] != null)
                Text('Conflict: ${decision['conflictDetails']}'),
              if (decision['suggestedVenue'] != null)
                Text('Suggested Venue: ${decision['suggestedVenue']}'),
              if (decision['timestamp'] != null)
                Text('Time: ${decision['timestamp'].toDate()}'),
              if (decision['status'] != null)
                Text('Status: ${decision['status']}'),
              if (decision['resolvedBy'] != null)
                Text('Resolved By: ${decision['resolvedBy']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: ThemeAlias.AppTheme.primary600),
              const SizedBox(width: 8),
              const Text('AI Allocation Dashboard Help'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpSection(
                  'Allocations Tab',
                  'View and manage current room allocations. The timeline shows scheduled classes throughout the day, with color coding to indicate status. Active allocations can be approved or edited as needed.',
                ),
                const Divider(),
                _buildHelpSection(
                  'Performance Tab',
                  'Monitor system performance metrics including optimization rate, average walking distance, venue utilization, and conflict resolution rate. Charts display trends over time.',
                ),
                const Divider(),
                _buildHelpSection(
                  'Decision Log Tab',
                  'Review AI allocation decisions with detailed information about the factors that influenced each change. Export logs for reporting purposes.',
                ),
                const Divider(),
                _buildHelpSection(
                  'Real-time Updates',
                  'Toggle the "Live" switch in the app bar to enable or disable real-time updates to the dashboard.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ThemeAlias.AppTheme.lightTheme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: ThemeAlias.AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
