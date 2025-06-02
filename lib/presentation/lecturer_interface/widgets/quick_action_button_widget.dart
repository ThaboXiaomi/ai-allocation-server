import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickActionButtonWidget extends StatefulWidget {
  final Map<String, dynamic> action;
  final VoidCallback onTap;

  const QuickActionButtonWidget({
    Key? key,
    required this.action,
    required this.onTap,
  }) : super(key: key);

  @override
  State<QuickActionButtonWidget> createState() => _QuickActionButtonWidgetState();
}

class _QuickActionButtonWidgetState extends State<QuickActionButtonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logActionToFirestore(String actionId) async {
    try {
      await FirebaseFirestore.instance.collection('action_logs').add({
        'actionId': actionId,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': 'currentUserId', // Replace with the actual user ID
      });
    } catch (e) {
      debugPrint('Error logging action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.action["color"];
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: () async {
        await _logActionToFirestore(widget.action["id"]);
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: color.withOpacity(0.25),
                    width: 1.2,
                  ),
                ),
                child: CustomIconWidget(
                  iconName: widget.action["icon"],
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.action["title"],
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Colors.black87,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
