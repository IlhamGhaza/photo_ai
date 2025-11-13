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
      // "Luxury Supercar Showcase - Place the person in front of a sleek supercar parked on a modern city street at sunset with glossy reflections and cinematic lighting",
      "Jetset Rooftop Lounge - Move the person to a chic rooftop bar overlooking a nighttime skyline filled with neon ambience and atmospheric glow",
      // "Tropical Beach Escape - Position the person on a white sand beach with turquoise water, palm trees, and warm golden hour light",
      // "European City Stroll - Set the person in a historic European alley with cobblestone streets, charming cafés, and twinkling evening lights",
    ];

    // Initialize Gemini AI client
    const ai = new GoogleGenAI({
      apiKey: geminiApiKey,
    });

    // Build prompt for all 4 styles
    const stylePrompt = `Transform this portrait into 4 immersive scenes featuring the same person. For each style below, create a photorealistic composite:

${socialMediaStyles.map((style, i) => `${i + 1}. ${style}`).join("\n")}

GUIDELINES - FOLLOW EXACTLY:
- Preserve the person's face, pose, proportions, and clothing details
- Adjust the environment, background, props, lighting, and color grading to match each style description
- Ensure the composites look natural and photorealistic with consistent perspective
- Do not duplicate the person or alter their identity, expression, or wardrobe
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
