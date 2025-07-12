import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AllocationsScreen extends StatefulWidget {
  const AllocationsScreen({super.key});

  @override
  State<AllocationsScreen> createState() => _AllocationsScreenState();
}

class _AllocationsScreenState extends State<AllocationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _allocations;

  @override
  void initState() {
    super.initState();
    _allocations = _apiService.getAllocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allocations')),
      body: FutureBuilder<List<dynamic>>(
        future: _allocations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No allocations found.'));
          } else {
            final allocations = snapshot.data!;
            return ListView.builder(
              itemCount: allocations.length,
              itemBuilder: (context, index) {
                final allocation = allocations[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(allocation['courseCode'] ?? 'No Course Code'),
                  subtitle: Text('Venue: ${allocation['resolvedVenue'] ?? 'TBD'}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}