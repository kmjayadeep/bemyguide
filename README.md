# BeMyGuide 🗺️

An AI-powered local guide Flutter app that helps you discover nearby attractions, restaurants, and activities through natural language queries.

## ✨ Features

- **🤖 AI-Powered Recommendations**: Ask questions in natural language and get personalized suggestions
- **📍 Location-Based Search**: Automatically uses your current location or fallback to Interlaken, Switzerland
- **🏷️ Categorized Results**: Places organized by categories (Restaurant, Park, Museum, Activity, Landmark, Shopping)
- **📏 Distance Display**: Shows walking distance to each suggested location
- **🔗 Direct Links**: Visit place websites directly from the app
- **🎨 Modern UI**: Clean Material 3 design with teal theme
- **🔒 Privacy-First**: Location requested only when searching, not on app startup

## 🚀 How It Works

1. **Ask Naturally**: Type questions like "Find nearby restaurants that serve vegan food" or "What attractions are close to me?"
2. **Get Location**: The app requests your location when you search (with fallback options)
3. **AI Processing**: Your query and location are sent to Cloudflare AI for intelligent processing
4. **Personalized Results**: Receive curated suggestions with distances, categories, and descriptions

## 📱 Screenshots

TODO

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **AI Service**: Cloudflare AI API
- **Location**: Geolocator package for GPS functionality
- **Environment**: flutter_dotenv for configuration management

## 🔧 Setup & Installation

### Prerequisites

- Flutter SDK 3.24.0 or later
- Android Studio / VS Code
- Cloudflare AI API access

### 1. Clone the Repository

```bash
git clone https://github.com/kmjayadeep/bemyguide.git
cd bemyguide
```

### 2. Install Dependencies

```bash
cd app
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the `app/` directory:

```env
CLOUDFLARE_AI_URL=https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/run/YOUR_MODEL_NAME
CLOUDFLARE_AI_TOKEN=YOUR_CLOUDFLARE_AI_TOKEN
```

### 4. Set Up Permissions

The app requires location permissions. These are already configured in:
- `android/app/src/main/AndroidManifest.xml` (Android)
- `ios/Runner/Info.plist` (iOS)

### 5. Run the App

```bash
flutter run
```

## 🤖 AI Configuration

This app uses Cloudflare's AI API for generating location-based recommendations. You'll need:

1. A Cloudflare account with AI access
2. Your account ID and API token
3. Access to a suitable language model (e.g., @cf/meta/llama-2-7b-chat-fp16)

## 🏗️ Project Structure

```
app/
├── lib/
│   ├── main.dart              # Main app entry point and UI
│   └── services/
│       ├── ai_service.dart    # Cloudflare AI integration
│       └── location_service.dart # GPS and location handling
├── android/                   # Android-specific files
├── ios/                      # iOS-specific files
├── pubspec.yaml              # Dependencies
└── .env                      # Environment variables (create this)
```

## 🚀 Building for Release

### Android APK

```bash
cd app
flutter build apk --release
```

The APK will be available at `app/build/app/outputs/flutter-apk/app-release.apk`

### Using GitHub Actions

This repository includes a GitHub Actions workflow that automatically builds the APK. See `.github/workflows/build-apk.yml`.

Required GitHub Secrets:
- `CLOUDFLARE_AI_URL`
- `CLOUDFLARE_AI_TOKEN`

## 🌟 Example Queries

Try asking BeMyGuide:

- "Find nearby restaurants that serve vegan food"
- "What attractions are close to Eiffel Tower that I can reach by foot?"
- "Show me fun activities for a family with 10 year old kids"
- "Where can I go shopping for local crafts?"
- "Find parks where I can have a picnic"

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 📞 Contact

**Jayadeep KM**
- GitHub: [@kmjayadeep](https://github.com/kmjayadeep)
- Project Link: [https://github.com/kmjayadeep/bemyguide](https://github.com/kmjayadeep/bemyguide)

---

*Made with ❤️ using Flutter* 