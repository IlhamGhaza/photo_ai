# Photo AI

Photo AI is a Flutter application that transforms user photos into travel-inspired looks by combining Google Gemini prompt engineering with Pollinations image generation and Firebase-backed persistence.

## Table of Contents

- [Photo AI](#photo-ai)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Key Features](#key-features)
  - [Tech Stack](#tech-stack)
  - [Architecture Overview](#architecture-overview)
  - [Setup Instructions](#setup-instructions)
  - [Project Structure](#project-structure)
  - [Security Approach](#security-approach)
  - [Development Tips](#development-tips)
  - [Additional Documentation](#additional-documentation)

## Overview

Users upload a photo, trigger AI-assisted restyling, and browse the generated results inside a polished mobile UI. Anonymous Firebase authentication keeps each user's gallery isolated while Firestore and Cloud Storage persist originals and generated outputs. The experience is optimized for a delightful progress flow, rich visuals, and the ability to save favorite variations.

## Key Features

- **One-tap photo upload** with gallery picker, inline replacement, and reset controls.
- **AI style generation pipeline** that produces up to six curated travel or lifestyle treatments per photo while visualizing progress and errors clearly.
- **Animated result gallery** with shimmer states, bookmarking, and full-screen preview for generated images.
- **Saved collection** that automatically restores previous generations from Firestore when the app launches.

## Tech Stack

- **Framework**: Flutter (Material 3, Provider for state management)
- **AI Services**: Google Gemini (prompt generation), Pollinations (image rendering)
- **Backend**: Firebase Authentication (anonymous), Cloud Firestore, Cloud Storage
- **Tooling**: Envied for environment variables, Shimmer and CachedNetworkImage for UI polish

## Architecture Overview

Photo AI follows a layered architecture that separates presentation, domain logic, and infrastructure services. Provider manages UI state, while repository classes encapsulate the integrations with Gemini, Pollinations, and Firebase. The flow is intentionally linear so each step can report progress, handle errors, and persist intermediate results.

1. **Authentication** – The app signs users in anonymously and stores a persistent UID using secure storage.
2. **Image upload** – Original photos are uploaded to Firebase Storage and registered in Firestore.
3. **Prompt generation** – Gemini produces descriptive style prompts tailored to the uploaded photo.
4. **Image rendering** – Pollinations renders final images from the enhanced prompts.
5. **Persistence & UI** – Generated URLs are saved back to Firestore and rendered in the UI with save/unsave controls.

## Setup Instructions

Follow these steps to get the application running locally. See [SETUP.md](SETUP.md) for expanded guidance, rationale, and troubleshooting.

1. **Install prerequisites** – Ensure Flutter 3.9.x+ is available and run `flutter --version` to confirm.
2. **Fetch dependencies** – Clone the repository and install packages:

   ```bash
   git clone https://github.com/IlhamGhaza/photo_ai.git
   cd photo_ai
   flutter pub get
   ```

3. **Create environment file** – Add a `.env` file at the project root with your Gemini key:

   ```ini
   GEMINI_API_KEY=your-google-gemini-api-key
   ```

4. **Generate Envied bindings** – Produce `env.g.dart` so secrets are available at runtime:

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Configure Firebase** – Download `google-services.json` and `GoogleService-Info.plist`, or rerun `flutterfire configure` if using a different Firebase project.
6. **Run the app** – Launch on your target device:

   ```bash
   flutter run
   ```

## Project Structure

```text
lib/
  core/            # Theme, constants, services (auth, env helpers)
  data/            # Models and repositories (Gemini, AI image, Firestore, Storage)
  presentation/    # Home screen widgets, providers, and pages
assets/
  images/          # App branding assets
android/ios/       # platform-specific Firebase configuration
```

## Security Approach

- **Secret management** – Environment variables are stored in an untracked `.env` file, and Envied generates type-safe accessors in `env.g.dart`.
- **User isolation** – Anonymous authentication issues a unique UID per device and stores it securely using `FlutterSecureStorage` so each gallery remains private.
- **Data persistence** – Firebase Security Rules (see `firestore.rules` and `storage.rules`) restrict reads and writes to authenticated users' own documents and images.
- **API usage** – Gemini keys are never committed; network calls to Pollinations rely on public endpoints without sensitive credentials.

## Development Tips

- Regenerate `env.g.dart` whenever `.env` changes:

  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

- Use Flutter's DevTools or `flutter run -d chrome` for rapid UI iteration.

## Additional Documentation

- [SETUP.md](SETUP.md) — complete environment, Firebase, and secrets configuration guide.
