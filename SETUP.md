# Photo AI Setup Guide

This document explains how to prepare your local environment to run Photo AI, configure required services, and manage secrets that are intentionally excluded from version control.

## 1. Prerequisites

1. **Flutter SDK**: Install Flutter 3.9.x (or newer compatible with `sdk: ^3.9.2`). Follow the [official installation guide](https://docs.flutter.dev/get-started/install) for your OS.
2. **Dart**: Included with Flutter.
3. **Firebase CLI** *(optional but recommended)*: `npm install -g firebase-tools`
4. **Google Cloud project** with the Gemini API enabled.
5. **Access to the Pollinations image API** (public endpoint, no key required).

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

## 3. Environment Variables (`.env`)

Sensitive configuration values live in a `.env` file that is **not** committed. Create the file at the repository root:

```ini
# .env
GEMINI_API_KEY=your-google-gemini-api-key
```

> **Tip:** Keep a secure copy of this file; it is required whenever you set up a new machine or CI pipeline.

### 3.1 Generate `env.g.dart`

This project uses [Envied](https://pub.dev/packages/envied) to generate strongly typed accessors. Whenever `.env` changes (or on first setup), run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

The command creates `lib/core/utils/env.g.dart`, which should remain untracked (check `.gitignore`).

## 4. Firebase Configuration

Photo AI relies on Firebase Authentication, Cloud Firestore, and Cloud Storage. Create a Firebase project (or reuse an existing one) and enable the following services:

1. **Authentication** → Enable Anonymous sign-in.
2. **Firestore Database** → Create a Firestore database in production mode or apply the development rules found in `firestore.rules`.
3. **Storage** → Enable Cloud Storage and apply `storage.rules` if needed.

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

## 5. Emulator vs. Production

- **Local development**: You can point Firestore and Storage to local emulators. Update repository services to use emulator hosts before running.
- **Production**: Ensure Firebase security rules match your deployment strategy before shipping.

## 6. Running the App

```bash
flutter run
```

Choose your preferred device (Android emulator, iOS simulator, or physical device). The app signs the user in anonymously on launch and persists the UID via secure storage.

## 7. Testing & QA

Currently, only the default widget test exists. Add more coverage as features grow:

```bash
flutter test
```

## 8. Troubleshooting

| Issue | Resolution |
| ----- | ---------- |
| `MissingPluginException` on Firebase services | Run `flutter clean`, then `flutter pub get`. Make sure Firebase initialization occurs before usage. |
| `Gemini API Error` in console | Verify `GEMINI_API_KEY` is correct and has sufficient quota/API access. |
| Generated images not appearing | Check Pollinations availability and ensure network access on the device. |
| `env.g.dart` missing | Re-run the build_runner command in [Section 3.1](#31-generate-envgdart). |

## 9. Deployment Checklist

1. Confirm `.env` and `env.g.dart` are excluded from commits.
2. Ensure production Firebase rules are applied.
3. Verify Gemini API usage limits suit production load.
4. Generate release builds with:
   - Android: `flutter build appbundle`
   - iOS: `flutter build ipa`

Keep this document updated whenever infrastructure or configuration requirements change.
