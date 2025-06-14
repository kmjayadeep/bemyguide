import type { RateLimitData } from "../types";

// Rate limit configuration
export const RATE_LIMIT = {
  MAX_REQUESTS: 30,
  WINDOW_MINUTES: 60,
};

export class RateLimiterService {
  static async checkRateLimit(
    deviceId: string, 
    kvStore: KVNamespace
  ): Promise<{ allowed: boolean; remaining: number; resetAt: number; retryAfter?: number }> {
    const key = `rate_limit:${deviceId}`;
    const now = Date.now();
    const windowMs = RATE_LIMIT.WINDOW_MINUTES * 60 * 1000;
    const resetAt = now + windowMs;
    
    // Get current rate limit data from KV
    const storedData = await kvStore.get(key, 'json') as RateLimitData | null;
    
    if (storedData) {
      // Check if the window has expired
      if (now > storedData.resetAt) {
        // Reset counter for new window
        await kvStore.put(key, JSON.stringify({
          count: 1,
          resetAt: resetAt
        }), { expirationTtl: RATE_LIMIT.WINDOW_MINUTES * 60 });
        
        return {
          allowed: true,
          remaining: RATE_LIMIT.MAX_REQUESTS - 1,
          resetAt: resetAt
        };
      } else {
        // Window still active
        if (storedData.count >= RATE_LIMIT.MAX_REQUESTS) {
          // Rate limit exceeded
          const retryAfterSeconds = Math.ceil((storedData.resetAt - now) / 1000);
          return {
            allowed: false,
            remaining: 0,
            resetAt: storedData.resetAt,
            retryAfter: retryAfterSeconds
          };
        }
        
        // Increment counter
        await kvStore.put(key, JSON.stringify({
          count: storedData.count + 1,
          resetAt: storedData.resetAt
        }), { expirationTtl: Math.ceil((storedData.resetAt - now) / 1000) });
        
        return {
          allowed: true,
          remaining: Math.max(0, RATE_LIMIT.MAX_REQUESTS - storedData.count - 1),
          resetAt: storedData.resetAt
        };
      }
    } else {
      // First request in this window
      await kvStore.put(key, JSON.stringify({
        count: 1,
        resetAt: resetAt
      }), { expirationTtl: RATE_LIMIT.WINDOW_MINUTES * 60 });
      
      return {
        allowed: true,
        remaining: RATE_LIMIT.MAX_REQUESTS - 1,
        resetAt: resetAt
      };
    }
  }
} 