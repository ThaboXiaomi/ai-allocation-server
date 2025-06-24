import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart' as ThemeAlias;
import '../../widgets/custom_icon_widget.dart' as CustomIcons;
import './widgets/allocation_card_widget.dart';
import './widgets/allocation_chart_widget.dart';
import './widgets/allocation_filter_widget.dart';
import './widgets/decision_log_item_widget.dart';
import './widgets/performance_indicator_widget.dart';
import './widgets/timeline_item_widget.dart';

class AIAllocationDashboard extends StatefulWidget {
  const AIAllocationDashboard({Key? key}) : super(key: key);

  @override
  State<AIAllocationDashboard> createState() => _AIAllocationDashboardState();
}

class _AIAllocationDashboardState extends State<AIAllocationDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFaculty = 'All';
  String _selectedBuilding = 'All';
  String _selectedTimeframe = 'Today';
  bool _isRealTimeUpdates = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch active allocations from Firestore
  Stream<List<Map<String, dynamic>>> _fetchActiveAllocations() {
    return FirebaseFirestore.instance
        .collection('allocations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  /// Fetch decision logs from Firestore
  Stream<List<Map<String, dynamic>>> _fetchDecisionLogs() {
    return FirebaseFirestore.instance
        .collection('decisionLogs')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  /// Fetch performance metrics from Firestore
  Future<Map<String, dynamic>> _fetchPerformanceMetrics() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('performanceMetrics')
        .doc('metrics')
        .get();

    if (docSnapshot.exists) {
      return docSnapshot.data()!;
    } else {
      throw Exception('Performance metrics not found');
    }
  }

  /// Fetch timeline events from Firestore
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
    return Scaffold(
      appBar: AppBar(
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
            _buildFilterSection(),
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
        tabs: const [
          Tab(
            icon: CustomIcons.CustomIconWidget(
              iconName: 'swap_horiz',
              color: ThemeAlias.AppTheme.primary600,
            ),
            text: 'Allocations',
          ),
          Tab(
            icon: CustomIcons.CustomIconWidget(
              iconName: 'insights',
              color: ThemeAlias.AppTheme.primary600,
            ),
            text: 'Performance',
          ),
          Tab(
            icon: CustomIcons.CustomIconWidget(
              iconName: 'history',
              color: ThemeAlias.AppTheme.primary600,
            ),
            text: 'Logs',
          ),
        ],
        labelColor: AppTheme.primary600,
        unselectedLabelColor: ThemeAlias.AppTheme.neutral500 ?? Colors.grey,
        indicatorColor: AppTheme.primary600,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeAlias.AppTheme.neutral50 ?? Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: ThemeAlias.AppTheme.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: ThemeAlias.AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600
                ),
              ),
              IconButton(
                icon: const CustomIcons.CustomIconWidget(iconName: 'help_outline', color: ThemeAlias.AppTheme.neutral500),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter data across all tabs by faculty, building, or timeframe.')),
                  );
                },
                tooltip: 'About Filters',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AllocationFilterWidget(
            selectedFaculty: _selectedFaculty,
            selectedBuilding: _selectedBuilding,
            selectedTimeframe: _selectedTimeframe,
            onFacultyChanged: (value) {
              setState(() {
                _selectedFaculty = value;
              });
            },
            onBuildingChanged: (value) {
              setState(() {
                _selectedBuilding = value;
              });
            },
            onTimeframeChanged: (value) {
              setState(() {
                _selectedTimeframe = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchActiveAllocations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Print error to console for debugging
          print('AllocationTab Firestore error: ${snapshot.error}');
          return Center(child: Text('Error loading allocations: ${snapshot.error}'));
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
              Text(
                "Active & Recent Allocations",
                style: ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allocations.length,
                itemBuilder: (context, index) {
                  return AllocationCardWidget(
                    allocation: allocations[index],
                    documentId: allocations[index]['id'],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Daily Timeline",
                    style: ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const CustomIcons.CustomIconWidget(iconName: 'access_time', color: ThemeAlias.AppTheme.neutral500),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Timeline shows scheduled events for the selected day.')),
                      );
                    },
                    tooltip: 'Timeline Information',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTimelineSection(), // New section for TimelineItemWidget
            ],
          ),
        );
      },
    );
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
          return Center(child: Text('Error loading timeline events: ${snapshot.error}'));
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
            // Assuming 'id' is the timeSlotId for TimelineItemWidget
            return TimelineItemWidget(timeSlotId: events[index]['id'], isLast: index == events.length -1,);
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
          return Center(child: Text('Error loading performance metrics: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No performance metrics found.'));
        }

        final metrics = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPerformanceIndicatorItem('optimizationRate', 'Optimization Rate'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem('venueUtilization', 'Venue Utilization'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem('conflictResolutionRate', 'Conflict Resolution'),
              const SizedBox(height: 16),
              _buildPerformanceIndicatorItem('avgWalkingDistance', 'Avg. Walking Distance'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Performance Trends",
                     style: ThemeAlias.AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.show_chart_outlined, color: ThemeAlias.AppTheme.neutral500),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chart showing performance trends over time.')),
                      );
                    },
                    tooltip: 'Chart Details',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250, // Give the chart a fixed height
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

  Widget _buildPerformanceIndicatorItem(String documentId, String title) {
    return Row(
      children: [
        Expanded(
          child: PerformanceIndicatorWidget(
            documentId: documentId,
          ),
        ),
        IconButton(
          icon: const CustomIcons.CustomIconWidget(iconName: 'insights', color: ThemeAlias.AppTheme.neutral500),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Detailed view for $title (document ID: $documentId).')),
            );
          },
          tooltip: 'View details for $title',
        ),
      ],
    );
  }

  Widget _buildTimelineTab() { // This function seems to be unused, replaced by _buildTimelineSection
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchTimelineEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No timeline events found.'));
        }
        final events = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return TimelineItemWidget(
              timeSlotId: events[index]['id'], // Ensure 'id' is the correct field for timeSlotId
              isLast: index == events.length - 1,
            );
          },
        );
      },
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
          return Center(child: Text('Error loading decision logs: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No decision logs found.'));
        }

        final decisionLogs = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: decisionLogs.length,
          itemBuilder: (context, index) {
            return DecisionLogItemWidget(
              decision: decisionLogs[index],
              onViewDetails: () {
                _showDecisionDetailsDialog(context, decisionLogs[index]);
              },
            );
          },
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
          content: Text(decision['description'] ?? 'No details available.'),
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
          title: const Text('AI Allocation Dashboard Help'),
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
                  'Filters',
                  'Use the filters at the top of the screen to focus on specific faculties, buildings, or time periods. This affects the data displayed in all tabs.',
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
            style: ThemeAlias.AppTheme.lightTheme.textTheme?.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: ThemeAlias.AppTheme.lightTheme.textTheme?.bodyMedium,
          ),
        ],
      ),
    );
  }
}
