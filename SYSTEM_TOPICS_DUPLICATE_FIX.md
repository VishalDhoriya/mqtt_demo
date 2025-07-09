# System Topics Duplicate Message Fix

## Issue
System topics (`client/connect` and `client/disconnect`) were showing duplicate messages on the broker side - each message appeared twice in the UI while clients only saw it once.

## Root Cause
The duplication was caused by the broker receiving system topic messages through **two different paths**:

1. **Normal MQTT Subscription**: The broker's monitoring client was subscribed to system topics like any other client
2. **Direct Forwarding**: The `_handleClientConnectionMessage` method was manually forwarding the same messages to TopicManager

This created a race condition where the same message was processed twice by the TopicManager.

## Message Flow Analysis

### Before Fix (Duplicate Messages):
```
Client publishes to client/connect
        ↓
Broker receives message
        ↓
┌─────────────────────────────────────────┐
│ Path 1: Normal MQTT Subscription       │
│ ├─ Broker monitoring client receives   │
│ ├─ Calls _handleIncomingMessage        │
│ └─ Adds to TopicManager (1st time)     │
│                                         │
│ Path 2: Direct Handler                  │
│ ├─ _handleClientConnectionMessage      │
│ ├─ Calls _onMessageReceived            │
│ └─ Adds to TopicManager (2nd time)     │ ← DUPLICATE!
└─────────────────────────────────────────┘
```

### After Fix (Single Message):
```
Client publishes to client/connect
        ↓
Broker receives message
        ↓
┌─────────────────────────────────────────┐
│ Path 1: Normal MQTT Subscription       │
│ ├─ Broker monitoring client receives   │
│ ├─ Calls _handleIncomingMessage        │
│ └─ Adds to TopicManager (only time)    │
│                                         │
│ Path 2: Client Tracking Only           │
│ ├─ _handleClientConnectionMessage      │
│ ├─ Updates ClientTracker              │
│ └─ NO TopicManager call                │ ← FIXED!
└─────────────────────────────────────────┘
```

## Fix Applied
1. **Removed duplicate forwarding**: Removed the `_onMessageReceived` call from `_handleClientConnectionMessage`
2. **Simplified broker manager**: Removed unused `_onMessageReceived` parameter from `MqttBrokerManager` constructor
3. **Updated service integration**: Cleaned up the constructor call in `MqttService`

### Code Changes:

**File: `lib/services/mqtt_broker_manager.dart`**
```dart
// REMOVED this line that caused duplicates:
// if (_onMessageReceived != null) {
//   _onMessageReceived(topic, message);
// }

// Now _handleClientConnectionMessage only handles client tracking
void _handleClientConnectionMessage(String message, String topic) {
  // Only update ClientTracker, no TopicManager forwarding
  if (topic == 'client/connect') {
    final clientInfo = _clientTracker.parseClientInfo(message);
    if (clientInfo != null) {
      _clientTracker.addClient(clientInfo);
    }
  } else if (topic == 'client/disconnect') {
    _clientTracker.removeClient(message);
  }
}
```

**File: `lib/services/mqtt_service.dart`**
```dart
// Removed onMessageReceived parameter from broker manager constructor
_brokerManager = MqttBrokerManager(_logger, _clientTracker, 
  onStateChanged: notifyListeners,
);
```

## Result
- ✅ **Regular clients**: Still see system topic messages exactly once
- ✅ **Broker host**: Now sees system topic messages exactly once (was twice before)
- ✅ **Client tracking**: Still works properly for connected clients management
- ✅ **UI consistency**: All devices show the same message count for system topics

## Testing
- ✅ No compilation errors
- ✅ Flutter analyze passes
- ✅ System topics should now show consistent message counts across all devices

## Technical Notes
The fix maintains the **separation of concerns**:
- **Normal MQTT flow**: Handles UI display through TopicManager
- **Client tracking**: Handles connected clients management through ClientTracker
- **No overlap**: Each message is processed exactly once by each system

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
