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

## 🏗️ Architecture

BeMyGuide uses a secure, serverless architecture with anonymous authentication:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│ Cloudflare      │───▶│  Cloudflare AI  │
│ • Device ID     │    │ Workers API     │    │                 │
│ • JWT Token     │    │ • Rate Limiting │    │                 │
│ • Location      │    │ • Auth & Validation │    │                 │
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
- **Rate Limiting**: 10 requests per 15 minutes per device (configurable)
- **No Exposed Credentials**: AI API keys secured in backend only

### How It Works
1. App generates unique device ID and gets JWT token from backend
2. User queries sent to Cloudflare Workers API with location data
3. Backend validates request, enforces rate limits, and calls Cloudflare AI
4. AI responses processed and returned to app with caching

## 🛠️ Tech Stack

**Frontend**: Flutter, Geolocator, HTTP client, JWT handling  
**Backend**: Cloudflare Workers, Hono framework, Cloudflare AI  
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
wrangler kv:namespace create "RATE_LIMITER"
wrangler kv:namespace create "USER_SESSIONS"
# Update wrangler.toml with your namespace IDs

# Deploy backend
wrangler deploy

# Flutter setup
cd ../app
flutter pub get
# Update API endpoint in lib/services/api_service.dart
flutter run
```

## 🧪 Testing the API

### Test the Backend Locally
```bash
# Start local development server
cd backend
wrangler dev

# Test the API endpoint
curl -X POST http://localhost:8787/api/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Find nearby restaurants that serve vegan food",
    "latitude": 40.7128,
    "longitude": -74.0060
  }'

# Test health check
curl http://localhost:8787/health
```

### Test Deployed Backend
```bash
# Replace YOUR_WORKER_URL with your actual Cloudflare Workers URL
curl -X POST https://YOUR_WORKER_URL.workers.dev/api/recommendations \
  -H "Content-Type: application/json" \
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
      "category": "Restaurant",
      "distance": "0.2 km",
      "website": "https://example.com/cafe",
      "description": "Cozy local cafe with excellent coffee and pastries"
    },
    {
      "name": "Central Park",
      "category": "Park",
      "distance": "0.5 km",
      "description": "Beautiful park perfect for walks and relaxation"
    },
    {
      "name": "Art Museum",
      "category": "Museum",
      "distance": "1.2 km",
      "website": "https://example.com/museum",
      "description": "Contemporary art museum with rotating exhibitions"
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
│   │       ├── auth_service.dart     # Anonymous authentication
│   │       └── location_service.dart # GPS handling
│   └── pubspec.yaml
│
├── backend/                   # Cloudflare Workers backend
│   ├── src/
│   │   ├── index.js          # Main Workers entry point
│   │   ├── auth/             # Authentication middleware
│   │   └── routes/           # API route handlers
│   ├── wrangler.toml         # Workers configuration
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

**Rate Limiting**: 10 requests/15min (configurable in `wrangler.toml`)  
**AI Model**: `@cf/meta/llama-3.1-8b-instruct` (configurable)  
**Deployment**: `wrangler deploy --env production`

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