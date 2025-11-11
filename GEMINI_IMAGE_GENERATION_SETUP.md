# 🎨 Gemini Image Generation Setup Guide

## Overview

The **Photo AI app** now uses the **Google Gemini 2.5 Flash Image** model to generate **4 photo variations** with different social-media-style moods from a single uploaded user photo.

### How It Works

1. User uploads a photo
2. The system sends the photo to the **Gemini 2.5 Flash Image model** with a custom prompt
3. Gemini generates **4 styled photos (streaming output)**
4. Backend uploads generated images to **Firebase Storage**
5. Returns **storage URLs** (not base64) to the Flutter app
6. The generated styles only adjust lighting/mood — **not the background**:

   * ✨ **Golden Hour Glow** — warm golden hour lighting, sunset tones, Instagram-perfect glow
   * 🎬 **Cinematic Drama** — dramatic lighting, deeper contrast, moody atmosphere
   * 🌈 **Vibrant Pop** — boosted colors, vibrant and saturated, eye-catching
   * 💫 **Dreamy Soft** — soft dreamy filter, pastel tones, ethereal mood

---

## 📋 Prerequisites

* Google Cloud Project
* Firebase Project (already set up)
* Node.js & npm installed
* Firebase CLI installed

---

## 🔧 Setup Steps

### 1. Get a Gemini API Key

#### A. Open Google AI Studio

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click **“Get API Key”** on the left sidebar

#### B. Create an API Key

1. Choose **“Create API key in new project”** or select an existing project
2. Copy the generated API key
3. **IMPORTANT:** Store the API key securely — never share it publicly!

---

### 2. Set the API Key in Firebase

> **Note:** In Cloud Functions v2, `functions.config()` is deprecated. Use the new `firebase functions:env` command for environment variables.

#### Option A: Using Firebase CLI (Recommended)

```bash
# Set Gemini API key
firebase functions:env:set GEMINI_API_KEY="YOUR_GEMINI_API_KEY_HERE"

# Verify configuration
firebase functions:env:get
```

#### Option B: Using Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Functions → Configuration**
4. Add environment variable:

   * Key: `GEMINI_API_KEY`
   * Value: your API key

---

### 3. Deploy the Functions

```bash
# Go to functions directory
cd functions

# Install dependencies (includes @google/genai for Gemini 2.5 Flash Image)
npm install

# Deploy to Firebase
firebase deploy --only functions
```

---

### 4. Test the Function

After deployment, test by calling the function from your Flutter app or manually:

```javascript
// Test from Flutter
final result = await FirebaseFunctions.instance
    .httpsCallable('generateImages')
    .call({
      'imageUrl': 'https://your-firebase-storage-url.com/image.jpg'
    });
```

---

## 🔑 API Key Security Best Practices

### ✅ DO

* Store the API key in Firebase environment config
* Call Gemini API **only** through Firebase Functions (server-side)
* Restrict API key usage in Google Cloud Console
* Monitor API usage regularly

### ❌ DON’T

* Hardcode API keys in source code
* Commit API keys to Git repositories
* Share API keys publicly
* Expose API keys in client-side code

---

## 💰 Pricing & Quotas

### Gemini 2.5 Flash Image Pricing

* **Text Input:** $0.30 per 1M tokens
* **Image Output:** $0.039 per image
* **Knowledge cutoff:** June 2025
* Latest pricing: [Google AI Pricing](https://ai.google.dev/pricing)

### Cost Optimization Tips

1. Implement caching for identical results
2. Add rate limiting in your Flutter app
3. Monitor usage in Google Cloud Console
4. Consider batch processing for multiple users

---

## 🐛 Troubleshooting

### Error: “GEMINI_API_KEY not configured”

**Fix:**

```bash
firebase functions:env:set GEMINI_API_KEY="YOUR_KEY"
firebase deploy --only functions
```

### Error: “API key not valid”

**Fix:**

1. Verify the API key in Google AI Studio
2. Check API key permissions
3. Regenerate the API key if needed

### Error: “Quota exceeded”

**Fix:**

1. Check usage in Google Cloud Console
2. Wait for quota reset (per minute/day)
3. Upgrade to a paid tier if needed

### Images not generating

**Fix:**

1. Check Firebase Function logs: `firebase functions:log`
2. Verify the image URL is accessible
3. Check Gemini API status
4. Ensure timeout is sufficient (2 minutes per image)

---

## 📊 Monitoring

### View Function Logs

```bash
# Real-time logs
firebase functions:log --only generateImages

# Logs from the last hour
firebase functions:log --since 1h
```

### Check Function Performance

1. Open Firebase Console
2. Go to **Functions → Dashboard**
3. Monitor:

   * Invocations
   * Execution time
   * Error rate
   * Memory usage

---

## 🔄 Updates & Maintenance

### Update Gemini API Key

```bash
# Update key
firebase functions:config:set gemini.api_key="NEW_KEY"

# Redeploy
firebase deploy --only functions
```

### Update Prompts

Edit the `socialMediaStyles` array inside `functions/index.js` to customize prompts.

### Add More Styles

Add a new object to the `socialMediaStyles` array:

```javascript
{
  name: "Your Style Name",
  prompt: "Your detailed prompt here..."
}
```

---

## 📝 Notes

* **Model:** Gemini 2.5 Flash Image (state-of-the-art image generation & editing)
* **Image Format:** Function accepts JPEG images from Firebase Storage
* **Response Format:** Returns signed Firebase Storage URLs (private, expires in 7 days)
* **Storage Path:** `users/{userId}/generated/` (private per user)
* **Image Size:** 1024×1024 (1K resolution)
* **Style Changes:** Only lighting, color grading, and mood — original scene/background remain
* **Timeout:** 9 minutes total (540 seconds) for 4 images
* **Concurrency:** Up to 10 instances running simultaneously

---

## 🆘 Support

If you run into issues:

1. Check Firebase Functions logs
2. Verify Gemini API key status
3. Check Google Cloud Console for quota/billing issues
4. Review error messages in the Flutter app

---

## 📚 Resources

* [Gemini API Documentation](https://ai.google.dev/docs)
* [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
* [Google AI Studio](https://aistudio.google.com/)
* [Firebase Console](https://console.firebase.google.com/)

---

**Last Updated:** November 2024
**Version:** 1.0.0
