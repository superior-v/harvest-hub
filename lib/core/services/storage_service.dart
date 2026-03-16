import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload single image
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    required String userId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('$folder/$userId/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

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

  // Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    required String userId,
    Function(int, int)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadImage(
          imageFile: imageFiles[i],
          folder: folder,
          userId: userId,
        );

        if (url != null) {
          downloadUrls.add(url);
        }

        // Notify progress
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        debugPrint('Error uploading image ${i + 1}: $e');
      }
    }

    return downloadUrls;
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