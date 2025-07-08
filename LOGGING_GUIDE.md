# MQTT Demo Logging Guide

## Overview
The MQTT Demo app now includes comprehensive logging to help you debug and monitor the MQTT functionality. All log messages are printed to the terminal/console when running in debug mode.

## Log Message Format
```
[HH:MM:SS] CATEGORY: MESSAGE
```

## Log Categories

### 🎬 UI Logs
**Prefix:** `[timestamp] UI:`
- Track user interactions and UI state changes
- Help debug UI-related issues

**Example Messages:**
```
[14:30:15] UI: 🎬 Initializing MQTT Demo App
[14:30:16] UI: 🌐 Getting device IP address...
[14:30:17] UI: ✅ Device IP detected: 192.168.1.105
[14:30:20] UI: 🚀 User requested to start MQTT broker
[14:30:25] UI: 🔌 User requested to connect to broker: 192.168.1.100
```

### 🔧 MQTT Service Logs
**Prefix:** `[timestamp] MQTT:`
- Track MQTT operations (broker, client, messaging)
- Most detailed logging for MQTT functionality

**Example Messages:**
```
[14:30:21] MQTT: 🚀 Starting MQTT broker...
[14:30:21] MQTT: ⚙️  Creating broker configuration (port: 1883, anonymous: true)
[14:30:22] MQTT: ✅ MQTT Broker started successfully on port 1883
[14:30:25] MQTT: 🔌 Attempting to connect to MQTT broker...
[14:30:25] MQTT: 📍 Broker IP: 192.168.1.100
[14:30:26] MQTT: ✅ Connected to MQTT broker at 192.168.1.100
```

### 🌐 Network Logs
**Prefix:** `[timestamp] NETWORK:`
- Track network interface detection and IP validation
- Help debug network-related issues

**Example Messages:**
```
[14:30:16] NETWORK: 🔍 Starting device IP address detection
[14:30:16] NETWORK: 📡 Fetching network interfaces
[14:30:16] NETWORK: 📊 Found 3 network interfaces
[14:30:16] NETWORK: ✅ Wi-Fi IPv4 address found: 192.168.1.105
[14:30:25] NETWORK: ✅ Validating IP address: 192.168.1.100
```

## Common Log Sequences

### 1. Starting MQTT Broker
```
[14:30:20] UI: 🚀 User requested to start MQTT broker
[14:30:21] MQTT: 🚀 Starting MQTT broker...
[14:30:21] MQTT: ⚙️  Creating broker configuration (port: 1883, anonymous: true)
[14:30:21] MQTT: 🔧 Creating broker instance
[14:30:21] MQTT: 🎯 Starting broker on port 1883...
[14:30:22] MQTT: ✅ MQTT Broker started successfully on port 1883
[14:30:22] MQTT: 📡 Broker is ready to accept client connections
[14:30:22] UI: ✅ Broker started successfully - showing success message
```

### 2. Connecting MQTT Client
```
[14:30:25] UI: 🔌 User requested to connect to broker: 192.168.1.100
[14:30:25] NETWORK: ✅ Validating IP address: 192.168.1.100
[14:30:25] NETWORK: 📊 IP validation result: true
[14:30:25] UI: ✅ IP validation passed - attempting connection
[14:30:25] MQTT: 🔌 Attempting to connect to MQTT broker...
[14:30:25] MQTT: 📍 Broker IP: 192.168.1.100
[14:30:25] MQTT: 👤 Client ID: flutter_client_1704558625000
[14:30:25] MQTT: 🔧 Creating MQTT client instance
[14:30:25] MQTT: ⚙️  Configuring client settings
[14:30:25] MQTT: 📝 Creating connection message
[14:30:25] MQTT: 🚀 Connecting to broker...
[14:30:26] MQTT: ✅ Connected to MQTT broker at 192.168.1.100
[14:30:26] MQTT: 🔗 Connection status: connected
[14:30:26] MQTT: 👂 Setting up message listener
[14:30:26] MQTT: 🔗 Client connected successfully
[14:30:26] UI: ✅ Connection successful - showing success message
```

### 3. Subscribing to Topic
```
[14:30:30] UI: 📡 User requested to subscribe to topic
[14:30:30] MQTT: 📡 Attempting to subscribe to topic: test/topic
[14:30:30] MQTT: ✅ Client is connected, proceeding with subscription
[14:30:30] MQTT: 🎯 Subscribing to topic: test/topic with QoS: atMostOnce
[14:30:30] MQTT: 📬 Subscription request sent
[14:30:30] MQTT: 📬 Successfully subscribed to topic: test/topic
[14:30:30] MQTT: 🎯 Subscription status: true
[14:30:30] MQTT: 👂 Now listening for messages on topic: test/topic
```

### 4. Publishing Message
```
[14:30:35] UI: 📤 User requested to publish message: "Hello, MQTT!"
[14:30:35] MQTT: 📤 Publishing message...
[14:30:35] MQTT: 📍 Topic: test/topic
[14:30:35] MQTT: 📝 Message: "Hello, MQTT!"
[14:30:35] MQTT: 🎯 QoS: atMostOnce
[14:30:35] MQTT: ✅ Client is connected, proceeding with publish
[14:30:35] MQTT: 📦 Payload created (12 bytes)
[14:30:35] MQTT: 🚀 Message published successfully
[14:30:35] MQTT: 📨 Received message: "Hello, MQTT!" from topic: test/topic
```

## Error Indicators

### ❌ Connection Errors
```
[14:30:25] MQTT: ❌ Connection error: SocketException: Connection refused
[14:30:25] MQTT: 🔍 Error type: SocketException
[14:30:25] UI: ❌ Connection failed - showing error message
```

### ⚠️ Validation Warnings
```
[14:30:25] NETWORK: ⚠️  Invalid IP format detected
[14:30:25] UI: ⚠️  Invalid IP format - showing error message
```

### 🔍 Debug Information
```
[14:30:25] MQTT: 🔍 Client exists: true
[14:30:25] MQTT: 🔍 Is connected: false
[14:30:25] MQTT: 🔍 Return code: connectionAccepted
```

## How to View Logs

### Using Flutter Run
```bash
cd "c:\Users\Vishal\Desktop\flutter selc\mqtt_demo"
flutter run --debug
```

### Using VS Code
1. Open project in VS Code
2. Press F5 or use "Run > Start Debugging"
3. Logs will appear in the Debug Console

### Using Android Studio
1. Open project in Android Studio
2. Run the app in debug mode
3. Logs will appear in the Logcat window

## Troubleshooting with Logs

### Broker Won't Start
Look for these patterns:
```
❌ Failed to start broker: [error details]
```
**Common causes:** Port already in use, permission issues

### Client Won't Connect
Look for these patterns:
```
❌ Connection error: [error details]
❌ Connection failed - Status: [status]
```
**Common causes:** Wrong IP address, broker not running, network issues

### Messages Not Received
Look for these patterns:
```
❌ Cannot subscribe - client not connected
❌ Cannot publish - client not connected
```
**Common causes:** Not connected to broker, not subscribed to topic

### IP Address Issues
Look for these patterns:
```
⚠️  Could not detect device IP address
⚠️  Invalid IP format detected
```
**Common causes:** Not connected to Wi-Fi, firewall blocking detection

## Log Levels

### 🎯 Success Messages
- ✅ Operations completed successfully
- 📊 Status information
- 🔗 Connection established

### ⚠️ Warning Messages
- IP validation issues
- Client state warnings
- Network detection issues

### ❌ Error Messages
- Connection failures
- Broker start/stop errors
- Message publish/subscribe failures

### 🔍 Debug Messages
- Detailed state information
- Error type information
- Connection status details

## Tips for Effective Debugging

1. **Follow the timestamps** - They help track the sequence of events
2. **Look for emoji patterns** - They quickly identify success/failure states
3. **Check network logs first** - Many issues stem from network problems
4. **Verify client state** - Ensure client is connected before operations
5. **Monitor both devices** - Compare logs between broker and client devices
