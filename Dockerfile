# Use Ubuntu as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Create a non-root user for Flutter
RUN useradd -m -s /bin/bash flutter && \
    usermod -aG sudo flutter && \
    echo 'flutter ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create directories and set permissions (as root)
RUN mkdir -p $ANDROID_HOME $FLUTTER_HOME

# Download and install Android SDK Command Line Tools (as root)
RUN cd /opt && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux-11076708_latest.zip && \
    mkdir -p $ANDROID_HOME/cmdline-tools && \
    mv cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm commandlinetools-linux-11076708_latest.zip

# Download and install Flutter (using newer version with Dart SDK 3.7.2+)
RUN cd /opt && \
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.3-stable.tar.xz && \
    tar xf flutter_linux_3.29.3-stable.tar.xz && \
    rm flutter_linux_3.29.3-stable.tar.xz

# Fix ownership and git configuration
RUN chown -R flutter:flutter $ANDROID_HOME $FLUTTER_HOME && \
    git config --global --add safe.directory $FLUTTER_HOME

# Switch to flutter user for Flutter operations
USER flutter

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses

# Install Android SDK components
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Pre-download Dart SDK and other dependencies
RUN flutter precache

# Configure Flutter
RUN flutter config --android-sdk $ANDROID_HOME
RUN flutter doctor --android-licenses

# Set working directory
WORKDIR /workspace

# Switch back to root for file copying
USER root

# Copy pubspec files first for better caching
COPY app/pubspec.yaml app/pubspec.lock ./

# Change ownership to flutter user
RUN chown -R flutter:flutter /workspace

# Switch to flutter user for pub get
USER flutter

# Install Flutter dependencies
RUN flutter pub get

# Switch back to root for copying remaining files
USER root

# Copy the rest of the application
COPY app/ ./

# Copy build script
COPY build-apk.sh /usr/local/bin/build-apk.sh
RUN chmod +x /usr/local/bin/build-apk.sh

# Set final ownership
RUN chown -R flutter:flutter /workspace

# Switch to flutter user for running
USER flutter

# Default command
CMD ["/usr/local/bin/build-apk.sh"] 