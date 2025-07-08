import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_server/mqtt_server.dart';

class MqttService extends ChangeNotifier {
  // MQTT Client variables
  MqttServerClient? _client;
  bool _isConnected = false;
  bool _isSubscribed = false;
  String _brokerIp = '';
  final String _clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  final String _defaultTopic = 'test/topic';
  final List<String> _messages = [];
  
  // MQTT Broker variables
  MqttBroker? _broker;
  bool _isBrokerRunning = false;
  MqttServerClient? _brokerMonitorClient; // Client to monitor broker messages
  
  // Current mode
  AppMode _currentMode = AppMode.none;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isSubscribed => _isSubscribed;
  bool get isBrokerRunning => _isBrokerRunning;
  String get brokerIp => _brokerIp;
  List<String> get messages => _messages;
  AppMode get currentMode => _currentMode;
  
  // Logging helper method
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] MQTT: $message';
    if (kDebugMode) {
      print(logMessage); // This will show in terminal/console
    }
    _addMessage(message);
  }
  
  // Set mode
  void setMode(AppMode mode) {
    _log('Setting mode to: $mode');
    _currentMode = mode;
    notifyListeners();
  }
  
  // MQTT Broker functionality
  Future<bool> startBroker() async {
    _log('🚀 Starting MQTT broker...');
    try {
      // Stop existing broker if running
      if (_broker != null) {
        _log('⚠️  Stopping existing broker before starting new one');
        await _broker!.stop();
      }
      
      // Create broker configuration
      _log('⚙️  Creating broker configuration (port: 1883, anonymous: true)');
      final config = MqttBrokerConfig(
        port: 1883,
        allowAnonymous: true,
        enablePersistence: false,
      );
      
      // Create and start broker
      _log('🔧 Creating broker instance');
      _broker = MqttBroker(config);
      
      _log('🎯 Starting broker on port 1883...');
      await _broker!.start();
      
      _isBrokerRunning = true;
      _log('✅ MQTT Broker started successfully on port 1883');
      _log('📡 Broker is ready to accept client connections');
      
      // Start broker monitoring client to log all messages (optional)
      _log('👂 Starting broker monitoring client...');
      _startBrokerMonitoringClient().catchError((error) {
        _log('⚠️  Broker monitoring client failed to start: $error');
        _log('📝 Broker will continue without message monitoring');
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      _log('❌ Failed to start broker: $e');
      _isBrokerRunning = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> stopBroker() async {
    _log('🛑 Stopping MQTT broker...');
    try {
      // Stop monitoring client first
      await _stopBrokerMonitoringClient();
      
      if (_broker != null) {
        _log('🔧 Shutting down broker instance');
        await _broker!.stop();
        _broker = null;
      }
      _isBrokerRunning = false;
      _log('✅ MQTT Broker stopped successfully');
      notifyListeners();
    } catch (e) {
      _log('❌ Failed to stop broker: $e');
      notifyListeners();
    }
  }
  
  // MQTT Client functionality
  Future<bool> connect(String brokerIp) async {
    _log('🔌 Attempting to connect to MQTT broker...');
    _log('📍 Broker IP: $brokerIp');
    _log('👤 Client ID: $_clientId');
    
    try {
      _brokerIp = brokerIp;
      
      // Disconnect existing client if connected
      if (_client != null) {
        _log('⚠️  Disconnecting existing client');
        _client!.disconnect();
      }
      
      // Create new MQTT client
      _log('🔧 Creating MQTT client instance');
      _client = MqttServerClient(_brokerIp, _clientId);
      
      // Configure client settings
      _log('⚙️  Configuring client settings');
      _client!.logging(on: true); // Enable client logging
      _client!.keepAlivePeriod = 30;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onUnsubscribed = _onUnsubscribed;
      _client!.setProtocolV311();
      
      // Create connection message
      _log('📝 Creating connection message');
      final connMess = MqttConnectMessage()
          .withClientIdentifier(_clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMess;
      
      // Attempt connection
      _log('🚀 Connecting to broker...');
      await _client!.connect();
      
      // Check connection status
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        _log('✅ Connected to MQTT broker at $_brokerIp');
        _log('🔗 Connection status: ${_client!.connectionStatus!.state}');
        
        // Set up message listener
        _log('👂 Setting up message listener');
        _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
          if (messages != null && messages.isNotEmpty) {
            final recMess = messages[0].payload as MqttPublishMessage;
            final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            final topic = messages[0].topic;
            _log('📨 Received message: "$message" from topic: $topic');
          }
        });
        
        notifyListeners();
        return true;
      } else {
        _log('❌ Connection failed - Status: ${_client!.connectionStatus!.state}');
        _log('🔍 Return code: ${_client!.connectionStatus!.returnCode}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _log('❌ Connection error: $e');
      _log('🔍 Error type: ${e.runtimeType}');
      notifyListeners();
      return false;
    }
  }
  
  Future<void> disconnect() async {
    _log('🔌 Disconnecting from MQTT broker...');
    try {
      if (_client != null) {
        _log('🔧 Closing client connection');
        _client!.disconnect();
        _client = null;
      }
      _isConnected = false;
      _isSubscribed = false;
      _log('✅ Disconnected from MQTT broker');
      notifyListeners();
    } catch (e) {
      _log('❌ Disconnect error: $e');
      notifyListeners();
    }
  }
  
  Future<void> subscribe() async {
    _log('📡 Attempting to subscribe to topic: $_defaultTopic');
    try {
      if (_client != null && _isConnected) {
        _log('✅ Client is connected, proceeding with subscription');
        _log('🎯 Subscribing to topic: $_defaultTopic with QoS: atMostOnce');
        _client!.subscribe(_defaultTopic, MqttQos.atMostOnce);
        _log('📬 Subscription request sent');
      } else {
        _log('❌ Cannot subscribe - client not connected');
        _log('🔍 Client exists: ${_client != null}');
        _log('🔍 Is connected: $_isConnected');
      }
    } catch (e) {
      _log('❌ Subscribe error: $e');
      notifyListeners();
    }
  }
  
  Future<void> unsubscribe() async {
    _log('📡 Attempting to unsubscribe from topic: $_defaultTopic');
    try {
      if (_client != null && _isConnected) {
        _log('✅ Client is connected, proceeding with unsubscription');
        _client!.unsubscribe(_defaultTopic);
        _log('📭 Unsubscription request sent');
      } else {
        _log('❌ Cannot unsubscribe - client not connected');
      }
    } catch (e) {
      _log('❌ Unsubscribe error: $e');
      notifyListeners();
    }
  }
  
  Future<void> publishMessage({String? message, String? topic}) async {
    final msg = message ?? 'Hello, MQTT!';
    final pubTopic = topic ?? _defaultTopic;
    
    _log('📤 Publishing message...');
    _log('📍 Topic: $pubTopic');
    _log('📝 Message: "$msg"');
    _log('🎯 QoS: atMostOnce');
    
    try {
      if (_client != null && _isConnected) {
        _log('✅ Client is connected, proceeding with publish');
        
        // Create payload
        final builder = MqttClientPayloadBuilder();
        builder.addString(msg);
        _log('📦 Payload created (${builder.payload!.length} bytes)');
        
        // Publish message
        _client!.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload!);
        _log('🚀 Message published successfully');
        
        // If we're running a broker, also log the message as received by broker
        if (_isBrokerRunning) {
          _log('📨 [BROKER] Message published to topic: $pubTopic');
          _log('📝 [BROKER] Message content: "$msg"');
          _log('🔄 [BROKER] Broadcasting to all connected clients...');
        }
        
        notifyListeners();
      } else {
        _log('❌ Cannot publish - client not connected');
        _log('🔍 Client exists: ${_client != null}');
        _log('🔍 Is connected: $_isConnected');
      }
    } catch (e) {
      _log('❌ Publish error: $e');
      notifyListeners();
    }
  }
  
  // Callback functions with detailed logging
  void _onConnected() {
    _log('🔗 Client connected successfully');
    _log('📊 Connection details:');
    _log('   - Client ID: $_clientId');
    _log('   - Broker IP: $_brokerIp');
    _log('   - Protocol: MQTT v3.1.1');
    _log('   - Keep alive: 30 seconds');
    notifyListeners();
  }
  
  void _onDisconnected() {
    _isConnected = false;
    _isSubscribed = false;
    _log('🔌 Client disconnected');
    _log('📊 Connection status updated:');
    _log('   - Connected: $_isConnected');
    _log('   - Subscribed: $_isSubscribed');
    notifyListeners();
  }
  
  void _onSubscribed(String topic) {
    _isSubscribed = true;
    _log('📬 Successfully subscribed to topic: $topic');
    _log('🎯 Subscription status: $_isSubscribed');
    _log('👂 Now listening for messages on topic: $topic');
    notifyListeners();
  }
  
  void _onUnsubscribed(String? topic) {
    _isSubscribed = false;
    _log('📭 Successfully unsubscribed from topic: $topic');
    _log('🎯 Subscription status: $_isSubscribed');
    _log('🔇 No longer listening for messages on topic: $topic');
    notifyListeners();
  }
  
  void _addMessage(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _messages.add('[$timestamp] $message');
    if (_messages.length > 100) {
      _messages.removeAt(0);
    }
  }
  
  void clearMessages() {
    _log('🧹 Clearing message log');
    _messages.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _log('🧹 Disposing MqttService');
    _log('🔌 Disconnecting client...');
    disconnect();
    _log('� Stopping broker monitoring client...');
    _stopBrokerMonitoringClient();
    _log('�🛑 Stopping broker...');
    stopBroker();
    _log('✅ MqttService disposed');
    super.dispose();
  }
  
  // Broker monitoring client to log all messages
  Future<void> _startBrokerMonitoringClient() async {
    try {
      _log('🔧 Creating broker monitoring client...');
      
      // Wait a bit for broker to be fully ready
      await Future.delayed(const Duration(milliseconds: 1000));
      
      const monitorClientId = 'broker_monitor_client';
      
      // Create monitoring client that connects to localhost
      _brokerMonitorClient = MqttServerClient('127.0.0.1', monitorClientId);
      _brokerMonitorClient!.logging(on: false); // Disable client logging to avoid spam
      _brokerMonitorClient!.keepAlivePeriod = 30;
      _brokerMonitorClient!.setProtocolV311();
      
      // Set up connection message
      final connMess = MqttConnectMessage()
          .withClientIdentifier(monitorClientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _brokerMonitorClient!.connectionMessage = connMess;
      
      // Connect the monitoring client with timeout
      _log('🔗 Connecting monitoring client to broker...');
      await _brokerMonitorClient!.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('⏰ Broker monitoring client connection timed out');
          throw TimeoutException('Connection timeout', const Duration(seconds: 5));
        },
      );
      
      // Check if connection was successful
      if (_brokerMonitorClient?.connectionStatus?.state == MqttConnectionState.connected) {
        _log('✅ Broker monitoring client connected');
        
        // Set up message listener for monitoring
        _brokerMonitorClient!.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
          if (messages != null && messages.isNotEmpty) {
            try {
              final recMess = messages[0].payload as MqttPublishMessage;
              final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
              final topic = messages[0].topic;
              _log('📨 [BROKER] Message received: "$message" on topic: $topic');
              _log('🔄 [BROKER] Broadcasting message to all connected clients...');
            } catch (e) {
              _log('❌ Error processing broker message: $e');
            }
          }
        });
        
        // Subscribe to all topics using wildcard
        _log('📡 Subscribing to all topics (#) for message monitoring...');
        _brokerMonitorClient!.subscribe('#', MqttQos.atMostOnce);
        _log('👂 Broker is now monitoring all messages');
      } else {
        _log('❌ Failed to connect broker monitoring client - Status: ${_brokerMonitorClient?.connectionStatus?.state}');
        _log('📝 Broker will continue without message monitoring');
      }
    } catch (e) {
      _log('❌ Error starting broker monitoring client: $e');
      _log('🔍 Error type: ${e.runtimeType}');
      _log('📝 Broker will continue without message monitoring');
      // Clean up on error
      _brokerMonitorClient = null;
    }
  }

  Future<void> _stopBrokerMonitoringClient() async {
    try {
      if (_brokerMonitorClient != null) {
        _log('🔌 Stopping broker monitoring client...');
        if (_brokerMonitorClient!.connectionStatus?.state == MqttConnectionState.connected) {
          _brokerMonitorClient!.disconnect();
        }
        _brokerMonitorClient = null;
        _log('✅ Broker monitoring client stopped');
      }
    } catch (e) {
      _log('❌ Error stopping broker monitoring client: $e');
      _brokerMonitorClient = null; // Force cleanup
    }
  }
}

enum AppMode {
  none,
  broker,
  client,
}