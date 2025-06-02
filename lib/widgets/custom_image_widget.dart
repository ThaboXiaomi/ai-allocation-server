import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallbackImageUrl;

  const CustomImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.fallbackImageUrl =
        'https://images.unsplash.com/photo-1584824486509-112e4181ff6b?q=80&w=2940&auto=format&fit=crop',
  }) : super(key: key);

  Future<String> _getFirebaseImageUrl(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error fetching image from Firebase Storage: $e');
      return fallbackImageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log image usage to Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'image_displayed',
      parameters: {
        'image_url': imageUrl ?? 'fallback_image',
        'width': width,
        'height': height,
      },
    );

    return FutureBuilder<String>(
      future: imageUrl != null ? _getFirebaseImageUrl(imageUrl!) : Future.value(fallbackImageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Image.network(
            fallbackImageUrl,
            fit: fit,
            width: width,
            height: height,
          );
        } else {
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            errorWidget: (context, url, error) => Image.network(
              fallbackImageUrl,
              fit: fit,
              width: width,
              height: height,
            ),
            placeholder: (context, url) => Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }
}
