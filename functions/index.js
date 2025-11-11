/**
 * Firebase Cloud Functions for Photo AI
 * 
 * This module handles secure AI image generation by:
 * 1. Receiving image URLs from authenticated Flutter clients
 * 2. Calling Google Gemini API to generate 6 social media style variations
 * 3. Returning generated image URLs from Gemini to the client
 * 
 * Security: API keys are stored in Firebase environment config,
 * never exposed to the client.
 */

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {defineString} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const {GoogleGenAI} = require("@google/genai");

// Initialize Firebase Admin
admin.initializeApp();

// Set global options for all functions
setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
  timeoutSeconds: 540, // 9 minutes for AI generation
  memory: "512MiB",
});

// Read Gemini API key from deployed environment variables
const GEMINI_API_KEY = defineString("GEMINI_API_KEY");

/**
 * Generate AI images from an uploaded photo
 * 
 * @param {Object} data - Request data
 * @param {string} data.imageUrl - URL of the uploaded image in Firebase Storage
 * @param {Object} context - Function context with auth info
 * @returns {Promise<Object>} Object containing array of generated image URLs
 */
exports.generateImages = onCall(async (request) => {
  const {data, auth} = request;

  // Verify authentication
  if (!auth) {
    throw new HttpsError(
        "unauthenticated",
        "User must be authenticated to generate images",
    );
  }

  // Validate input
  if (!data.imageUrl || typeof data.imageUrl !== "string") {
    throw new HttpsError(
        "invalid-argument",
        "imageUrl is required and must be a string",
    );
  }

  const {imageUrl} = data;
  const userId = auth.uid;

  console.log(`Generating images for user ${userId} with image: ${imageUrl}`);

  try {
    // Generate 4 social media style variations using Gemini
    const generatedImages = await generateSocialMediaVariations(imageUrl, userId);
    console.log(`Generated ${generatedImages.length} image variations`);

    // Return results
    return {
      success: true,
      generatedUrls: generatedImages.map(img => img.url),
      styles: generatedImages.map(img => img.style),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error("Error generating images:", error);
    throw new HttpsError(
        "internal",
        `Failed to generate images: ${error.message}`,
    );
  }
});

/**
 * Generate 4 social media style variations using Google Gemini API
 * 
 * @param {string} imageUrl - URL of the image to transform
 * @param {string} userId - User ID for private storage path
 * @returns {Promise<Array<{url: string, style: string}>>} Array of generated images with styles
 */
async function generateSocialMediaVariations(imageUrl, userId) {
  // Get Gemini API key from environment config
  const geminiApiKey = GEMINI_API_KEY.value() || process.env.GEMINI_API_KEY;

  if (!geminiApiKey) {
    throw new Error("GEMINI_API_KEY not configured. Please set up Gemini API key in Firebase environment.");
  }

  try {
    // Download image from Firebase Storage
    const imageResponse = await axios.get(imageUrl, {
      responseType: "arraybuffer",
      timeout: 30000,
    });
    const imageBase64 = Buffer.from(imageResponse.data).toString("base64");

    // Generate 4 variations with social media styles (Gemini 2.5 Flash Image limit)
    const generatedImages = [];
    const socialMediaStyles = [
      "Golden Hour Glow - Keep the exact same scene and background, but change to warm golden hour lighting with sunset tones, soft shadows, and that Instagram-perfect glow",
      "Cinematic Drama - Maintain the same location and composition, but add dramatic lighting, deeper contrast, moody atmosphere, like a movie scene",
      "Vibrant Pop - Same scene but boost colors to be more vibrant and saturated, bright and eye-catching, perfect for social media engagement",
      "Dreamy Soft - Keep everything the same but add soft dreamy filter, pastel tones, gentle bokeh effect, ethereal and romantic mood",
    ];

    // Initialize Gemini AI client
    const ai = new GoogleGenAI({
      apiKey: geminiApiKey,
    });

    // Build prompt for all 4 styles
    const stylePrompt = `Generate 4 different style variations of this photo:

${socialMediaStyles.map((style, i) => `${i + 1}. ${style}`).join("\n")}

CRITICAL RULES - FOLLOW EXACTLY:
- DO NOT change the background, location, or scene
- DO NOT add new objects or remove existing elements
- DO NOT change the person's pose, position, or appearance
- ONLY change: lighting, color grading, mood, atmosphere, and photo filter
- Keep the EXACT same composition and setting as the original
- The result should look like the same photo taken at different times of day or with different camera settings
- Make it look natural and realistic, like photos people post on Instagram
- Generate exactly 4 images, one for each style above`;

    console.log("Generating 4 social media style variations...");

    try {
      // Use Gemini 2.5 Flash Image model with streaming
      const config = {
        responseModalities: ["IMAGE", "TEXT"],
        imageConfig: {
          imageSize: "1K",
        },
      };

      const model = "gemini-2.5-flash-image";
      const contents = [
        {
          role: "user",
          parts: [
            {
              text: stylePrompt,
            },
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: imageBase64,
              },
            },
          ],
        },
      ];

      const response = await ai.models.generateContentStream({
        model,
        config,
        contents,
      });

      let imageIndex = 0;
      for await (const chunk of response) {
        if (!chunk.candidates || !chunk.candidates[0].content || !chunk.candidates[0].content.parts) {
          continue;
        }

        // Extract image data from chunk
        if (chunk.candidates?.[0]?.content?.parts?.[0]?.inlineData) {
          const inlineData = chunk.candidates[0].content.parts[0].inlineData;
          const mimeType = inlineData.mimeType || "image/png";
          const imageData = inlineData.data;

          if (imageData && imageIndex < socialMediaStyles.length) {
            const styleName = socialMediaStyles[imageIndex].split(" - ")[0];
            
            // Upload to Firebase Storage instead of returning base64
            try {
              const imageBuffer = Buffer.from(imageData, "base64");
              const fileName = `generated_${Date.now()}_${imageIndex}.png`;
              const bucket = admin.storage().bucket();
              const file = bucket.file(`users/${userId}/generated/${fileName}`);
              
              await file.save(imageBuffer, {
                metadata: {
                  contentType: mimeType,
                },
              });
              
              // Make file publicly accessible
              await file.makePublic();
              
              // Small delay to ensure file is accessible
              await new Promise((resolve) => setTimeout(resolve, 500));
              
              // Get public URL
              const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;
              
              generatedImages.push({
                url: publicUrl,
                style: styleName,
              });
              
              console.log(`Generated and uploaded image ${imageIndex + 1}: ${styleName}`);
            } catch (uploadError) {
              console.error(`Error uploading image ${imageIndex + 1}:`, uploadError.message);
              // Skip this image if upload fails
            }
            
            imageIndex++;
          }
        }
      }
    } catch (error) {
      console.error("Error generating images with Gemini 2.5 Flash Image:", error.message);
      throw error;
    }

    if (generatedImages.length === 0) {
      throw new Error("Failed to generate any images. Please check Gemini API configuration.");
    }

    return generatedImages;
  } catch (error) {
    console.error("Error in generateSocialMediaVariations:", error.message);
    throw error;
  }
}


/**
 * Health check function for testing deployment
 */
exports.healthCheck = onCall(async (request) => {
  return {
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  };
});
