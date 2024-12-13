// album_image_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;

class CustomAlbumImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const CustomAlbumImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  /// Utility function to check if the image format is supported.
  bool isSupportedImageFormat(String url) {
    try {
      Uri uri = Uri.parse(url);
      String extension = path.extension(uri.path).toLowerCase(); // e.g., '.png'
      print('Parsed extension: $extension for URL: $url'); // Debug log
      return (extension == '.jpg' || extension == '.jpeg' || extension == '.png');
    } catch (e) {
      print('Error parsing image URL: $url, error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validate the image format
    bool isSupported = isSupportedImageFormat(imageUrl);

    if (!isSupported) {
      print('Unsupported image format for URL: $imageUrl');
      // Return a fallback image
      return Image.asset(
        'assets/blank_cd.png', // Ensure this image exists in your assets
        fit: fit,
      );
    }

    return imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) {
              print('Error loading image from $url: $error');
              return Image.asset(
                'assets/blank_cd.png', // Fallback image
                fit: fit,
              );
            },
          )
        : Icon(
            Icons.album,
            size: 120,
          );
  }
}
