# System Topics Subscription Fix

## Issue
Regular MQTT clients (not just the broker) were not subscribing to system topics (`client/connect` and `client/disconnect`), which meant that connection/disconnection events were only visible in the UI on the broker device, not on all connected clients.

## Root Cause
The `subscribe()` method in `MqttService` was only subscribing to:
1. Default topic (`test/topic`)
2. Share topic (`share/topic`)

But it was missing the system topics:
3. `client/connect`
4. `client/disconnect`

## Fix Applied
Updated the `MqttService` class to subscribe to system topics:

### Changes Made:

1. **Updated `subscribe()` method**: Now subscribes to system topics for regular clients
2. **Updated `unsubscribe()` method**: Now properly unsubscribes from system topics
3. **Updated `_setupHostPublishingClient()` method**: Broker host client also subscribes to system topics

### Code Changes:

```dart
// In subscribe() method:
await _clientManager.subscribeToTopic('client/connect');
await _clientManager.subscribeToTopic('client/disconnect');

// In unsubscribe() method:
await _clientManager.unsubscribeFromTopic('client/connect');
await _clientManager.unsubscribeFromTopic('client/disconnect');
```

## Result
Now all MQTT clients (both regular clients and broker host) will:
- Subscribe to all relevant topics including system topics
- Receive and display `client/connect` and `client/disconnect` messages in their UI
- Show real-time connection/disconnection events for all devices on the network

## Testing
- No compilation errors
- Flutter analyze passes with no issues
- All system topics should now be visible in the Topics page UI for all connected devices

## File Modified
- `lib/services/mqtt_service.dart` - Updated subscription logic

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
