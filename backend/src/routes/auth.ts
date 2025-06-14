import { Hono } from "hono";
import { AuthService } from "../services/auth";
import type { CloudflareBindings } from "../types";

const auth = new Hono<{ Bindings: CloudflareBindings }>();

// Anonymous Auth endpoint
auth.post("/anonymous", async (c) => {
  try {
    const { deviceId } = await c.req.json();
    if (!deviceId || typeof deviceId !== "string") {
      return c.json({ success: false, error: "deviceId is required" }, 400);
    }
    
    const token = await AuthService.generateToken(deviceId, c.env.JWT_SECRET);
    return c.json({ success: true, token });
  } catch (e) {
    return c.json({ success: false, error: "Invalid request" }, 400);
  }
});

export { auth }; 