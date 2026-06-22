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

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const { GoogleGenAI } = require("@google/genai");

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
 * @param {string} data.selectedStyle - Target scene style (beach, mountain, car, city, café, night_city)
 * @param {Object} context - Function context with auth info
 * @returns {Promise<Object>} Object containing array of generated image URLs
 */
exports.generateImages = onCall(async (request) => {
  const { data, auth } = request;

  // Verify authentication
  if (!auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated to generate images"
    );
  }

  // Validate input
  if (!data.imageUrl || typeof data.imageUrl !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "imageUrl is required and must be a string"
    );
  }

  const { imageUrl, selectedStyle } = data;
  const userId = auth.uid;

  console.log(
    `Generating images for user ${userId} with image: ${imageUrl}, style: ${
      selectedStyle || "auto"
    }`
  );

  try {
    // Generate social media style photo using Gemini
    const generatedImages = await generateSocialMediaVariations(
      imageUrl,
      userId,
      selectedStyle
    );
    console.log(`Generated ${generatedImages.length} image variations`);

    // Return results
    return {
      success: true,
      generatedUrls: generatedImages.map((img) => img.url),
      styles: generatedImages.map((img) => img.style),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error) {
    console.error("Error generating images:", error);
    throw new HttpsError(
      "internal",
      `Failed to generate images: ${error.message}`
    );
  }
});

/**
 * Generate social media style photo using Google Gemini API
 *
 * @param {string} imageUrl - URL of the image to transform
 * @param {string} userId - User ID for private storage path
 * @param {string} selectedStyle - Target scene style (beach, mountain, car, city, café, night_city)
 * @returns {Promise<Array<{url: string, style: string}>>} Array of generated images with styles
 */
async function generateSocialMediaVariations(imageUrl, userId, selectedStyle) {
  // Get Gemini API key from environment config
  const geminiApiKey = GEMINI_API_KEY.value() || process.env.GEMINI_API_KEY;

  if (!geminiApiKey) {
    throw new Error(
      "GEMINI_API_KEY not configured. Please set up Gemini API key in Firebase environment."
    );
  }

  try {
    // Download image from Firebase Storage
    const imageResponse = await axios.get(imageUrl, {
      responseType: "arraybuffer",
      timeout: 30000,
    });
    const imageBase64 = Buffer.from(imageResponse.data).toString("base64");

    // Define scene configurations for realistic social media photos
    const sceneConfigs = {
      beach: {
        name: "Beach Escape",
        description: "sunny beach with white sand and turquoise ocean",
        lighting: "warm golden hour sunlight, soft shadows on sand",
        atmosphere: "relaxed vacation vibe, gentle ocean breeze feel",
      },
      mountain: {
        name: "Mountain Adventure",
        description: "scenic mountain landscape with green valleys and peaks",
        lighting: "fresh outdoor daylight, natural mountain atmosphere",
        atmosphere: "adventurous outdoor feel, crisp mountain air",
      },
      car: {
        name: "Luxury Car Lifestyle",
        description: "standing beside a modern luxury car on urban street",
        lighting: "urban ambient light with subtle reflections on car surface",
        atmosphere: "sophisticated lifestyle vibe, confident pose",
      },
      city: {
        name: "City Life",
        description:
          "vibrant city street with modern buildings and urban elements",
        lighting: "natural daylight with urban shadows and reflections",
        atmosphere: "energetic city lifestyle, contemporary urban feel",
      },
      café: {
        name: "Café Moment",
        description: "cozy café setting with warm interior or outdoor terrace",
        lighting: "soft ambient café lighting, warm and inviting tones",
        atmosphere: "casual relaxed vibe, social lifestyle feel",
      },
      night_city: {
        name: "Night City Glow",
        description:
          "nighttime city scene with neon lights and illuminated buildings",
        lighting: "neon glow, soft bokeh lights, cinematic night atmosphere",
        atmosphere: "vibrant nightlife energy, urban sophistication",
      },
    };

    // Use selected style or default to beach
    const targetScene = sceneConfigs[selectedStyle] || sceneConfigs.beach;
    const generatedImages = [];

    // Initialize Gemini AI client
    const ai = new GoogleGenAI({
      apiKey: geminiApiKey,
    });

    // Build casual Instagram-style photo prompt
    const stylePrompt = `Create a casual, natural Instagram photo using the person in the input image.
This should look like a candid moment someone captured on their phone - NOT a professional photoshoot.

Scene: ${targetScene.name}
Environment: ${targetScene.description}

Style Guidelines:
- Make it look like a spontaneous, real-life moment (not posed or staged)
- Use phone camera quality - slightly imperfect, authentic feel
- The person should blend seamlessly into the scene (NO cut-out edges or pasted look)
- Lighting: ${targetScene.lighting} - but keep it natural and casual, not studio-perfect
- Add realistic shadows, reflections, and natural depth
- Atmosphere: ${targetScene.atmosphere}
- Keep the person fully recognizable (face, body, clothing unchanged)
- Make it feel like something you'd scroll past on Instagram - casual, relatable, authentic
- NO bokeh or excessive blur. Keep the background relatively clear like a phone photo.
- NO studio lighting. Use natural, slightly imperfect lighting.

Think: "Friend took this photo of me during a trip" NOT "Professional photographer session"

Output:
A casual, Instagram-worthy photo that looks like it was taken in the moment with a phone.
Natural, authentic, and effortlessly cool - not overly polished or staged.`;

    console.log(
      `Generating social media photo with style: ${targetScene.name}...`
    );

    try {
      // Use Gemini 2.5 Flash Image model with streaming
      const config = {
        responseModalities: ["IMAGE", "TEXT"],
        imageConfig: {
          imageSize: "1K",
        },
      };

      const model = "gemini-3-pro-image-preview";
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
        if (
          !chunk.candidates ||
          !chunk.candidates[0].content ||
          !chunk.candidates[0].content.parts
        ) {
          continue;
        }

        // Extract image data from chunk
        if (chunk.candidates?.[0]?.content?.parts?.[0]?.inlineData) {
          const inlineData = chunk.candidates[0].content.parts[0].inlineData;
          const mimeType = inlineData.mimeType || "image/png";
          const imageData = inlineData.data;

          if (imageData) {
            const styleName = targetScene.name;

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

              console.log(
                `Generated and uploaded image ${imageIndex + 1}: ${styleName}`
              );
            } catch (uploadError) {
              console.error(
                `Error uploading image ${imageIndex + 1}:`,
                uploadError.message
              );
              // Skip this image if upload fails
            }

            imageIndex++;
          }
        }
      }
    } catch (error) {
      console.error(
        "Error generating images with Gemini 2.5 Flash Image:",
        error.message
      );
      throw error;
    }

    if (generatedImages.length === 0) {
      throw new Error(
        "Failed to generate any images. Please check Gemini API configuration."
      );
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
