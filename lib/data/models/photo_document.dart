import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document model for user photos
/// Path: users/{uid}/images/{imageId}
class PhotoDocument {
  final String id;
  final String userId;
  final String originalUrl;
  final List<String> generatedUrls;
  final DateTime createdAt;

  PhotoDocument({
    required this.id,
    required this.userId,
    required this.originalUrl,
    required this.generatedUrls,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalUrl': originalUrl,
      'generatedUrls': generatedUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory PhotoDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return PhotoDocument(
      id: snapshot.id,
      userId: data['userId'] as String,
      originalUrl: data['originalUrl'] as String,
      generatedUrls: List<String>.from(data['generatedUrls'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create from map with ID
  factory PhotoDocument.fromMap(String id, Map<String, dynamic> data) {
    return PhotoDocument(
      id: id,
      userId: data['userId'] as String,
      originalUrl: data['originalUrl'] as String,
      generatedUrls: List<String>.from(data['generatedUrls'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Copy with new values
  PhotoDocument copyWith({
    String? id,
    String? userId,
    String? originalUrl,
    List<String>? generatedUrls,
    DateTime? createdAt,
  }) {
    return PhotoDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalUrl: originalUrl ?? this.originalUrl,
      generatedUrls: generatedUrls ?? this.generatedUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
