import '../utils/env.dart';

class AppConstants {
  // Gemini AI Configuration
  static const String geminiApiKey = Env.geminiApiKey;
  
  // Image Generation Prompts
  static const List<String> travelStyles = [
    'Mountain Vista - dramatic mountain landscape at golden hour',
    'Beach Paradise - tropical beach with crystal clear water',
    'Lake Serenity - peaceful lake surrounded by nature',
    'Desert Adventure - vast desert landscape with sand dunes',
    'Forest Trail - lush forest path with sunlight filtering through trees',
    'City Lights - vibrant cityscape at night with lights',
  ];
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // UI Constants
  static const double maxWidth = 480.0;
  static const double horizontalPadding = 24.0;
  static const double borderRadius = 24.0;
  static const double cardBorderRadius = 16.0;
  
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
}
