import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class CustomIconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const CustomIconWidget({
    Key? key,
    required this.iconName,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Map of available icons
    final Map<String, IconData> iconMap = {
      'abc': Icons.abc,
      'ac_unit': Icons.ac_unit,
      'access_alarm': Icons.access_alarm,
      'access_alarms': Icons.access_alarms,
      'access_time': Icons.access_time,
      'accessibility': Icons.accessibility,
      'account_circle': Icons.account_circle,
      'add': Icons.add,
      'alarm': Icons.alarm,
      'android': Icons.android,
      'arrow_back': Icons.arrow_back,
      'arrow_forward': Icons.arrow_forward,
      'home': Icons.home,
      'settings': Icons.settings,
      'help_outline': Icons.help_outline,
    };

    // Log the icon usage to Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'icon_used',
      parameters: {
        'icon_name': iconName,
        'icon_size': size,
        'icon_color': color?.value.toString() ?? 'default',
      },
    );

    // Check if the icon exists
    if (iconMap.containsKey(iconName)) {
      return Icon(
        iconMap[iconName],
        size: size,
        color: color,
        semanticLabel: iconName,
      );
    } else {
      // Return a fallback icon and log the missing icon
      FirebaseAnalytics.instance.logEvent(
        name: 'missing_icon',
        parameters: {
          'icon_name': iconName,
        },
      );

      return Icon(
        Icons.help_outline,
        size: size,
        color: Colors.grey,
        semanticLabel: '$iconName (missing)',
      );
    }
  }
}

// Firebase Remote Config Example
Future<void> fetchRemoteIconMap() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  try {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await remoteConfig.fetchAndActivate();

    // Example: Fetch a remote icon map (as a JSON string)
    final remoteIconMap = remoteConfig.getString('icon_map');
    print('Fetched remote icon map: $remoteIconMap');
  } catch (e) {
    print('Failed to fetch remote config: $e');
  }
}
