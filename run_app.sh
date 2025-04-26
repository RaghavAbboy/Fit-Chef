#!/bin/bash

# Script to automate running the Flutter app in iOS, Android, or Web mode

MODE=$1
DEVICE_ID=$2

if [ -z "$MODE" ]; then
  echo "Usage: ./run_app.sh [ios|android|web] [android_device_id (optional)]"
  exit 1
fi

case $MODE in
  ios)
    echo "🚀 Opening iOS Simulator..."
    open -a Simulator
    sleep 5
    echo "🏃‍♂️ Running Flutter app on iOS simulator..."
    flutter run -d ios
    ;;
  android)
    if [ -z "$DEVICE_ID" ]; then
      echo "⚠️  No Android device ID provided. Listing available devices:"
      flutter devices
      echo "Please provide an Android device ID as the second argument."
      echo "Example: ./run_app.sh android emulator-5554"
      exit 1
    fi
    echo "🏃‍♂️ Running Flutter app on Android device $DEVICE_ID..."
    flutter run -d $DEVICE_ID
    ;;
  web)
    echo "🌐 Running Flutter app in Chrome on port 3000..."
    flutter run -d chrome --web-port=3000
    ;;
  *)
    echo "❌ Invalid mode: $MODE"
    echo "Usage: ./run_app.sh [ios|android|web] [android_device_id (optional)]"
    exit 1
    ;;
esac 