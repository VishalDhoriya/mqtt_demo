import 'package:flutter/foundation.dart';
import 'connected_client.dart';
import 'message_logger.dart';

/// Manages tracking of connected MQTT clients
class ClientTracker extends ChangeNotifier {
  final MessageLogger _logger;
  final Map<String, ConnectedClient> _connectedClients = {};
  
  ClientTracker(this._logger);
  
  /// Get list of connected clients
  List<ConnectedClient> get connectedClients => _connectedClients.values.toList();
  
  /// Get count of connected clients
  int get connectedCount => _connectedClients.length;
  
  /// Add a connected client
  void addClient(ConnectedClient client) {
    _logger.log('👥 Client connected: ${client.deviceName} (${client.ipAddress})');
    _connectedClients[client.clientId] = client;
    notifyListeners();
  }
  
  /// Remove a disconnected client
  void removeClient(String clientId) {
    final client = _connectedClients.remove(clientId);
    if (client != null) {
      _logger.log('👋 Client disconnected: ${client.deviceName} (${client.ipAddress})');
      notifyListeners();
    }
  }
  
  /// Check if a client is connected
  bool isClientConnected(String clientId) {
    return _connectedClients.containsKey(clientId);
  }
  
  /// Get client by ID
  ConnectedClient? getClient(String clientId) {
    return _connectedClients[clientId];
  }
  
  /// Clear all clients
  void clearAllClients() {
    _logger.log('🧹 Clearing all connected clients');
    _connectedClients.clear();
    notifyListeners();
  }
  
  /// Try to extract device name and IP from client ID
  /// Expected format: "mqtt_client_DeviceName_BrokerIP_DeviceIP"
  ConnectedClient? parseClientInfo(String clientId) {
    try {
      // Try to parse client ID in format: mqtt_client_DeviceName_BrokerIP_DeviceIP
      if (clientId.startsWith('mqtt_client_')) {
        final parts = clientId.split('_');
        if (parts.length >= 5) {
          final deviceName = parts[2];
          // Convert dashes back to dots for device IP address (parts[4])
          final deviceIp = parts[4].replaceAll('-', '.');
          
          return ConnectedClient(
            clientId: clientId,
            deviceName: deviceName,
            ipAddress: deviceIp,
            connectedAt: DateTime.now(),
          );
        }
      }
      
      // Fallback: create client with just the ID
      return ConnectedClient(
        clientId: clientId,
        deviceName: clientId,
        ipAddress: 'Unknown',
        connectedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.log('❌ Error parsing client info from ID: $clientId - $e');
      return null;
    }
  }
}
