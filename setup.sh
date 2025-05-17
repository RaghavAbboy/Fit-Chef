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

# Install VS Code extensions
echo "📦 Attempting to install recommended VS Code extensions (Dart, Flutter & Supabase)..."
if command -v code &> /dev/null; then
    code --install-extension Dart-Code.dart-code
    code --install-extension Dart-Code.flutter
    code --install-extension Supabase.vscode-supabase-extension
    echo "✅ VS Code extension installation attempt finished."
else
    echo "⚠️  VS Code 'code' command not found in PATH. Skipping extension installation."
    echo "   To install extensions via script, ensure 'code' is in your PATH."
    echo "   In VS Code, open Command Palette (Cmd+Shift+P) and run 'Shell Command: Install \'code\' command in PATH'"
fi

echo "✅ Setup complete! You can now run the app using:"
echo "flutter run" 