import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Repository for Firebase Storage operations
/// Manages image uploads and downloads
/// Storage paths:
/// - /users/{uid}/original/{imageId}
/// - /users/{uid}/generated/{imageId}/{n}
class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload original image to Firebase Storage with retry logic
  /// Returns the download URL
  Future<String> uploadOriginalImage({
    required String userId,
    required String imageId,
    required File imageFile,
  }) async {
    return _uploadWithRetry(
      () async {
        final ref = _storage.ref().child('users/$userId/original/$imageId');
        
        // Upload file with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded': DateTime.now().toIso8601String()},
        );
        
        final uploadTask = await ref.putFile(imageFile, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      },
      'uploadOriginalImage',
    );
  }
  
  /// Helper method to upload with retry logic
  Future<T> _uploadWithRetry<T>(
    Future<T> Function() uploadFunction,
    String operationName, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    Duration delay = const Duration(seconds: 1);
    
    while (attempts < maxRetries) {
      try {
        return await uploadFunction();
      } catch (e) {
        attempts++;
        print('$operationName attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('$operationName failed after $maxRetries attempts');
          rethrow;
        }
        
        // Exponential backoff
        print('Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay *= 2; // Double the delay for next retry
      }
    }
    
    throw Exception('$operationName failed after $maxRetries attempts');
  }

  /// Upload generated image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadGeneratedImage({
    required String userId,
    required String imageId,
    required int index,
    required File imageFile,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('users/$userId/generated/$imageId/$index');
      
      // Upload file
      final uploadTask = await ref.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading generated image: $e');
      rethrow;
    }
  }

  /// Delete original image from Storage
  Future<void> deleteOriginalImage({
    required String userId,
    required String imageId,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/original/$imageId');
      await ref.delete();
    } catch (e) {
      print('Error deleting original image: $e');
      // Don't rethrow - file might not exist
    }
  }

  /// Delete all generated images for a photo
  Future<void> deleteGeneratedImages({
    required String userId,
    required String imageId,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/generated/$imageId');
      final listResult = await ref.listAll();
      
      // Delete all files in the directory
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      print('Error deleting generated images: $e');
      // Don't rethrow - files might not exist
    }
  }

  /// Delete all images (original + generated) for a photo
  Future<void> deleteAllImages({
    required String userId,
    required String imageId,
  }) async {
    await Future.wait([
      deleteOriginalImage(userId: userId, imageId: imageId),
      deleteGeneratedImages(userId: userId, imageId: imageId),
    ]);
  }
}
