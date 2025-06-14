import { sign, verify } from "hono/jwt";

export class AuthService {
  static async generateToken(deviceId: string, jwtSecret: string): Promise<string> {
    const payload = {
      sub: deviceId,
      iat: Math.floor(Date.now() / 1000),
      // 7 days expiry
      exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60,
    };
    
    return await sign(payload, jwtSecret);
  }

  static async verifyToken(token: string, jwtSecret: string): Promise<any> {
    return await verify(token, jwtSecret);
  }
} 