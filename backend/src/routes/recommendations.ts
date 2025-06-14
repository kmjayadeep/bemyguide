import { Hono } from "hono";
import { jwtAuth } from "../middleware/auth";
import { rateLimiter } from "../middleware/rateLimiter";
import { AIService } from "../services/aiService";
import type { CloudflareBindings, LocationQuery, ApiResponse } from "../types";

const recommendations = new Hono<{ Bindings: CloudflareBindings }>();

// Main API endpoint for location-based recommendations (protected)
recommendations.post("/", jwtAuth, rateLimiter, async (c) => {
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

    const suggestions = await AIService.getRecommendations(body, c.env.AI);

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

export { recommendations }; 