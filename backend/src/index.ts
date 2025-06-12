import { Hono } from "hono";
import { cors } from "hono/cors";
import { sign, verify, decode } from "hono/jwt";
import type { Context, Next } from "hono";

interface CloudflareBindings {
  JWT_SECRET: string;
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

// Main API endpoint for location-based recommendations (protected)
app.post("/api/recommendations", jwtAuth, async (c) => {
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
