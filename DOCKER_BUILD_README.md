# 🐳 Docker Flutter APK Builder

This Docker setup provides a complete, reproducible environment for building Flutter APKs without needing to install Flutter, Android SDK, or Java on your host machine.

## 📋 Prerequisites

- Docker and Docker Compose installed on your system
- At least 4GB of available disk space for the build environment

## 🚀 Quick Start

### Build APK (One Command)

```bash
# Build the APK using Docker Compose
docker-compose up flutter-builder
```

The built APK will be available in the `build-output/` directory with a timestamp.

### Interactive Development Mode

If you want to run commands interactively or debug the build process:

```bash
# Start the development container
docker-compose up -d flutter-dev

# Connect to the container
docker-compose exec flutter-dev bash

# Inside the container, you can run Flutter commands:
flutter doctor
flutter build apk --release
flutter build apk --debug
```

## 📁 Directory Structure

```
.
├── Dockerfile              # Flutter/Android build environment
├── docker-compose.yml      # Docker Compose configuration
├── build-apk.sh           # APK build script
├── build-output/          # Generated APKs will appear here
└── app/                   # Your Flutter app source code
```

## 🔧 Available Services

### `flutter-builder` 
- **Purpose**: Automated APK building
- **Usage**: `docker-compose up flutter-builder`
- **Output**: Timestamped APK in `build-output/`

### `flutter-dev`
- **Purpose**: Interactive development and debugging
- **Usage**: `docker-compose up -d flutter-dev && docker-compose exec flutter-dev bash`
- **Features**: Full Flutter/Android development environment

## 🛠️ Build Options

### Release APK
```bash
docker-compose run flutter-dev flutter build apk --release
```

### Debug APK
```bash
docker-compose run flutter-dev flutter build apk --debug
```

### Split APKs by ABI
```bash
docker-compose run flutter-dev flutter build apk --split-per-abi
```

### App Bundle for Play Store
```bash
docker-compose run flutter-dev flutter build appbundle
```

## 📊 What's Included

- **Flutter**: Latest stable version (3.24.5)
- **Android SDK**: Platform Tools, API 34, Build Tools 34.0.0
- **Java**: OpenJDK 17
- **Build Tools**: Gradle caching for faster subsequent builds

## 🗂️ Volume Mounts

- `./app` → `/workspace` (Your Flutter source code)
- `./build-output` → `/workspace/output` (Built APKs)
- `gradle-cache` → `/root/.gradle` (Gradle cache for faster builds)
- `flutter-cache` → `/root/.flutter` (Flutter cache)

## 🐛 Troubleshooting

### First Build is Slow
The first build will download Flutter SDK, Android SDK, and dependencies. Subsequent builds will be much faster due to caching.

### Permission Issues
If you encounter permission issues with the output directory:
```bash
sudo chown -R $USER:$USER build-output/
```

### Clean Build
To clean everything and start fresh:
```bash
docker-compose down -v
docker system prune -f
docker-compose up flutter-builder
```

### Check Flutter Doctor
To verify the environment setup:
```bash
docker-compose run flutter-dev flutter doctor -v
```

## 📋 Build Output

Successful builds will create:
- `build-output/bemyguide_YYYYMMDD_HHMMSS.apk` - Timestamped release APK
- Console output showing build status and APK size

## 🔄 Updating

To update Flutter or Android SDK versions, modify the Dockerfile and rebuild:
```bash
docker-compose build --no-cache
```

## 💡 Tips

1. **Faster Builds**: Keep the Docker volumes to cache Gradle and Flutter dependencies
2. **Parallel Builds**: You can run multiple build commands simultaneously
3. **Debugging**: Use the `flutter-dev` service for interactive debugging
4. **Clean Builds**: Run `flutter clean` inside the container if builds behave unexpectedly 