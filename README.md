# cursor_fitchef

A Flutter project for FitChef application.

## Development Setup

### Prerequisites
1. Install [Flutter](https://docs.flutter.dev/get-started/install)
2. Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) (for iOS development)
3. Install [Android Studio](https://developer.android.com/studio) (for Android development)
4. Install [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) (for iOS dependencies):
   ```bash
   sudo gem install cocoapods
   ```

### Getting Started

1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd cursor_fitchef
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Install iOS dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. Setup simulators/emulators:
   - For iOS: Open Xcode, go to Xcode > Open Developer Tool > Simulator
   - For Android: Open Android Studio > Tools > Device Manager > Create Device

5. Run the app:
   ```bash
   # Check available devices
   flutter devices
   
   # Run on specific device
   flutter run -d <device_id>
   ```

### Common Issues and Solutions

- If you encounter CocoaPods issues:
  ```bash
  cd ios
  pod deintegrate
  pod setup
  pod install
  ```

- If Flutter doctor shows issues:
  ```bash
  flutter doctor
  ```
  Follow the recommendations to resolve any issues.

## Additional Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter Documentation](https://docs.flutter.dev/)

## Troubleshooting

If you encounter any issues:
1. Ensure all prerequisites are installed correctly
2. Run `flutter doctor -v` for detailed environment information
3. Check that all environment variables are set correctly
4. For iOS issues, try cleaning the build:
   ```bash
   cd ios
   xcodebuild clean
   cd ..
   flutter clean
   ```
