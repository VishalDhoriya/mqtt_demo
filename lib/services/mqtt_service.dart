import 'package:flutter/foundation.dart';
import 'message_logger.dart';
import 'mqtt_client_manager.dart';
import 'mqtt_broker_manager.dart';
import 'client_tracker.dart';
import 'connected_client.dart';

/// Main MQTT service that orchestrates client and broker operations
class MqttService extends ChangeNotifier {
  late final MessageLogger _logger;
  late final MqttClientManager _clientManager;
  late final MqttBrokerManager _brokerManager;
  late final ClientTracker _clientTracker;
  
  // Current mode
  AppMode _currentMode = AppMode.none;
  
  MqttService() {
    _logger = MessageLogger();
    _clientManager = MqttClientManager(_logger, onStateChanged: notifyListeners);
    _clientTracker = ClientTracker(_logger);
    _brokerManager = MqttBrokerManager(_logger, _clientTracker, onStateChanged: notifyListeners);
    
    // Listen to client tracker changes
    _clientTracker.addListener(notifyListeners);
  }
  
  // Getters
  bool get isConnected => _clientManager.isConnected;
  bool get isSubscribed => _clientManager.isSubscribed;
  bool get isBrokerRunning => _brokerManager.isBrokerRunning;
  String get brokerIp => _clientManager.brokerIp;
  List<String> get messages => _logger.messages;
  AppMode get currentMode => _currentMode;
  List<ConnectedClient> get connectedClients => _clientTracker.connectedClients;
  int get connectedClientsCount => _clientTracker.connectedCount;
  
  // Set mode
  void setMode(AppMode mode) {
    _logger.log('Setting mode to: $mode');
    _currentMode = mode;
    notifyListeners();
  }
  
  // MQTT Broker functionality
  Future<bool> startBroker() async {
    return await _brokerManager.startBroker();
  }
  
  Future<void> stopBroker() async {
    await _brokerManager.stopBroker();
  }
  
  // MQTT Client functionality
  Future<bool> connect(String brokerIp) async {
    return await _clientManager.connect(brokerIp);
  }
  
  Future<void> disconnect() async {
    await _clientManager.disconnect();
  }
  
  Future<void> subscribe() async {
    await _clientManager.subscribe();
  }
  
  Future<void> unsubscribe() async {
    await _clientManager.unsubscribe();
  }
  
  Future<void> publishMessage({String? message, String? topic}) async {
    await _clientManager.publishMessage(message: message, topic: topic);
    
    // If we're running a broker, also log the message as received by broker
    if (_brokerManager.isBrokerRunning) {
      _logger.log('📨 [BROKER] Message published to topic: ${topic ?? 'test/topic'}');
      _logger.log('📝 [BROKER] Message content: "${message ?? 'Hello, MQTT!'}"');
      _logger.log('🔄 [BROKER] Broadcasting to all connected clients...');
    }
  }
  
  void clearMessages() {
    _logger.clearMessages();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _logger.log('🧹 Disposing MqttService');
    _clientTracker.removeListener(notifyListeners);
    _clientManager.dispose();
    _brokerManager.dispose();
    _logger.log('✅ MqttService disposed');
    super.dispose();
  }
}

enum AppMode {
  none,
  broker,
  client,
}