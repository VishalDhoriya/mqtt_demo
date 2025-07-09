# MQTT Demo App

A Flutter application that demonstrates MQTT broker and client functionality, allowing devices to communicate with each other via MQTT protocol.

## Features

- **MQTT Broker Mode**: Turn your device into an MQTT broker that other devices can connect to
- **MQTT Client Mode**: Connect to an MQTT broker and publish/subscribe to topics
- **Automatic Broker Discovery**: Find available MQTT brokers on your network automatically
- **Manual Broker Entry**: Add brokers manually when auto-discovery doesn't find them
- **Real-time Messaging**: Send and receive messages instantly between devices
- **Topics Management**: Browse and manage MQTT topics in dedicated rooms
- **Visual Status Indicators**: Clear visual feedback for connection and subscription status
- **Message Logging**: View all MQTT activities in real-time
- **Modular Architecture**: Clean separation of concerns with dedicated services and widgets

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
4. **Find the Broker**: Either:
   - **Auto-Discovery**: Tap the search icon (🔍) next to the broker IP field to automatically discover brokers on your network
   - **Manual Entry**: Enter the IP address from Device A directly in the broker IP field
5. **Connect**: If using auto-discovery, tap a discovered broker to connect. If using manual entry, enter the IP and tap "Connect"
6. **Subscribe**: Once connected, tap "Subscribe" to subscribe to the default topic `test/topic`
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

## Topics Feature

The app includes a comprehensive topics management system that allows users to organize and view MQTT messages by topic.

### Key Features
1. **Topic Discovery**: Automatically discovers all MQTT topics from message activity
2. **Topic Rooms**: Dedicated chat-like interface for each topic
3. **Message History**: View all messages published to a specific topic
4. **Subscription Management**: Subscribe/unsubscribe to topics directly from topic rooms
5. **Real-time Updates**: Live updates when new messages arrive

### How to Use
1. **Access Topics**: Tap the "Topics" tab in the bottom navigation
2. **Browse Topics**: See all discovered topics with message counts and subscription status
3. **Enter Topic Room**: Tap any topic to view its dedicated message room
4. **Send Messages**: Publish new messages directly to the topic
5. **Manage Subscriptions**: Toggle subscription status for real-time updates

For detailed information about the topics feature, see [TOPICS_FEATURE_GUIDE.md](TOPICS_FEATURE_GUIDE.md).

## Broker Discovery Feature

The app includes an automatic broker discovery feature that makes it easy to find and connect to MQTT brokers on your network.

### How It Works
1. **Network Scanning**: Automatically scans your local network for devices running MQTT brokers
2. **Port Detection**: Checks common MQTT ports (1883, 8883, 9001, 8080) on all network devices
3. **Visual Interface**: Shows discovered brokers in a user-friendly list
4. **One-Tap Connect**: Simply tap any discovered broker to connect immediately

### Using Broker Discovery
1. **Open Discovery**: In client mode, tap the search icon (🔍) next to the broker IP field
2. **Wait for Scan**: The app will automatically scan your network (takes up to 5 seconds)
3. **Select Broker**: Tap any discovered broker from the list to connect
4. **Manual Fallback**: If your broker isn't found, use the "Manual Entry" section to add it

### Manual Entry Options
- **Add to List**: Save manual entries for easy reuse
- **Connect Now**: Connect immediately to a manually entered broker
- **Remove Entries**: Delete manual entries you no longer need

For detailed information about the broker discovery feature, see [BROKER_DISCOVERY.md](BROKER_DISCOVERY.md).

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
├── main.dart                              # App entry point
├── services/
│   ├── mqtt_service.dart                  # MQTT broker and client logic
│   ├── network_helper.dart                # Network interface detection
│   └── broker_discovery_service.dart      # Broker discovery functionality
├── screens/
│   ├── mqtt_demo_screen.dart              # Main screen logic
│   └── broker_discovery_screen.dart       # Broker discovery screen
├── widgets/
│   ├── device_ip_display.dart             # Device IP display widget
│   ├── mode_selection.dart                # Mode selection widget
│   ├── status_cards.dart                  # Status cards widget
│   ├── broker_section.dart                # Broker controls widget
│   ├── client_section.dart                # Client controls widget
│   ├── message_log.dart                   # Message log widget
│   └── broker_selection_widget.dart       # Broker selection widget
└── test/
    └── widget_test.dart                   # Widget tests
```

### Key Classes
- `MqttService`: Handles all MQTT operations (broker and client)
- `BrokerDiscoveryService`: Network scanning and broker discovery
- `NetworkHelper`: Network interface detection and IP resolution
- `MqttDemoScreen`: Main screen with controls and message display
- `BrokerDiscoveryScreen`: Broker discovery and selection interface

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
