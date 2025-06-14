# BeMyGuide 🗺️

An AI-powered local guide Flutter app that helps you discover nearby attractions, restaurants, and activities through natural language queries.

## ✨ Features

- **🤖 AI-Powered Recommendations**: Ask questions in natural language and get personalized suggestions
- **📍 Location-Based Search**: Uses your current location
- **🏷️ Categorized Results**: Places organized by categories (Restaurant, Park, Museum, Activity, Landmark, Shopping)
- **📏 Distance Display**: Shows walking distance to each suggested location
- **🔗 Direct Links**: Visit place websites directly from the app
- **🎨 Modern UI**: Clean Material 3 design with teal theme
- **🔒 Privacy-First**: Anonymous authentication with device-based identification
- **⚡ Rate Limited**: Smart rate limiting per user to ensure fair usage
- **🛡️ Secure**: Backend-first architecture with no exposed API credentials

## 📱 Screenshots

<div align="center">
  <img src="assets/screenshots/home.jpeg" alt="BeMyGuide Home Screen" width="300"/>
  <img src="assets/screenshots/search.jpeg" alt="Search Results Screen" width="300"/>
</div>

*Left: Welcome screen with search interface and example queries | Right: AI-powered search results with nearby recommendations*

## 🏗️ Architecture

BeMyGuide uses a secure, serverless architecture with anonymous authentication:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│ Cloudflare      │───▶│   Workers AI    │
│ • Device ID     │    │ Workers API     │    │ (Llama 3.1-8B)  │
│ • JWT Token     │    │ • Rate Limiting │    │                 │
│ • Location      │    │ • Auth & AI     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │ Cloudflare KV   │
                       │ • User Sessions │
                       │ • Rate Limits   │
                       └─────────────────┘
```

### Authentication & Security
- **Anonymous Auth**: Zero-friction experience - no signup required
- **Device Identity**: Unique device ID generated on first launch
- **JWT Tokens**: Secure API authentication with automatic refresh
- **Rate Limiting**: 30 requests per 60 minutes per device (configurable)
- **No Exposed Credentials**: AI processing handled entirely in backend

### How It Works
1. App generates unique device ID and gets JWT token from backend
2. User queries sent to Cloudflare Workers API with location data
3. Backend validates request, enforces rate limits, and processes with Workers AI
4. AI responses processed and returned to app with proper formatting

## 🛠️ Tech Stack

**Frontend**: Flutter, Geolocator, HTTP client, JWT handling  
**Backend**: Cloudflare Workers, Hono framework, Workers AI (Llama 3.1-8B)  
**Storage**: Cloudflare KV for sessions and rate limiting  
**Infrastructure**: Global edge deployment with zero cold starts

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.24.0+
- Cloudflare account with Workers and AI access
- Node.js 18+ (for backend)

### Setup
```bash
# Clone repository
git clone https://github.com/kmjayadeep/bemyguide.git
cd bemyguide

# Backend setup
cd backend
npm install
npm install -g wrangler
wrangler login

# Create KV namespaces
wrangler kv:namespace create "bmg-rate-dev"
wrangler kv:namespace create "bmg-rate"
# Update wrangler.jsonc with your namespace IDs in the env.dev and env.production sections

# Deploy backend
wrangler deploy

# Flutter setup
cd ../app
flutter pub get
# Update API endpoint in lib/services/api_service.dart
flutter run
```

## 🧪 Testing the API

### Authentication Flow

All API requests require authentication using a JWT token. The process is:
1. Generate a unique device ID on the client (e.g., UUID).
2. Obtain a JWT by calling the anonymous auth endpoint:

```bash
curl -X POST http://localhost:8787/api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-123"
  }'
```

**Response:**
```json
{
  "success": true,
  "token": "<JWT_TOKEN>"
}
```

3. Use the JWT token in the Authorization header for all protected endpoints:

### Test the Backend Locally
```bash
# Start local development server
cd backend
wrangler dev

# Get a JWT token
TOKEN=$(curl -s -X POST http://localhost:8787/api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test-device-123"}' | jq -r .token)

# Test the API endpoint (replace $TOKEN with the value from above if not using jq)
curl -X POST http://localhost:8787/api/recommendations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "query": "Find nearby restaurants that serve vegan food",
    "latitude": 40.7128,
    "longitude": -74.0060
  }'

# Test health check
curl http://localhost:8787/health
```

### Test Rate Limiting
```bash
# Get a JWT token with a consistent device ID
TOKEN=$(curl -s -X POST http://localhost:8787/api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test-device-123"}' | jq -r .token)

# Make multiple requests in a loop to trigger rate limiting
for i in {1..35}; do
  echo "Request $i:"
  curl -s -X POST http://localhost:8787/api/recommendations \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "query": "Find nearby restaurants",
      "latitude": 40.7128,
      "longitude": -74.0060
    }' | jq '.success, .error, ."X-RateLimit-Remaining"'
  echo ""
  # Small delay between requests
  sleep 1
done
```

After 30 requests, you should see a rate limit error with a 429 status code.

### Test Deployed Backend
```bash
# Replace YOUR_WORKER_URL with your actual Cloudflare Workers URL
TOKEN=$(curl -s -X POST https://YOUR_WORKER_URL.workers.dev/api/auth/anonymous \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test-device-123"}' | jq -r .token)

curl -X POST https://YOUR_WORKER_URL.workers.dev/api/recommendations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "query": "Show me fun activities for families with kids",
    "latitude": 48.8566,
    "longitude": 2.3522
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": [
    {
      "name": "Local Cafe & Bistro",
      "description": "Cozy local cafe with excellent coffee and pastries",
      "category": "Restaurant",
      "distance_km": 0.2,
      "website_url": "https://example.com/cafe",
      "latitude": null,
      "longitude": null
    },
    {
      "name": "Central Park",
      "description": "Beautiful park perfect for walks and relaxation",
      "category": "Park",
      "distance_km": 0.5,
      "website_url": null,
      "latitude": null,
      "longitude": null
    },
    {
      "name": "Art Museum",
      "description": "Contemporary art museum with rotating exhibitions",
      "category": "Museum",
      "distance_km": 1.2,
      "website_url": "https://example.com/museum",
      "latitude": null,
      "longitude": null
    }
  ]
}
```

## 🏗️ Project Structure

```
├── app/                       # Flutter application
│   ├── lib/
│   │   ├── main.dart         # Main app entry point
│   │   └── services/
│   │       ├── api_service.dart      # Backend API integration
│   │       └── location_service.dart # GPS handling
│   └── pubspec.yaml
│
├── backend/                   # Cloudflare Workers backend
│   ├── src/
│   │   ├── index.ts          # Main Workers entry point
│   │   ├── types/
│   │   │   └── index.ts      # TypeScript interfaces and types
│   │   ├── services/
│   │   │   ├── auth.ts       # JWT token generation/validation
│   │   │   ├── aiService.ts  # AI/LLM integration logic
│   │   │   └── rateLimiter.ts # Rate limiting business logic
│   │   ├── middleware/
│   │   │   ├── auth.ts       # JWT authentication middleware
│   │   │   └── rateLimiter.ts # Rate limiting middleware
│   │   └── routes/
│   │       ├── auth.ts       # Authentication endpoints
│   │       └── recommendations.ts # AI recommendations endpoints
│   ├── wrangler.jsonc        # Workers configuration
│   └── package.json
```

## 🔄 Development Roadmap

**Phase 1 (Current)**: Anonymous authentication, rate limiting, secure AI integration  
**Phase 2**: Google OAuth integration, premium tiers, usage analytics  
**Phase 3**: Cross-device sync, personalization, social features

## 🌟 Example Queries

Try asking BeMyGuide:

- "Find nearby restaurants that serve vegan food"
- "What attractions are close to Eiffel Tower that I can reach by foot?"
- "Show me fun activities for a family with 10 year old kids"
- "Where can I go shopping for local crafts?"

## ⚙️ Configuration

**Rate Limiting**: 30 requests/60min (configurable in backend)  
**AI Model**: `workers-ai/@cf/meta/llama-3.1-8b-instruct` (Workers AI)  
**Deployment**: `wrangler deploy --env production`

### Rate Limiting

The app implements device-based rate limiting:

- Each device is limited to 30 requests per 60-minute window
- Rate limits are tracked in Cloudflare KV using the device ID as the key
- When rate limit is exceeded, the API returns a 429 status with a Retry-After header
- Rate limit headers are included in each response:
  - `X-RateLimit-Limit`: Maximum requests allowed in the window
  - `X-RateLimit-Remaining`: Remaining requests in the current window
  - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets

To test rate limiting, make more than 30 requests within 60 minutes using the same device ID.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 📞 Contact

**Jayadeep KM**
- GitHub: [@kmjayadeep](https://github.com/kmjayadeep)
- Project Link: [https://github.com/kmjayadeep/bemyguide](https://github.com/kmjayadeep/bemyguide)

---
*Made with ❤️ using Flutter and Cloudflare Workers*