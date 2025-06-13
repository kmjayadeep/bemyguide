import { Hono } from "hono";
import { cors } from "hono/cors";
import { sign, verify, decode } from "hono/jwt";
import type { Context, Next } from "hono";

interface CloudflareBindings {
  JWT_SECRET: string;
  bmg_rate: KVNamespace;
  AI: any; // Cloudflare AI binding
}

interface LocationQuery {
  query: string;
  latitude: number;
  longitude: number;
}

interface PlaceRecommendation {
  name: string;
  description: string;
  category: "Restaurant" | "Park" | "Museum" | "Activity" | "Landmark" | "Shopping" | "Other";
  distance_km?: number | null;
  website_url?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}

interface ApiResponse {
  success: boolean;
  data?: PlaceRecommendation[];
  error?: string;
}

interface RateLimitData {
  count: number;
  resetAt: number;
}

// Rate limit configuration
const RATE_LIMIT = {
  MAX_REQUESTS: 30,
  WINDOW_MINUTES: 60,
};

const app = new Hono<{ Bindings: CloudflareBindings }>();

// Enable CORS for Flutter app
app.use("/*", cors({
  origin: "*",
  allowHeaders: ["Content-Type", "Authorization"],
  allowMethods: ["POST", "GET", "OPTIONS"],
}));

// Anonymous Auth endpoint
app.post("/api/auth/anonymous", async (c) => {
  try {
    const { deviceId } = await c.req.json();
    if (!deviceId || typeof deviceId !== "string") {
      return c.json({ success: false, error: "deviceId is required" }, 400);
    }
    const payload = {
      sub: deviceId,
      iat: Math.floor(Date.now() / 1000),
      // 7 days expiry
      exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
    };
    const token = await sign(payload, c.env.JWT_SECRET);
    return c.json({ success: true, token });
  } catch (e) {
    return c.json({ success: false, error: "Invalid request" }, 400);
  }
});

// JWT Auth middleware
const jwtAuth = async (c: Context, next: Next) => {
  const auth = c.req.header("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return c.json({ success: false, error: "Missing or invalid Authorization header" }, 401);
  }
  const token = auth.slice(7);
  try {
    const payload = await verify(token, c.env.JWT_SECRET);
    c.set("user", payload);
    await next();
  } catch (e) {
    return c.json({ success: false, error: "Invalid or expired token" }, 401);
  }
};

// Rate limiting middleware
const rateLimiter = async (c: Context, next: Next) => {
  try {
    const user = c.get('user');
    const deviceId = user.sub;
    
    if (!deviceId) {
      return c.json({ success: false, error: "Invalid user identity" }, 401);
    }
    
    const key = `rate_limit:${deviceId}`;
    const now = Date.now();
    const windowMs = RATE_LIMIT.WINDOW_MINUTES * 60 * 1000;
    const resetAt = now + windowMs;
    
    // Get current rate limit data from KV
    const storedData = await c.env.bmg_rate.get(key, 'json') as RateLimitData | null;
    
    if (storedData) {
      // Check if the window has expired
      if (now > storedData.resetAt) {
        // Reset counter for new window
        await c.env.bmg_rate.put(key, JSON.stringify({
          count: 1,
          resetAt: resetAt
        }), { expirationTtl: RATE_LIMIT.WINDOW_MINUTES * 60 });
      } else {
        // Window still active
        if (storedData.count >= RATE_LIMIT.MAX_REQUESTS) {
          // Rate limit exceeded
          const retryAfterSeconds = Math.ceil((storedData.resetAt - now) / 1000);
          return c.json({
            success: false,
            error: `Rate limit exceeded. Try again in ${retryAfterSeconds} seconds.`
          }, 429, {
            'Retry-After': retryAfterSeconds.toString()
          });
        }
        
        // Increment counter
        await c.env.bmg_rate.put(key, JSON.stringify({
          count: storedData.count + 1,
          resetAt: storedData.resetAt
        }), { expirationTtl: Math.ceil((storedData.resetAt - now) / 1000) });
      }
    } else {
      // First request in this window
      await c.env.bmg_rate.put(key, JSON.stringify({
        count: 1,
        resetAt: resetAt
      }), { expirationTtl: RATE_LIMIT.WINDOW_MINUTES * 60 });
    }
    
    // Add rate limit headers
    const remaining = storedData ? 
      Math.max(0, RATE_LIMIT.MAX_REQUESTS - storedData.count) : 
      RATE_LIMIT.MAX_REQUESTS - 1;
    
    c.header('X-RateLimit-Limit', RATE_LIMIT.MAX_REQUESTS.toString());
    c.header('X-RateLimit-Remaining', remaining.toString());
    c.header('X-RateLimit-Reset', Math.ceil((storedData?.resetAt || resetAt) / 1000).toString());
    
    await next();
  } catch (error) {
    console.error("Rate limiting error:", error);
    // Continue even if rate limiting fails (failsafe)
    await next();
  }
};

// Main API endpoint for location-based recommendations (protected)
app.post("/api/recommendations", jwtAuth, rateLimiter, async (c) => {
  try {
    const body = await c.req.json() as LocationQuery;
    
    // Validate request body
    if (!body.query || typeof body.query !== 'string') {
      return c.json<ApiResponse>({
        success: false,
        error: "Query is required and must be a string"
      }, 400);
    }
    
    if (typeof body.latitude !== 'number' || typeof body.longitude !== 'number') {
      return c.json<ApiResponse>({
        success: false,
        error: "Valid latitude and longitude are required"
      }, 400);
    }
    
    if (body.latitude < -90 || body.latitude > 90) {
      return c.json<ApiResponse>({
        success: false,
        error: "Latitude must be between -90 and 90"
      }, 400);
    }
    
    if (body.longitude < -180 || body.longitude > 180) {
      return c.json<ApiResponse>({
        success: false,
        error: "Longitude must be between -180 and 180"
      }, 400);
    }

    // Use AI to generate recommendations
    const aiResponse = await c.env.AI.run(
      '@cf/meta/llama-3.1-8b-instruct',
      {
        messages: [
          {
            role: 'system',
            content: 'You are a local guide assistant named \'bemyguide\'. Your task is to find relevant places for the user based on their query and location. ALWAYS respond with a valid JSON object containing a single key \'suggestions\' which is an array of places. Each place must have the following keys: \'name\', \'description\', \'category\', \'distance_km\', \'website_url\', \'latitude\', and \'longitude\'. The \'description\' should be a concise, one-sentence summary. The \'distance_km\' should be the approximate distance in kilometers from the user\'s location to the suggested place. If you cannot find a website, set \'website_url\' to null. If you cannot find the exact coordinates, set \'latitude\' and \'longitude\' to null. The \'category\' should be one of: \'Park\', \'Restaurant\', \'Museum\', \'Activity\', \'Landmark\', \'Shopping\', \'Other\'. Do not include any text outside of the JSON object.'
          },
          {
            role: 'user',
            content: `User query: '${body.query}'. My current location is latitude ${body.latitude} and longitude ${body.longitude}.`
          }
        ],
        max_tokens: 800,
        temperature: 0.3
      }
    );

    // Parse the AI response
    let aiResponseText = '';
    if (aiResponse.response) {
      aiResponseText = aiResponse.response;
    } else if (aiResponse.choices && aiResponse.choices.length > 0) {
      aiResponseText = aiResponse.choices[0].message.content;
    } else {
      throw new Error('Unexpected AI response format');
    }

    // Parse the JSON response from AI
    const jsonResponse = JSON.parse(aiResponseText);
    if (!jsonResponse.suggestions || !Array.isArray(jsonResponse.suggestions)) {
      throw new Error('AI response does not contain valid suggestions array');
    }

    const suggestions: PlaceRecommendation[] = jsonResponse.suggestions.map((place: any) => ({
      name: place.name || '',
      description: place.description || '',
      category: place.category || 'Other',
      distance_km: typeof place.distance_km === 'number' ? place.distance_km : null,
      website_url: place.website_url || null,
      latitude: typeof place.latitude === 'number' ? place.latitude : null,
      longitude: typeof place.longitude === 'number' ? place.longitude : null
    }));

    return c.json<ApiResponse>({
      success: true,
      data: suggestions
    });

  } catch (error) {
    console.error("Error processing request:", error);
    return c.json<ApiResponse>({
      success: false,
      error: "Failed to process your request. Please try again."
    }, 500);
  }
});

// Health check endpoint
app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

export default app;
