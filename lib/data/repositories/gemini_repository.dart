import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';

class GeminiRepository {
  late final GenerativeModel _model;

  GeminiRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: AppConstants.geminiApiKey,
    );
  }

  /// Generate image variations using Gemini AI
  /// Returns a list of generated image descriptions/prompts
  Future<List<String>> generateImageVariations(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create prompt for generating travel/lifestyle variations
      final prompt = '''
You are an art director helping to restyle the SAME scene that appears in the uploaded photo.
Generate 6 tasteful travel/lifestyle style treatments that KEEP the core subject, composition, and geography recognizable.

For each variation:
- Start with a short evocative style title (2-3 words)
- Follow with one sentence describing how lighting, mood, season, weather, or color grading change while preserving the landscape, landmarks, and camera perspective shown in the photo.
- Do NOT invent new structures, replace the terrain, or move the camera to a different vantage point. Only restyle what already exists.
- Reference at least one visual element that is clearly present in the original image (e.g. mountains, coastline, river, skyline, vegetation).

Format every line exactly as: "Style Name - description"

Examples:
- Golden Peaks - warm sunset light washing over the existing mountain ridges and coastal bays, intensifying the golden grasses
- Misty Morning - soft dawn fog hugging the same rolling hills and water in the valley, with pastel tones and gentle glow
- Midnight Aurora - nighttime treatment over the identical coastline with northern lights rippling above the silhouetted peaks

Return 6 variations now:
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';

      // Parse the response into individual styles
      final lines = text
          .split('\n')
          .where(
            (line) =>
                line.trim().isNotEmpty &&
                line.contains('-') &&
                !line.startsWith('#') &&
                !line.toLowerCase().contains('variation'),
          )
          .toList();

      // Clean up and return
      final styles = lines
          .take(6)
          .map((line) {
            // Remove bullet points, numbers, etc.
            return line.replaceAll(RegExp(r'^[\d\*\-\.]+\s*'), '').trim();
          })
          .where((s) => s.isNotEmpty)
          .toList();

      if (styles.isEmpty) {
        // Fallback to default styles if parsing fails
        return AppConstants.travelStyles;
      }

      return styles.take(6).toList();
    } catch (e) {
      print('Gemini API Error: $e');
      // Return default styles as fallback
      return AppConstants.travelStyles;
    }
  }

  /// Generate a single text-to-image prompt based on style
  Future<String> enhancePrompt(String style, File originalImage) async {
    try {
      final imageBytes = await originalImage.readAsBytes();

      final prompt =
          '''
Based on the uploaded photo and the style "$style", create a detailed, vivid prompt for an AI image generator that would transform this photo into that style.

Make it descriptive, atmospheric, and specific. Focus on lighting, mood, composition, and details.

Return only the enhanced prompt, nothing else.
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await _model.generateContent(content);
      return response.text ?? style;
    } catch (e) {
      print('Prompt enhancement error: $e');
      return style;
    }
  }
}
