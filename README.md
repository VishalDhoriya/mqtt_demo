# MQTT Demo App

A Flutter application that demonstrates MQTT broker and client functionality, allowing devices to communicate with each other via MQTT protocol.

## Features

- **MQTT Broker Mode**: Turn your device into an MQTT broker that other devices can connect to
- **MQTT Client Mode**: Connect to an MQTT broker and publish/subscribe to topics
- **Real-time Messaging**: Send and receive messages instantly between devices
- **Visual Status Indicators**: Clear visual feedback for connection and subscription status
- **Message Logging**: View all MQTT activities in real-time

## Architecture

The app uses two main packages:
- `mqtt_server`: For creating an MQTT broker
- `mqtt_client`: For MQTT client functionality

## Installation

1. Clone or download this project
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Build and run the app: `flutter run`

## Usage Instructions

### Setting Up Device A as MQTT Broker

1. **Run the app** on Device A
2. **Note the IP address** displayed at the top of the screen (this device's IP)
3. **Tap "Become MQTT Broker"** to switch to broker mode
4. **Tap "Start Broker"** - the status should change to "Broker is RUNNING"
5. **Share the IP address** from the top display with client devices

### Setting Up Device B as MQTT Client

1. **Run the app** on Device B
2. **Note this device's IP** displayed at the top (for reference)
3. **Tap "Become MQTT Client"** to switch to client mode
4. **Enter the Broker IP Address**: Input the IP address from Device A (shown at the top of Device A's screen)
5. **Tap "Connect"** - the button should change to "Disconnect" if successful
6. **Tap "Subscribe"** to subscribe to the default topic `test/topic`
   - You should see a "Subscribed..." message appear in the log

### Testing Message Publishing

1. **On Device B**, tap the **"Publish Message"** button
2. **You should instantly see** the message "Received message: 'Hello, MQTT!' from topic: test/topic" appear in the log on Device B
3. This confirms the message loop is working (Device B is both publishing and subscribed to the same topic)

### Testing with Multiple Clients (Recommended)

1. **Start the broker** on Device A
2. **Connect both Device B and Device C** as clients to Device A's IP address
3. **Have both B and C subscribe** to `test/topic`
4. **When Device B publishes a message**, both Device B and Device C should receive it
5. **When Device C publishes a message**, both Device B and Device C should receive it
6. This proves the broker is correctly relaying messages between clients

## App Interface

### Device IP Display (Top of Screen)
- **IP Address Card**: Shows the current device's IP address prominently
- **Refresh Button**: Allows manual refresh of IP detection
- **Usage Note**: Provides context for broker/client setup

### Mode Selection
- **Become MQTT Broker**: Switches the app to broker mode
- **Become MQTT Client**: Switches the app to client mode

### Broker Mode
- **Status Card**: Shows whether the broker is running or stopped
- **Start/Stop Broker**: Controls the MQTT broker
- **IP Address Note**: Reminds you to check your device's IP address

### Client Mode
- **Connection Status**: Shows if connected to broker
- **Subscription Status**: Shows if subscribed to topics
- **Broker IP Field**: Enter the broker's IP address
- **Connect/Disconnect**: Manages broker connection
- **Subscribe/Unsubscribe**: Manages topic subscriptions
- **Message Field**: Enter custom messages to publish
- **Publish Message**: Sends messages to subscribed topics

### Message Log
- **Real-time Display**: Shows all MQTT activities with timestamps
- **Auto-scroll**: Automatically scrolls to show newest messages
- **Clear Button**: Clears the message log

## Technical Details

### Default Configuration
- **MQTT Port**: 1883 (standard MQTT port)
- **Default Topic**: `test/topic`
- **QoS Level**: 0 (At most once)
- **Client ID**: Auto-generated unique ID per device

### Network Requirements
- All devices must be on the same Wi-Fi network
- Ensure your network allows device-to-device communication
- Some enterprise networks may block MQTT traffic

## Troubleshooting

### Connection Issues
- **Verify IP Address**: Ensure the broker IP is correct
- **Check Network**: Confirm all devices are on the same Wi-Fi network
- **Firewall**: Some networks may block MQTT traffic on port 1883
- **Restart Broker**: Try stopping and starting the broker

### Message Issues
- **Subscribe First**: Ensure clients are subscribed before publishing
- **Check Topic**: Verify all clients are using the same topic name
- **QoS Settings**: Check if QoS levels are compatible

### Performance Tips
- **Limit Message Frequency**: Avoid sending messages too rapidly
- **Monitor Battery**: MQTT broker mode may consume more battery
- **Network Stability**: Ensure stable Wi-Fi connection for best performance

## Code Structure

```
lib/
├── main.dart           # Main UI and app entry point
├── mqtt_service.dart   # MQTT broker and client logic
└── pubspec.yaml       # Dependencies and project configuration
```

### Key Classes
- `MqttService`: Handles all MQTT operations (broker and client)
- `MqttDemo`: Main UI widget with controls and message display
- `AppMode`: Enum for switching between broker and client modes

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  mqtt_server: ^1.0.0    # MQTT broker functionality
  mqtt_client: ^10.10.0  # MQTT client functionality
```

## License

This project is for educational and demonstration purposes.

## Contributing

Feel free to submit issues and enhancement requests!
