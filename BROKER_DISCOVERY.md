# Broker Discovery Feature

## Overview
The MQTT demo app now includes an automatic broker discovery feature that helps clients find available MQTT brokers on the local network. This feature uses network scanning to detect brokers and provides a user-friendly interface for broker selection.

## Features

### 1. Automatic Network Scanning
- **Network Detection**: Automatically detects local network interfaces and scans for MQTT brokers
- **Port Scanning**: Checks common MQTT ports (1883, 8883, 9001, 8080) on all network devices
- **Timeout Protection**: Scans are limited to 5 seconds to avoid long waits
- **Periodic Refresh**: Automatically refreshes the broker list every 30 seconds

### 2. Manual Broker Entry
- **Fallback Option**: When automatic discovery doesn't find your broker, you can add it manually
- **Add to List**: Save manual entries to the discovered brokers list for easy reuse
- **Direct Connect**: Connect immediately to a manually entered broker
- **Input Validation**: Ensures valid IP addresses and port numbers

### 3. User-Friendly Interface
- **Visual Indicators**: Different icons for discovered vs. manual brokers
- **Broker Information**: Shows broker name, IP:port, and discovery method
- **One-Tap Connection**: Simply tap a broker to connect
- **Remove Manual Entries**: Delete manually added brokers you no longer need

## How to Use

### For Clients (Connecting to Brokers)
1. **Start the App**: Launch the MQTT demo app
2. **Select Client Mode**: Choose "Client" mode from the mode selection
3. **Open Broker Discovery**: Tap the search icon (🔍) next to the broker IP field
4. **Wait for Discovery**: The app will automatically scan the network for brokers
5. **Select Broker**: Tap any discovered broker to connect
6. **Manual Entry (if needed)**: If your broker isn't found, expand "Manual Entry" and enter the details

### For Brokers (Making Yourself Discoverable)
1. **Start Broker Mode**: Run the app in "Broker" mode on your device
2. **Note the IP**: The app displays your device's IP address at the top
3. **Ensure Network Connectivity**: Make sure both devices are on the same network
4. **Common Ports**: The broker runs on port 1883 (standard MQTT port)

## Technical Details

### Network Scanning Method
- **Approach**: TCP connection attempts to detect active MQTT brokers
- **Scope**: Scans all devices on the same network subnet
- **Efficiency**: Parallel scanning with timeouts to minimize wait time
- **Compatibility**: Works on Wi-Fi and hotspot networks

### Supported Ports
- **1883**: Standard MQTT port (unencrypted)
- **8883**: MQTT over TLS/SSL (encrypted)
- **9001**: MQTT over WebSocket
- **8080**: Alternative HTTP/WebSocket port

### File Structure
```
lib/
├── services/
│   └── broker_discovery_service.dart    # Core discovery logic
├── screens/
│   └── broker_discovery_screen.dart     # Discovery screen UI
├── widgets/
│   ├── broker_selection_widget.dart     # Broker list and selection UI
│   └── client_section.dart              # Updated with discovery button
```

## Benefits

### For Users
- **Simplified Setup**: No need to manually enter IP addresses
- **Automatic Discovery**: Find brokers without network knowledge
- **Better UX**: Visual, tap-to-connect interface
- **Fallback Support**: Manual entry when auto-discovery fails

### For Developers
- **Modular Code**: Clean separation of discovery logic and UI
- **Extensible**: Easy to add new discovery methods or protocols
- **Error Handling**: Robust error handling and timeout protection
- **Performance**: Efficient parallel scanning with minimal resource usage

## Future Enhancements

### Possible Improvements
1. **mDNS/Bonjour Support**: Add true service discovery protocol support
2. **Broker Validation**: Verify discovered services are actual MQTT brokers
3. **Connection Testing**: Test connectivity before showing brokers as available
4. **Custom Ports**: Allow users to specify additional ports to scan
5. **Network Filtering**: Option to scan specific network ranges
6. **Broker Information**: Show more details about discovered brokers (version, capabilities)

### Platform Support
- **Current**: Works on Android, iOS, and other Flutter-supported platforms
- **Future**: Could be enhanced with platform-specific discovery methods

## Troubleshooting

### Common Issues
1. **No Brokers Found**: Ensure both devices are on the same network
2. **Slow Discovery**: Network congestion can slow down scanning
3. **Manual Entry Required**: Some brokers may not be detectable via port scanning
4. **Connection Fails**: Firewall or network restrictions may block connections

### Debug Information
- All discovery operations are logged to the debug console
- Look for `[BrokerDiscovery]` prefix in logs
- Connection attempts and results are tracked

## Integration Notes

### For Existing Projects
The broker discovery feature is designed to be:
- **Non-Intrusive**: Doesn't affect existing manual IP entry functionality
- **Optional**: Can be disabled or hidden if not needed
- **Backward Compatible**: Works alongside existing connection methods

### Dependencies
- **No External Dependencies**: Uses only standard Dart/Flutter libraries
- **Network Access**: Requires network permissions for scanning
- **Socket Access**: Uses TCP sockets for broker detection
