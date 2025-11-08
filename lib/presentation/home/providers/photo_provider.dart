import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/generated_image.dart';
import '../../../data/repositories/gemini_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/ai_image_repository.dart';

enum AppState { empty, uploaded, generating, error, results }

class PhotoProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GeminiRepository _geminiRepository = GeminiRepository();
  final FirestoreRepository _firestoreRepository = FirestoreRepository();
  final StorageRepository _storageRepository = StorageRepository();
  final AIImageRepository _aiImageRepository = AIImageRepository();
  final Uuid _uuid = const Uuid();

  AppState _appState = AppState.empty;
  File? _uploadedImageFile;
  String? _uploadedImagePath;
  String? _currentImageId;
  String? _originalImageUrl;
  List<GeneratedImage> _generatedImages = [];
  List<GeneratedImage> _savedImages = [];
  String _errorMessage = '';
  double _generationProgress = 0.0;

  // Getters
  AppState get appState => _appState;
  File? get uploadedImageFile => _uploadedImageFile;
  String? get uploadedImagePath => _uploadedImagePath;
  List<GeneratedImage> get generatedImages => _generatedImages;
  List<GeneratedImage> get savedImages => _savedImages;
  String get errorMessage => _errorMessage;
  double get generationProgress => _generationProgress;
  bool get hasUploadedImage => _uploadedImageFile != null;

  // Upload image to Firebase Storage and create Firestore document
  Future<void> uploadImage(File imageFile) async {
    try {
      _uploadedImageFile = imageFile;
      _uploadedImagePath = imageFile.path;
      _appState = AppState.uploaded;
      _errorMessage = '';
      notifyListeners();

      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique image ID
      _currentImageId = _uuid.v4();

      // Upload original image to Firebase Storage
      _originalImageUrl = await _storageRepository.uploadOriginalImage(
        userId: userId,
        imageId: _currentImageId!,
        imageFile: imageFile,
      );

      // Create Firestore document
      await _firestoreRepository.createPhotoDocument(
        userId: userId,
        imageId: _currentImageId!,
        originalUrl: _originalImageUrl!,
      );
    } catch (e) {
      _errorMessage = 'Failed to upload image: ${e.toString()}';
      _appState = AppState.error;
      notifyListeners();
    }
  }

  // Generate images using Cloud Functions and Firebase
  Future<void> generateImages() async {
    if (_uploadedImageFile == null || _originalImageUrl == null || _currentImageId == null) {
      _errorMessage = 'Please upload an image first';
      _appState = AppState.error;
      notifyListeners();
      return;
    }

    _appState = AppState.generating;
    _errorMessage = '';
    _generationProgress = 0.0;
    notifyListeners();

    try {
      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Generate style variations using Gemini (20% progress)
      _generationProgress = 0.2;
      notifyListeners();
      
      final styles = await _geminiRepository.generateImageVariations(_uploadedImageFile!);
      
      _generationProgress = 0.4;
      notifyListeners();

      // Step 2: Generate actual AI images using Pollinations.ai
      // Gemini creates enhanced prompts, Pollinations generates the images
      _generationProgress = 0.5;
      notifyListeners();

      final generatedUrls = await _aiImageRepository.generateImageVariations(
        originalImage: _uploadedImageFile!,
        styles: styles,
      );

      // If no images were generated, use fallback
      if (generatedUrls.isEmpty) {
        print('AI generation returned empty, using fallback');
        throw Exception('No images generated');
      }

      _generationProgress = 0.8;
      notifyListeners();

      // Step 3: Update Firestore with generated URLs
      await _firestoreRepository.updateGeneratedUrls(
        userId: userId,
        imageId: _currentImageId!,
        generatedUrls: generatedUrls,
      );

      // Step 4: Create GeneratedImage objects for UI
      _generatedImages = List.generate(
        generatedUrls.length,
        (index) => GeneratedImage(
          id: _uuid.v4(),
          url: generatedUrls[index],
          style: index < styles.length ? styles[index] : 'Generated Style ${index + 1}',
        ),
      );

      _generationProgress = 1.0;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      _appState = AppState.results;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to generate images: ${e.toString()}';
      _appState = AppState.error;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }

  // Load saved images from Firestore
  Future<void> loadSavedImages() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      final photoDocuments = await _firestoreRepository.getUserPhotos(userId: userId);
      
      // Convert Firestore documents to GeneratedImage objects
      _savedImages = [];
      for (final doc in photoDocuments) {
        for (int i = 0; i < doc.generatedUrls.length; i++) {
          _savedImages.add(GeneratedImage(
            id: '${doc.id}_$i',
            url: doc.generatedUrls[i],
            style: 'Saved Image ${i + 1}',
            createdAt: doc.createdAt,
          ));
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading saved images: $e');
    }
  }

  // Save image (add to saved list)
  void saveImage(GeneratedImage image) {
    if (!_savedImages.any((img) => img.id == image.id)) {
      _savedImages.add(image);
      notifyListeners();
    }
  }

  // Unsave image
  void unsaveImage(String imageId) {
    _savedImages.removeWhere((img) => img.id == imageId);
    notifyListeners();
  }

  // Check if image is saved
  bool isImageSaved(String imageId) {
    return _savedImages.any((img) => img.id == imageId);
  }

  // Reset all
  void reset() {
    _uploadedImageFile = null;
    _uploadedImagePath = null;
    _currentImageId = null;
    _originalImageUrl = null;
    _generatedImages = [];
    _appState = AppState.empty;
    _errorMessage = '';
    _generationProgress = 0.0;
    notifyListeners();
  }

  // Clear generated images only
  void clearGenerated() {
    _generatedImages = [];
    if (_uploadedImageFile != null) {
      _appState = AppState.uploaded;
    } else {
      _appState = AppState.empty;
    }
    notifyListeners();
  }
}
