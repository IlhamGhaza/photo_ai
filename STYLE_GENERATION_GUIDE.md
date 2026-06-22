# Social Media Style Photo Generation - Implementation Guide

## Overview
This implementation enables realistic social media-style photo generation where users can select a scene (beach, mountain, car, city, café, night_city) and the AI naturally integrates the person from the uploaded photo into that environment.

## Architecture

### 1. Cloud Function (Backend)
**File**: `functions/index.js`

#### Key Features:
- Accepts `selectedStyle` parameter from client
- Implements scene-specific configurations with detailed prompts
- Uses Google Gemini 2.5 Flash Image model for realistic photo composition
- Returns generated images uploaded to Firebase Storage

#### Scene Configurations:
```javascript
const sceneConfigs = {
  beach: {
    name: "Beach Escape",
    description: "sunny beach with white sand and turquoise ocean",
    lighting: "warm golden hour sunlight, soft shadows on sand",
    atmosphere: "relaxed vacation vibe, gentle ocean breeze feel",
  },
  mountain: { ... },
  car: { ... },
  city: { ... },
  café: { ... },
  night_city: { ... }
}
```

#### Prompt Engineering:
The prompt is designed to ensure:
- Person remains fully recognizable (face, body, clothing)
- Natural integration into the scene (no cut-out effect)
- Realistic lighting, shadows, and reflections
- Phone-camera realism for authentic social media look
- Proper scale and perspective matching

### 2. Functions Repository (Data Layer)
**File**: `lib/data/repositories/functions_repository.dart`

#### Updates:
- Added optional `selectedStyle` parameter to both methods:
  - `generateImages()`
  - `generateImagesWithTimeout()`
- Passes style to Cloud Function when provided

```dart
Future<Map<String, dynamic>> generateImagesWithTimeout({
  required String imageUrl,
  String? selectedStyle,  // NEW
  Duration timeout = const Duration(minutes: 5),
})
```

### 3. Photo Provider (State Management)
**File**: `lib/presentation/home/providers/photo_provider.dart`

#### New Features:
- `_selectedStyle` state variable
- `selectedStyle` getter
- `setSelectedStyle(String? style)` method
- Updated `generateImages()` to accept and pass `selectedStyle`

```dart
// Set style before generation
void setSelectedStyle(String? style) {
  _selectedStyle = style;
  notifyListeners();
}

// Generate with selected style
Future<void> generateImages({String? selectedStyle}) async {
  final styleToUse = selectedStyle ?? _selectedStyle;
  // ... pass to Cloud Function
}
```

### 4. Style Selector Widget (UI)
**File**: `lib/presentation/home/widgets/style_selector.dart`

#### Components:

**StyleOption Model:**
```dart
class StyleOption {
  final String id;        // 'beach', 'mountain', etc.
  final String name;      // Display name
  final String description;
  final IconData icon;
  final Color color;
}
```

**Available Styles:**
- 🏖️ Beach Escape (beach)
- 🏔️ Mountain Adventure (mountain)
- 🚗 Luxury Car (car)
- 🏙️ City Life (city)
- ☕ Café Moment (café)
- 🌃 Night City (night_city)

**UI Features:**
- Beautiful grid layout (2 columns)
- Animated selection with color-coded borders
- Icon and description for each style
- Checkmark indicator for selected style
- Disabled state during generation

### 5. Generate Section (UI Integration)
**File**: `lib/presentation/home/widgets/generate_section.dart`

#### Updates:
- Added `selectedStyle` and `onStyleSelected` parameters
- Displays `StyleSelector` when image is uploaded and not generating
- Passes selected style to parent component

```dart
if (widget.hasUploadedImage && !isGenerating) ...[
  StyleSelector(
    selectedStyle: widget.selectedStyle,
    onStyleSelected: widget.onStyleSelected,
    enabled: !isGenerating,
  ),
  const SizedBox(height: 24),
],
```

### 6. Home Page (Integration)
**File**: `lib/presentation/home/pages/home_page.dart`

#### Updates:
- Passes `provider.selectedStyle` to GenerateSection
- Connects `onStyleSelected` to `provider.setSelectedStyle()`
- Maintains state through provider

## User Flow

1. **Upload Photo**: User uploads their photo
2. **Select Style**: StyleSelector appears with 6 scene options
3. **Choose Scene**: User taps a style card (e.g., "Beach Escape")
4. **Generate**: User clicks "Generate Styles" button
5. **Processing**: 
   - Selected style is sent to Cloud Function
   - Gemini AI generates realistic photo with person in selected scene
   - Image is uploaded to Firebase Storage
6. **Results**: Generated photo appears in results tab

## Prompt Structure

The Cloud Function uses this prompt structure:

```
Generate a realistic social-media-style photo using the person in the input image.
Place the person naturally in the selected scene.

Selected scene: {targetScene.name}

Requirements:
- Keep the person fully recognizable (face, body shape, clothing)
- Make the person appear genuinely present in the environment: {description}
- Match lighting: {lighting}
- Ensure there is NO cut-out effect or visible edges around the person
- Make the result look like a real lifestyle photo taken with a phone camera
- Blend colors and depth so the scene feels natural
- Create atmosphere: {atmosphere}
- Add realistic shadows, reflections, and perspective matching
- Ensure proper scale and proportions for the scene

Output:
A high-quality lifestyle photo where the person is naturally integrated into the scene.
The photo should look authentic, as if taken during a real moment in this location.
```

## API Contract

### Cloud Function Input:
```json
{
  "imageUrl": "https://storage.googleapis.com/...",
  "selectedStyle": "beach"  // optional, defaults to "beach"
}
```

### Cloud Function Output:
```json
{
  "success": true,
  "generatedUrls": ["https://storage.googleapis.com/..."],
  "styles": ["Beach Escape"],
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Testing

### Manual Testing Steps:
1. Run the app and authenticate
2. Upload a portrait photo
3. Verify StyleSelector appears with 6 options
4. Select different styles and verify visual feedback
5. Click "Generate Styles" with a selected style
6. Verify Cloud Function receives correct style parameter
7. Check generated image matches selected scene

### Cloud Function Testing:
```bash
# Deploy function
firebase deploy --only functions:generateImages

# Test with Firebase Console or curl
curl -X POST https://us-central1-YOUR_PROJECT.cloudfunctions.net/generateImages \
  -H "Content-Type: application/json" \
  -d '{"imageUrl": "...", "selectedStyle": "beach"}'
```

## Future Enhancements

1. **Custom Styles**: Allow users to describe custom scenes
2. **Style Previews**: Show example images for each style
3. **Multiple Generations**: Generate multiple variations of same style
4. **Style History**: Remember user's favorite styles
5. **Advanced Controls**: Fine-tune lighting, atmosphere, etc.

## Troubleshooting

### Style Not Applied:
- Check Cloud Function logs for received `selectedStyle`
- Verify parameter is passed through all layers
- Ensure style ID matches scene config keys

### Generation Fails:
- Check Gemini API quota and limits
- Verify image URL is accessible
- Review Cloud Function timeout settings (currently 9 minutes)

### UI Not Showing Selector:
- Verify image is uploaded (`hasUploadedImage` is true)
- Check that app is not in generating state
- Ensure StyleSelector import is correct

## Code Quality

- ✅ Type-safe with proper TypeScript/Dart types
- ✅ Error handling at all layers
- ✅ Responsive UI with loading states
- ✅ Clean separation of concerns
- ✅ Comprehensive documentation
- ✅ Follows Flutter/Firebase best practices
