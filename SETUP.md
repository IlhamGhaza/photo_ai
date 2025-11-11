# Photo AI Setup Guide

This document explains how to prepare your local environment to run Photo AI, configure required services, and manage secrets that are intentionally excluded from version control.

## 1. Prerequisites

1. **Flutter SDK**: Install Flutter 3.9.x (or newer compatible with `sdk: ^3.9.2`). Follow the [official installation guide](https://docs.flutter.dev/get-started/install) for your OS.
2. **Dart**: Included with Flutter.
3. **Node.js**: Install Node.js 18+ for Firebase Cloud Functions. Download from [nodejs.org](https://nodejs.org/).
4. **Firebase CLI** *(required)*: `npm install -g firebase-tools`
5. **Google Cloud project** with the Gemini API enabled.
6. **Access to the Google Gemini Image API** with billing enabled.

Confirm Flutter is installed:

```bash
flutter --version
```

## 2. Clone and Bootstrap

```bash
git clone <repo-url>
cd photo_ai
flutter pub get
```

## 3. Firebase Configuration

Photo AI relies on Firebase Authentication, Cloud Firestore, and Cloud Storage. Create a Firebase project (or reuse an existing one) and enable the following services:

1. **Authentication** → Enable Anonymous sign-in.
2. **Firestore Database** → Create a Firestore database in production mode or apply the rules found in `firestore.rules`. The rules limit access to `users/{uid}/images/*` and `users/{uid}/saved/*`.
3. **Storage** → Enable Cloud Storage and ensure rules restrict access to per-user folders.

### 4.1 Platform Credentials

Use the FlutterFire CLI or Firebase console to download the configuration files and place them in the repository:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

If you run `flutterfire configure`, ensure it targets the same Firebase project across Android and iOS. After configuration, regenerate `lib/firebase_options.dart` if necessary.

### 4.2 Default Firebase Options

The repo currently includes generated options in `lib/firebase_options.dart`. If you create a new Firebase project, rerun:

```bash
flutterfire configure
```

Then replace the generated file and platform resources with the new ones.

## 5. Firebase Cloud Functions Setup

The app requires Firebase Cloud Functions to handle AI image generation securely. The functions protect API keys and enforce authentication.

### 5.1 Install Function Dependencies

Navigate to the functions directory and install Node.js dependencies:

```bash
cd functions
npm install
```

### 5.2 Configure Function Environment Variables

Set your Gemini API key in Firebase config (this keeps it secure on the server). `functions:env` is the supported command for Cloud Functions v2:

```bash
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY"
```

To verify the configuration:

```bash
firebase functions:config:get
```

### 5.3 Deploy Cloud Functions

Deploy the functions to your Firebase project:

```bash
firebase deploy --only functions
```

Or deploy specific functions:

```bash
firebase deploy --only functions:generateImages
```

The Cloud Function saves generated assets inside `users/{uid}/generated/`. By default the function calls `file.makePublic()` so the Flutter client can display images immediately. If you prefer signed URLs instead of public files, grant the Cloud Functions service account (`PROJECT_ID@appspot.gserviceaccount.com`) the `roles/iam.serviceAccountTokenCreator` role and replace the public URL logic.

### 5.4 Test Cloud Functions

Test the health check endpoint:

```bash
firebase functions:shell
> healthCheck()
```

Or test locally with emulators:

```bash
npm run serve
```

The functions will be available at `http://localhost:5001/YOUR_PROJECT_ID/us-central1/generateImages`

### 5.5 Monitor Function Logs

View real-time logs:

```bash
npm run logs
```

Or in Firebase Console: Functions → Logs

Return to the project root after setup:

```bash
cd ..
```

## 6. Emulator vs. Production

- **Local development**: You can point Firestore and Storage to local emulators. Update repository services to use emulator hosts before running.
- **Production**: Ensure Firebase security rules match your deployment strategy before shipping.

## 7. Running the App

```bash
flutter run
```

Choose your preferred device (Android emulator, iOS simulator, or physical device). The app signs the user in anonymously on launch and persists the UID via secure storage.

## 8. Testing & QA

Currently, only the default widget test exists. Add more coverage as features grow:

```bash
flutter test
```

## 9. Troubleshooting

| Issue | Resolution |
| ----- | ---------- |
| `MissingPluginException` on Firebase services | Run `flutter clean`, then `flutter pub get`. Make sure Firebase initialization occurs before usage. |
| `Gemini API Error` in console | Verify `GEMINI_API_KEY` is correct, billing is enabled, and the model `gemini-2.5-flash-image` is available. |
| Generated images not appearing | Ensure the Cloud Function deployed successfully, images exist in `users/{uid}/generated/`, and Storage rules permit reads for the authenticated user. |
| Cloud Functions not deploying | Ensure Node.js 18+ is installed and Firebase CLI is up to date. Check `firebase login` status. |
| Cloud Functions timeout | Increase timeout in `functions/index.js` (currently 9 minutes) or check Gemini API response time. |
| `unauthenticated` error from functions | Ensure user is signed in before calling functions. Check Firebase Auth setup. |

## 10. Deployment Checklist

1. Verify no API keys or secrets in mobile app code.
2. Deploy Cloud Functions: `cd functions && firebase deploy --only functions && cd ..`
3. Verify Cloud Functions are working: Test with `healthCheck` function.
4. Ensure production Firebase rules are applied (`firestore.rules` and `storage.rules`).
5. Verify Gemini API usage limits suit production load.
6. Test the complete flow: Upload → Generate → Display.
7. Generate release builds with:
   - Android: `flutter build appbundle`
   - iOS: `flutter build ipa`

Keep this document updated whenever infrastructure or configuration requirements change.
