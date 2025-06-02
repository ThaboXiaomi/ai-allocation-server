import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class LogoHeaderWidget extends StatefulWidget {
  final String? welcomeText;
  final String? subText;

  const LogoHeaderWidget({
    Key? key,
    this.welcomeText = 'Welcome back',
    this.subText = 'Please sign in to continue',
  }) : super(key: key);

  @override
  State<LogoHeaderWidget> createState() => _LogoHeaderWidgetState();
}

class _LogoHeaderWidgetState extends State<LogoHeaderWidget> {
  String _appName = 'Lecture Room Allocator';
  String _appVersion = 'v1.0.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppDetails();
  }

  Future<void> _fetchAppDetails() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();

      setState(() {
        _appName = remoteConfig.getString('app_name') ?? _appName;
        _appVersion = remoteConfig.getString('app_version') ?? _appVersion;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors (e.g., network issues)
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to fetch app details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App logo
        Container(
          width: 30.w,
          height: 30.w,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.primary50
                : AppTheme.neutral900,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primary200
                  : AppTheme.neutral700,
              width: 2,
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.primary100
                  : AppTheme.neutral800,
              shape: BoxShape.circle,
            ),
            child: const CustomIconWidget(
              iconName: 'school',
              color: AppTheme.primary700,
              size: 48,
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // App name and version
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Column(
            children: [
              Text(
                _appName,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.primary900
                      : AppTheme.neutral100,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _appVersion,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.neutral600
                      : AppTheme.neutral400,
                ),
              ),
            ],
          ),
        SizedBox(height: 3.h),

        // Admin portal indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: AppTheme.primary900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Admin Portal',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Welcome text
        Text(
          widget.welcomeText ?? 'Welcome back',
          textAlign: TextAlign.center,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          widget.subText ?? 'Please sign in to continue',
          textAlign: TextAlign.center,
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
