/// Represents a connected MQTT client
class ConnectedClient {
  final String clientId;
  final String deviceName;
  final String ipAddress;
  final DateTime connectedAt;
  
  ConnectedClient({
    required this.clientId,
    required this.deviceName,
    required this.ipAddress,
    required this.connectedAt,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectedClient && other.clientId == clientId;
  }
  
  @override
  int get hashCode => clientId.hashCode;
  
  @override
  String toString() {
    return 'ConnectedClient(clientId: $clientId, deviceName: $deviceName, ipAddress: $ipAddress)';
  }
}
