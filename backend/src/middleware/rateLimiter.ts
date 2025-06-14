import type { Context, Next } from "hono";
import { RateLimiterService, RATE_LIMIT } from "../services/rateLimiter";

// Rate limiting middleware
export const rateLimiter = async (c: Context, next: Next) => {
  try {
    const user = c.get('user');
    const deviceId = user.sub;
    
    if (!deviceId) {
      return c.json({ success: false, error: "Invalid user identity" }, 401);
    }
    
    const result = await RateLimiterService.checkRateLimit(deviceId, c.env.bmg_rate);
    
    if (!result.allowed) {
      return c.json({
        success: false,
        error: `Rate limit exceeded. Try again in ${result.retryAfter} seconds.`
      }, 429, {
        'Retry-After': result.retryAfter!.toString()
      });
    }
    
    // Add rate limit headers
    c.header('X-RateLimit-Limit', RATE_LIMIT.MAX_REQUESTS.toString());
    c.header('X-RateLimit-Remaining', result.remaining.toString());
    c.header('X-RateLimit-Reset', Math.ceil(result.resetAt / 1000).toString());
    
    await next();
  } catch (error) {
    console.error("Rate limiting error:", error);
    // Continue even if rate limiting fails (failsafe)
    await next();
  }
}; 