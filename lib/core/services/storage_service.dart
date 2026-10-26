import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compresses a high-res camera photo (from ~10MB down to ~150KB) for instant upload
  Future<File> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;

      // Resize down if wider than 1024px
      img.Image target = decoded;
      if (decoded.width > 1024 || decoded.height > 1024) {
        target = img.copyResize(decoded, width: 1024);
      }

      final compressedBytes = img.encodeJpg(target, quality: 75);
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final compressedFile = File(targetPath)..writeAsBytesSync(compressedBytes);
      return compressedFile;
    } catch (e) {
      debugPrint('Compression error, using original file: $e');
      return file;
    }
  }

  // Upload single image with timeout & compression
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String userId,
  }) async {
    try {
      final fileToUpload = await _compressImage(imageFile);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(fileToUpload.path)}';
      final ref = _storage.ref().child('$folder/$userId/$fileName');

      final uploadTask = ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 12-second timeout to prevent hanging on slow networks
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Upload timed out after 12s'),
      );

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }

      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images in parallel with timeout
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    required String userId,
    Function(int, int)? onProgress,
  }) async {
    if (imageFiles.isEmpty) return [];

    try {
      // Upload all images in parallel for 5x speedup
      final uploadFutures = imageFiles.map((file) => uploadImage(
            imageFile: file,
            folder: folder,
            userId: userId,
          ));

      final results = await Future.wait(uploadFutures);
      final validUrls = results.whereType<String>().toList();

      debugPrint('Successfully uploaded ${validUrls.length}/${imageFiles.length} photos.');
      return validUrls;
    } catch (e) {
      debugPrint('Error in uploadMultipleImages: $e');
      return [];
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}