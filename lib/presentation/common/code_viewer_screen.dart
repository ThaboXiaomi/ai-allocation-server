import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class CodeViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const CodeViewerScreen({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  Future<String> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return "Error loading file: $e\n\nPlease ensure the file path is correct and the file is included in your app's assets (pubspec.yaml).";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: FutureBuilder<String>(
        future: _loadAsset(filePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
                child: Text(snapshot.data ??
                    'Error: ${snapshot.error ?? "Could not load file."}'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              snapshot.data!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
