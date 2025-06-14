export interface CloudflareBindings {
  JWT_SECRET: string;
  bmg_rate: KVNamespace;
  AI: any; // Cloudflare AI binding
}

export interface LocationQuery {
  query: string;
  latitude: number;
  longitude: number;
}

export interface PlaceRecommendation {
  name: string;
  description: string;
  category: "Restaurant" | "Park" | "Museum" | "Activity" | "Landmark" | "Shopping" | "Other";
  distance_km?: number | null;
  google_maps_url: string;
}

export interface ApiResponse {
  success: boolean;
  data?: PlaceRecommendation[];
  error?: string;
}

export interface RateLimitData {
  count: number;
  resetAt: number;
}

export interface JWTPayload {
  sub: string;
  iat: number;
  exp: number;
} 