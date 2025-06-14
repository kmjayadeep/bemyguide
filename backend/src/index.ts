import { Hono } from "hono";
import { cors } from "hono/cors";
import type { CloudflareBindings } from "./types";
import { auth } from "./routes/auth";
import { recommendations } from "./routes/recommendations";

const app = new Hono<{ Bindings: CloudflareBindings }>();

// Enable CORS for Flutter app
app.use("/*", cors({
  origin: "*",
  allowHeaders: ["Content-Type", "Authorization"],
  allowMethods: ["POST", "GET", "OPTIONS"],
}));

// Mount routes
app.route("/api/auth", auth);
app.route("/api/recommendations", recommendations);

// Health check endpoint
app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

export default app;
