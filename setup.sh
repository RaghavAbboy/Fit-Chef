#!/bin/bash

echo "🚀 Setting up FitChef Flutter project..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods is not installed. Installing CocoaPods..."
    sudo gem install cocoapods
fi

echo "📦 Installing Flutter dependencies..."
flutter pub get

echo "📱 Setting up iOS dependencies..."
cd ios
pod install
cd ..

echo "🧹 Cleaning build files..."
flutter clean
flutter pub get

echo "✅ Setup complete! You can now run the app using:"
echo "flutter run" 