# Security Architecture

## Overview

Photo AI implements a **zero-trust client architecture** where **NO sensitive logic or API keys exist in the mobile application**. All AI processing, API calls, and business logic are executed server-side in Firebase Cloud Functions.

## Architecture Principle

### ❌ INSECURE (What We DON'T Do)

```
Mobile App
    ├─ Contains Gemini API Key ❌
    ├─ Contains AI prompt logic ❌
    ├─ Calls Gemini API directly ❌
    └─ Calls Pollinations API directly ❌
    
⚠️ PROBLEM: User can decompile APK/IPA and extract:
   - API keys
   - AI prompts
   - Business logic
   - API endpoints
```

### ✅ SECURE (What We DO)

```
Mobile App
    ├─ NO API keys ✅
    ├─ NO AI logic ✅
    ├─ Only calls Cloud Functions ✅
    └─ Only handles UI/UX ✅

Cloud Functions (Backend)
    ├─ Contains Gemini API Key (secure) ✅
    ├─ Contains AI prompt logic ✅
    ├─ Calls Gemini API ✅
    ├─ Calls Pollinations API ✅
    └─ Validates authentication ✅

✅ SECURE: User cannot extract anything sensitive from mobile app
```

## Data Flow

### 1. Image Upload (Client-Side)

```
User selects image
    ↓
Upload to Firebase Storage
    ↓
Get public URL
    ↓
Save URL to Firestore
```

**Security:**
- Storage rules enforce user isolation
- Only authenticated users can upload
- Each user can only access their own files

### 2. AI Generation (Server-Side ONLY)

```
Mobile App
    ↓
Call Cloud Function with image URL
    ↓
Cloud Function (Backend):
    ├─ Validate authentication
    ├─ Download image from Storage
    ├─ Call Gemini API (with server-side key)
    ├─ Generate prompts
    ├─ Call Pollinations API
    ├─ Generate images
    └─ Return URLs to client
    ↓
Mobile App
    ↓
Display images
    ↓
Save to Firestore
```

**Security:**
- Mobile app never sees API keys
- Mobile app never sees AI prompts
- Mobile app never calls AI APIs directly
- All sensitive logic is server-side

## Code Structure

### Mobile App (`lib/`)

**What's Included:**
- UI components
- State management (Provider)
- Firebase client SDKs (Auth, Firestore, Storage, Functions)
- Image picker and display logic

**What's NOT Included:**
- ❌ NO API keys
- ❌ NO Gemini SDK
- ❌ NO AI generation logic
- ❌ NO prompt engineering
- ❌ NO direct AI API calls

### Cloud Functions (`functions/`)

**What's Included:**
- Gemini API integration
- Pollinations API integration
- Prompt engineering logic
- Image generation orchestration
- Authentication validation
- Error handling

**Security Measures:**
- API keys stored in Firebase config (not in code)
- Environment variables never committed
- Authentication required on all functions
- Input validation and sanitization

## Removed Dependencies

The following packages were **removed** from `pubspec.yaml` because they're no longer needed:

```yaml
# REMOVED - No longer needed in mobile app
google_generative_ai: ^0.4.7  # Gemini SDK (now in Cloud Functions)
envied: ^1.1.1                 # Environment variables (no secrets in app)
envied_generator: ^1.1.1       # Code generation (not needed)
build_runner: ^2.4.8           # Build tools (not needed)
http: ^1.2.0                   # HTTP client (not needed)
image: ^4.5.2                  # Image processing (not needed)
```

## Deleted Files

The following files were **deleted** because they contained sensitive logic:

```
lib/data/repositories/gemini_repository.dart      # Direct Gemini API calls
lib/data/repositories/ai_image_repository.dart    # Direct AI logic
lib/core/utils/env.dart                           # API key management
lib/core/utils/env.g.dart                         # Generated secrets
```

## Attack Surface Analysis

### Before (Insecure)

**Attack Vectors:**
1. ✅ Decompile APK → Extract Gemini API key
2. ✅ Reverse engineer → See AI prompts
3. ✅ Network sniffing → Intercept API calls
4. ✅ Code analysis → Understand business logic

**Impact:** Complete compromise of AI system

### After (Secure)

**Attack Vectors:**
1. ❌ Decompile APK → Find nothing (only Cloud Function calls)
2. ❌ Reverse engineer → No AI logic in app
3. ⚠️ Network sniffing → Only see Firebase URLs (authenticated)
4. ❌ Code analysis → Only UI code

**Impact:** Minimal - attacker only sees UI code

## Authentication Flow

```
App Launch
    ↓
Firebase Anonymous Auth
    ↓
Store UID in Secure Storage
    ↓
All requests include auth token
    ↓
Cloud Functions validate token
    ↓
Process request if valid
```

**Security:**
- Every Cloud Function call requires authentication
- Anonymous auth provides unique UID per device
- UID stored securely using FlutterSecureStorage
- Cloud Functions reject unauthenticated requests

## API Key Management

### Mobile App
```dart
// NO API KEYS IN MOBILE APP ✅
// Only calls Cloud Functions
final result = await _functionsRepository.generateImages(
  imageUrl: imageUrl,
);
```

### Cloud Functions
```javascript
// API key stored in Firebase config ✅
const geminiApiKey = process.env.GEMINI_API_KEY;

// Set via Firebase CLI:
// firebase functions:config:set gemini.api_key="YOUR_KEY"
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/images/{imageId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

## Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own files
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

## Best Practices Implemented

1. **Zero Trust Client**
   - Mobile app is considered untrusted
   - All sensitive operations on backend

2. **Principle of Least Privilege**
   - Mobile app only has access to UI operations
   - Backend has access to AI APIs

3. **Defense in Depth**
   - Authentication required
   - Security rules enforced
   - Input validation on backend

4. **Secure by Default**
   - No secrets in code
   - No sensitive logic in client
   - All AI processing server-side

## Compliance

This architecture ensures:

- ✅ API keys never exposed to end users
- ✅ Business logic protected from reverse engineering
- ✅ User data isolated and protected
- ✅ Audit trail via Cloud Functions logs
- ✅ Rate limiting via Cloud Functions
- ✅ Cost control via backend monitoring

## Monitoring

Cloud Functions provide:

- Request logs
- Error tracking
- Performance metrics
- Usage statistics
- Cost monitoring

All accessible via Firebase Console without exposing sensitive data.

## Summary

**Mobile App = UI Only**
- No secrets
- No AI logic
- No direct API calls
- Only calls Cloud Functions

**Cloud Functions = All Logic**
- Contains API keys (secure)
- Contains AI logic
- Handles all AI API calls
- Validates authentication
- Enforces security

This architecture ensures that even if an attacker fully decompiles and analyzes the mobile app, they gain **zero access** to:
- API keys
- AI prompts
- Business logic
- Backend infrastructure

**Result: Maximum security with zero client-side secrets.**
