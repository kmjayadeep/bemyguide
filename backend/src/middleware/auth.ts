import type { Context, Next } from "hono";
import { AuthService } from "../services/auth";

// JWT Auth middleware
export const jwtAuth = async (c: Context, next: Next) => {
  const auth = c.req.header("Authorization");
  if (!auth || !auth.startsWith("Bearer ")) {
    return c.json({ success: false, error: "Missing or invalid Authorization header" }, 401);
  }
  const token = auth.slice(7);
  try {
    const payload = await AuthService.verifyToken(token, c.env.JWT_SECRET);
    c.set("user", payload);
    await next();
  } catch (e) {
    return c.json({ success: false, error: "Invalid or expired token" }, 401);
  }
}; 