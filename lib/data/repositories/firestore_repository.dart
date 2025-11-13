import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo_document.dart';

/// Repository for Firestore operations
/// Manages photo documents in users/{uid}/images/{imageId}
class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new photo document
  /// Returns the document ID
  Future<String> createPhotoDocument({
    required String userId,
    required String imageId,
    required String originalUrl,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId);

      final photoDoc = PhotoDocument(
        id: imageId,
        userId: userId,
        originalUrl: originalUrl,
        generatedUrls: [],
      );

      await docRef.set(photoDoc.toFirestore());
      return imageId;
    } catch (e) {
      log('Error creating photo document: $e');
      rethrow;
    }
  }

  /// Update photo document with generated URLs
  Future<void> updateGeneratedUrls({
    required String userId,
    required String imageId,
    required List<String> generatedUrls,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId)
          .update({'generatedUrls': generatedUrls});
    } catch (e) {
      log('Error updating generated URLs: $e');
      rethrow;
    }
  }

  /// Get a single photo document
  Future<PhotoDocument?> getPhotoDocument({
    required String userId,
    required String imageId,
  }) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId)
          .get();

      if (!docSnapshot.exists) return null;

      return PhotoDocument.fromFirestore(docSnapshot);
    } catch (e) {
      log('Error getting photo document: $e');
      return null;
    }
  }

  /// Get all photo documents for a user
  /// Returns list ordered by creation date (newest first)
  Future<List<PhotoDocument>> getUserPhotos({required String userId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PhotoDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting user photos: $e');
      return [];
    }
  }

  /// Stream of user photos (real-time updates)
  Stream<List<PhotoDocument>> watchUserPhotos({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PhotoDocument.fromFirestore(doc))
              .toList(),
        );
  }

  /// Delete a photo document
  Future<void> deletePhotoDocument({
    required String userId,
    required String imageId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('images')
          .doc(imageId)
          .delete();
    } catch (e) {
      log('Error deleting photo document: $e');
      rethrow;
    }
  }

  /// Save/bookmark a generated image
  Future<void> saveImage({
    required String userId,
    required String imageId,
    required String imageUrl,
    required String style,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved')
          .doc(imageId)
          .set({
            'url': imageUrl,
            'style': style,
            'savedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('Error saving image: $e');
      rethrow;
    }
  }

  /// Unsave/unbookmark an image
  Future<void> unsaveImage({
    required String userId,
    required String imageId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved')
          .doc(imageId)
          .delete();
    } catch (e) {
      log('Error unsaving image: $e');
      rethrow;
    }
  }

  /// Get all saved/bookmarked images
  Future<List<Map<String, dynamic>>> getSavedImages({
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved')
          .orderBy('savedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'url': data['url'] as String,
          'style': data['style'] as String,
          'savedAt':
              (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      log('Error getting saved images: $e');
      return [];
    }
  }

  /// Check if an image is saved
  Future<bool> isImageSaved({
    required String userId,
    required String imageId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved')
          .doc(imageId)
          .get();
      return doc.exists;
    } catch (e) {
      log('Error checking if image is saved: $e');
      return false;
    }
  }
}
