import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'decision_log_item_widget.dart';

class DecisionLogListWidget extends StatelessWidget {
  final void Function(Map<String, dynamic> decision)? onViewDetails;

  const DecisionLogListWidget({Key? key, this.onViewDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('decisionLogs')
          .where('status', isEqualTo: 'resolved')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No solved conflicts found.'));
        }
        final decisions = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        return ListView.builder(
          itemCount: decisions.length,
          itemBuilder: (context, index) {
            return DecisionLogItemWidget(
              decision: decisions[index],
              onViewDetails: () {
                if (onViewDetails != null) {
                  onViewDetails!(decisions[index]);
                }
              },
            );
          },
        );
      },
    );
  }
}
