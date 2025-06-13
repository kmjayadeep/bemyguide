import { Hono } from "hono";
import { cors } from "hono/cors";
import { sign, verify, decode } from "hono/jwt";
import type { Context, Next } from "hono";

interface CloudflareBindings {
  JWT_SECRET: string;
  bmg_rate: KVNamespace;
}

interface LocationQuery {
  query: string;
  latitude: number;
  longitude: number;
}

interface PlaceRecommendation {
  name: string;
  category: "Restaurant" | "Park" | "Museum" | "Activity" | "Landmark" | "Shopping";
  distance: string;
  website?: string;
  description: string;
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
    // TODO: This will be replaced with actual AI processing
    // For now, return mock data to test the API structure
    const mockRecommendations: PlaceRecommendation[] = [
      {
        name: "Local Cafe & Bistro",
        category: "Restaurant",
        distance: "0.2 km",
        website: "https://example.com/cafe",
        description: "Cozy local cafe with excellent coffee and pastries"
      },
      {
        name: "Central Park",
        category: "Park",
        distance: "0.5 km",
        description: "Beautiful park perfect for walks and relaxation"
      },
      {
        name: "Art Museum",
        category: "Museum",
        distance: "1.2 km",
        website: "https://example.com/museum",
        description: "Contemporary art museum with rotating exhibitions"
      }
    ];
    return c.json<ApiResponse>({
      success: true,
      data: mockRecommendations
    });
  } catch (error) {
    console.error("Error processing request:", error);
    return c.json<ApiResponse>({
      success: false,
      error: "Internal server error"
    }, 500);
  }
});

// Health check endpoint
app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

export default app;
