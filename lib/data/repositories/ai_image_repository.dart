import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';

/// Repository for AI image generation
/// Uses Gemini to generate prompts, then calls image generation API
class AIImageRepository {
  late final GenerativeModel _model;
  
  AIImageRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AppConstants.geminiApiKey,
    );
  }

  /// Generate image variations using AI
  /// Step 1: Use Gemini to create enhanced prompts from styles
  /// Step 2: Use Pollinations.ai free API to generate actual images
  Future<List<String>> generateImageVariations({
    required File originalImage,
    required List<String> styles,
  }) async {
    try {
      final imageBytes = await originalImage.readAsBytes();
      final generatedUrls = <String>[];

      // Generate images for each style
      for (int i = 0; i < styles.length && i < 6; i++) {
        final style = styles[i];
        
        try {
          // Step 1: Use Gemini to enhance the style into a detailed prompt
          final enhancedPrompt = await _enhanceStylePrompt(style, imageBytes);
          
          // Step 2: Generate image using Pollinations.ai (free API)
          final imageUrl = await _generateImageWithPollinations(enhancedPrompt);
          
          if (imageUrl != null) {
            generatedUrls.add(imageUrl);
            print('Generated image $i: $imageUrl');
          }
          
          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (e) {
          print('Error generating image for style $i: $e');
        }
      }

      return generatedUrls;
    } catch (e) {
      print('AI Image generation error: $e');
      return [];
    }
  }

  /// Enhance style description into detailed prompt using Gemini
  Future<String> _enhanceStylePrompt(String style, Uint8List imageBytes) async {
    try {
      final prompt = '''
Based on the style "$style", create a detailed, vivid image generation prompt.

The prompt should describe:
- Scene composition and subject
- Lighting and atmosphere
- Color palette and mood
- Photography style and quality
- Specific details that capture the essence of "$style"

Make it concise but descriptive (max 100 words).
Return ONLY the prompt, no explanations.''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final enhancedPrompt = response.text?.trim() ?? style;
      
      return enhancedPrompt;
    } catch (e) {
      print('Error enhancing prompt: $e');
      return style;
    }
  }

  /// Generate image using Pollinations.ai free API
  /// API: https://image.pollinations.ai/prompt/{prompt}
  Future<String?> _generateImageWithPollinations(String prompt) async {
    try {
      // Encode prompt for URL
      final encodedPrompt = Uri.encodeComponent(prompt);
      
      // Pollinations.ai free API endpoint
      // Parameters: width, height, seed, model
      final url = 'https://image.pollinations.ai/prompt/$encodedPrompt'
          '?width=800&height=800&nologo=true&model=flux';
      
      // The API returns the image directly, we just return the URL
      // The image will be loaded by CachedNetworkImage in the UI
      return url;
    } catch (e) {
      print('Error generating with Pollinations: $e');
      return null;
    }
  }

  /// Generate a single image with custom prompt
  Future<String?> generateSingleImage({
    required String prompt,
  }) async {
    try {
      return await _generateImageWithPollinations(prompt);
    } catch (e) {
      print('Single image generation error: $e');
      return null;
    }
  }
}
