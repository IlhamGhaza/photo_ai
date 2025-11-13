import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';

/// Repository for Firebase Cloud Functions
/// Handles calls to backend functions for AI image generation
class FunctionsRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call generateImages Cloud Function
  /// Input: { imageUrl: string }
  /// Output: { generatedUrls: string[], stylesUsed: string[] }
  Future<Map<String, dynamic>> generateImages({
    required String imageUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateImages');

      final result = await callable.call({'imageUrl': imageUrl});

      // Return complete response from Cloud Function
      final data = result.data as Map<String, dynamic>;

      return {
        'generatedUrls': List<String>.from(data['generatedUrls'] as List),
        'stylesUsed': List<String>.from(
          (data['styles'] as List?) ?? (data['stylesUsed'] as List?) ?? [],
        ),
      };
    } catch (e) {
      log('Cloud Function error: $e');
      rethrow;
    }
  }

  /// Call generateImages Cloud Function with timeout
  /// Useful for long-running AI operations
  Future<Map<String, dynamic>> generateImagesWithTimeout({
    required String imageUrl,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateImages',
        options: HttpsCallableOptions(timeout: timeout),
      );

      final result = await callable.call({'imageUrl': imageUrl});

      // Return complete response from Cloud Function
      final data = result.data as Map<String, dynamic>;

      return {
        'generatedUrls': List<String>.from(data['generatedUrls'] as List),
        'stylesUsed': List<String>.from(
          (data['styles'] as List?) ?? (data['stylesUsed'] as List?) ?? [],
        ),
      };
    } catch (e) {
      log('Cloud Function error: $e');
      rethrow;
    }
  }
}
