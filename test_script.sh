#!/bin/bash

# MQTT Demo Test Script
echo "🧪 MQTT Demo Test Script"
echo "========================"

echo "📱 Building Flutter app..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 You can now install the APK on your devices:"
    echo "   - Location: build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "📋 Testing Instructions:"
    echo "   1. Install APK on Device A (Broker)"
    echo "   2. Install APK on Device B (Client)"
    echo "   3. Optional: Install APK on Device C (Additional Client)"
    echo ""
    echo "🔧 Device A Setup (Broker):"
    echo "   - Tap 'Become MQTT Broker'"
    echo "   - Tap 'Start Broker'"
    echo "   - Note the IP address displayed"
    echo ""
    echo "🔧 Device B Setup (Client):"
    echo "   - Tap 'Become MQTT Client'"
    echo "   - Enter Device A's IP address"
    echo "   - Tap 'Connect'"
    echo "   - Tap 'Subscribe'"
    echo "   - Tap 'Publish Message'"
    echo ""
    echo "👀 What to watch for in terminal/logs:"
    echo "   - Look for messages starting with [timestamp] MQTT:"
    echo "   - Look for messages starting with [timestamp] UI:"
    echo "   - Look for messages starting with [timestamp] NETWORK:"
    echo "   - Look for [BROKER] messages showing received messages on broker side"
    echo ""
    echo "🐛 If you encounter issues:"
    echo "   - Check that both devices are on the same Wi-Fi network"
    echo "   - Verify the IP address is correct"
    echo "   - Look for error messages in the console"
    echo "   - Try restarting the broker if connection fails"
    echo ""
else
    echo "❌ Build failed! Check the errors above."
fi
