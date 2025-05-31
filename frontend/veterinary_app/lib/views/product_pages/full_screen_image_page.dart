import 'dart:io'; // Required for Platform check and File operations
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For downloading the image
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // For saving to gallery
import 'package:path_provider/path_provider.dart'; // For temporary file path
import 'package:permission_handler/permission_handler.dart';

import '../../utils/app_colors.dart'; // For permission handling

// Assuming kAccentGreen is defined in app_colors.dart or main.dart
// If not, define it here or import it from its source.

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;
  final String? fileName; // Optional: Pass original file name for saving

  const FullScreenImagePage({
    super.key,
    required this.imageUrl,
    this.fileName, // Make fileName optional
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {

  // Helper to show themed SnackBar feedback
  void _showSnackBar(String message, {bool isSuccess = true}) {
    // Ensure context is still valid before showing SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: isSuccess ? kAccentGreen : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // Method to download and save an image
  Future<void> _downloadAndSaveImage() async {
    _showSnackBar('Downloading image...', isSuccess: true);
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 13+ (API 33+), requires READ_MEDIA_IMAGES
        status = await Permission.photos.request();
        if (!status.isGranted) {
          // Fallback for older Android (API 32 and below) that uses WRITE_EXTERNAL_STORAGE
          status = await Permission.storage.request();
        }
      } else if (Platform.isIOS) {
        // iOS requires NSPhotoLibraryAddUsageDescription (photosAddOnly)
        status = await Permission.photosAddOnly.request();
      } else {
        // For other platforms (Web, Desktop), no explicit permission handling needed
        status = PermissionStatus.granted;
      }

      if (status.isGranted) {
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode == 200) {
          final directory = await getTemporaryDirectory();
          // Use the provided fileName or default to a generic name
          final String fileNameToSave = widget.fileName ?? 'downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = '${directory.path}/$fileNameToSave';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Save to gallery using image_gallery_saver_plus
          final result = await ImageGallerySaverPlus.saveFile(file.path, name: fileNameToSave);
          if (result['isSuccess']) {
            _showSnackBar('Image saved to gallery!', isSuccess: true);
          } else {
            _showSnackBar('Failed to save image to gallery: ${result['errorMessage'] ?? 'Unknown error'}', isSuccess: false);
          }
        } else {
          _showSnackBar('Failed to download image: Server responded with ${response.statusCode}', isSuccess: false);
        }
      } else {
        _showSnackBar('Permission denied to save image.', isSuccess: false);
        // Optional: Open app settings if permission is permanently denied
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      _showSnackBar('Error downloading image: $e', isSuccess: false);
      print('Error downloading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54, // semi-transparent dark background
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          // NEW: Download button in the AppBar actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54, // semi-transparent dark background
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Download Image',
                onPressed: _downloadAndSaveImage, // Call the download method
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          // Ensure imageUrl is prefixed with BaseUrl.api if it's a relative path
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.white, size: 100),
          ),
        ),
      ),
    );
  }
}
