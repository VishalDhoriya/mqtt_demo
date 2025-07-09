import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'message_logger.dart';
import 'device_info_helper.dart';

/// Manages MQTT client connections and operations
class MqttClientManager {
  final MessageLogger _logger;
  final Function()? _onStateChanged;
  
  MqttServerClient? _client;
  bool _isConnected = false;
  bool _isSubscribed = false;
  String _brokerIp = '';
  String _clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  final String _defaultTopic = 'test/topic';
  final String _shareTopic = 'share/topic';
  final Set<String> _subscribedTopics = {};
  
  MqttClientManager(this._logger, {Function()? onStateChanged}) 
    : _onStateChanged = onStateChanged;
  
  /// Get connection status
  bool get isConnected => _isConnected;
  
  /// Get subscription status
  bool get isSubscribed => _isSubscribed;
  
  /// Get broker IP
  String get brokerIp => _brokerIp;
  
  /// Get the default topic
  String get defaultTopic => _defaultTopic;
  
  /// Get the share topic
  String get shareTopic => _shareTopic;
  
  /// Get list of subscribed topics
  Set<String> get subscribedTopics => _subscribedTopics;

  /// Connect to MQTT broker
  Future<bool> connect(String brokerIp) async {
    _logger.log('🔌 Attempting to connect to MQTT broker...');
    _logger.log('📍 Broker IP: $brokerIp');
    
    try {
      _brokerIp = brokerIp;
      
      // Generate client ID with device name and IP
      final deviceName = await DeviceInfoHelper.getDeviceName() ?? 'Unknown';
      _clientId = 'mqtt_client_${deviceName}_${brokerIp.replaceAll('.', '-')}';
      _logger.log('👤 Client ID: $_clientId');
      
      // Disconnect existing client if connected
      if (_client != null) {
        _logger.log('⚠️  Disconnecting existing client');
        _client!.disconnect();
      }
      
      // Create new MQTT client
      _logger.log('🔧 Creating MQTT client instance');
      _client = MqttServerClient(_brokerIp, _clientId);
      
      // Configure client settings
      _logger.log('⚙️  Configuring client settings');
      _client!.logging(on: true);
      _client!.keepAlivePeriod = 60; // Increased from 30 to 60 seconds for longer timeout
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onUnsubscribed = _onUnsubscribed;
      _client!.setProtocolV311();
      _client!.autoReconnect = true; // Enable auto-reconnect
      
      // Set ping response handling
      _client!.keepAlivePeriod = 60; // Increased timeout
      
      // Create connection message
      _logger.log('📝 Creating connection message');
      final connMess = MqttConnectMessage()
          .withClientIdentifier(_clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMess;
      
      // Attempt connection
      _logger.log('🚀 Connecting to broker...');
      await _client!.connect();
      
      // Check connection status
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _isConnected = true;
        _logger.log('✅ Connected to MQTT broker at $_brokerIp');
        _logger.log('🔗 Connection status: ${_client!.connectionStatus!.state}');
        
        // Send connection notification to broker
        _logger.log('📢 Sending connection notification to broker...');
        _sendConnectionNotification();
        
        // Set up message listener
        _logger.log('👂 Setting up message listener');
        _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) async {
          if (messages != null && messages.isNotEmpty) {
            final recMess = messages[0].payload as MqttPublishMessage;
            final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            final topic = messages[0].topic;
            _logger.log('📨 Received message: "$message" from topic: $topic');
            
            // Process message based on topic
            await _processIncomingMessage(topic, message);
          }
        });
        
        _onStateChanged?.call();
        return true;
      } else {
        _logger.log('❌ Connection failed - Status: ${_client!.connectionStatus!.state}');
        _logger.log('🔍 Return code: ${_client!.connectionStatus!.returnCode}');
        _onStateChanged?.call();
        return false;
      }
    } catch (e) {
      _logger.log('❌ Connection error: $e');
      _logger.log('🔍 Error type: ${e.runtimeType}');
      _onStateChanged?.call();
      return false;
    }
  }
  
  /// Disconnect from MQTT broker
  Future<void> disconnect() async {
    _logger.log('🔌 Disconnecting from MQTT broker...');
    try {
      if (_client != null && _isConnected) {
        // Send disconnection notification before disconnecting
        _logger.log('📢 Sending disconnection notification to broker...');
        _sendDisconnectionNotification();
        
        // Wait a moment for message to be sent
        await Future.delayed(const Duration(milliseconds: 100));
        
        _logger.log('🔧 Closing client connection');
        _client!.disconnect();
        _client = null;
      }
      _isConnected = false;
      _isSubscribed = false;
      _logger.log('✅ Disconnected from MQTT broker');
      _onStateChanged?.call();
    } catch (e) {
      _logger.log('❌ Disconnect error: $e');
      _onStateChanged?.call();
    }
  }
  
  /// Subscribe to default topic
  Future<void> subscribe() async {
    await subscribeToTopic(_defaultTopic);
  }
  
  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    _logger.log('📡 Attempting to subscribe to topic: $topic');
    try {
      if (_client != null && _isConnected) {
        _logger.log('✅ Client is connected, proceeding with subscription');
        _logger.log('🎯 Subscribing to topic: $topic with QoS: atMostOnce');
        _client!.subscribe(topic, MqttQos.atMostOnce);
        _subscribedTopics.add(topic);
        _isSubscribed = true;
        _logger.log('📬 Subscription request sent');
      } else {
        _logger.log('❌ Cannot subscribe - client not connected');
        _logger.log('🔍 Client exists: ${_client != null}');
        _logger.log('🔍 Is connected: $_isConnected');
      }
    } catch (e) {
      _logger.log('❌ Subscribe error: $e');
      _onStateChanged?.call();
    }
  }
  
  /// Unsubscribe from default topic
  Future<void> unsubscribe() async {
    await unsubscribeFromTopic(_defaultTopic);
  }
  
  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    _logger.log('📡 Attempting to unsubscribe from topic: $topic');
    try {
      if (_client != null && _isConnected) {
        _logger.log('✅ Client is connected, proceeding with unsubscription');
        _client!.unsubscribe(topic);
        _subscribedTopics.remove(topic);
        if (_subscribedTopics.isEmpty) {
          _isSubscribed = false;
        }
        _logger.log('📭 Unsubscription request sent');
      } else {
        _logger.log('❌ Cannot unsubscribe - client not connected');
      }
    } catch (e) {
      _logger.log('❌ Unsubscribe error: $e');
      _onStateChanged?.call();
    }
  }
  
  /// Publish message to topic
  Future<void> publishMessage({String? message, String? topic}) async {
    final msg = message ?? 'Hello, MQTT!';
    final pubTopic = topic ?? _defaultTopic;
    
    _logger.log('📤 Publishing message...');
    _logger.log('📍 Topic: $pubTopic');
    
    // Don't log large messages completely to avoid terminal spam
    final truncatedMessage = msg.length > 100 ? '${msg.substring(0, 100)}...' : msg;
    _logger.log('📝 Message: "$truncatedMessage"');
    _logger.log('🎯 QoS: atMostOnce');
    
    try {
      if (_client != null && _isConnected) {
        _logger.log('✅ Client is connected, proceeding with publish');
        
        // Check message size to avoid MQTT protocol limits
        if (msg.length > 1024) {
          _logger.log('⚠️ Message size (${msg.length} bytes) is large, may exceed broker limits');
        }
        
        // Create payload
        final builder = MqttClientPayloadBuilder();
        builder.addString(msg);
        _logger.log('📦 Payload created (${builder.payload!.length} bytes)');
        
        // Publish message
        _client!.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload!);
        _logger.log('🚀 Message published successfully');
        
        _onStateChanged?.call();
      } else {
        _logger.log('❌ Cannot publish - client not connected');
        _logger.log('🔍 Client exists: ${_client != null}');
        _logger.log('🔍 Is connected: $_isConnected');
      }
    } catch (e) {
      _logger.log('❌ Publish error: $e');
      _onStateChanged?.call();
    }
  }
  
  /// Callback when client connects
  void _onConnected() {
    _logger.log('🔗 Client connected successfully');
    _logger.log('📊 Connection details:');
    _logger.log('   - Client ID: $_clientId');
    _logger.log('   - Broker IP: $_brokerIp');
    _logger.log('   - Protocol: MQTT v3.1.1');
    _logger.log('   - Keep alive: 30 seconds');
    _onStateChanged?.call();
  }
  
  /// Callback when client disconnects
  void _onDisconnected() {
    _isConnected = false;
    _isSubscribed = false;
    _logger.log('🔌 Client disconnected');
    _logger.log('📊 Connection status updated:');
    _logger.log('   - Connected: $_isConnected');
    _logger.log('   - Subscribed: $_isSubscribed');
    _onStateChanged?.call();
  }
  
  /// Callback when subscribed to topic
  void _onSubscribed(String topic) {
    _isSubscribed = true;
    _logger.log('📬 Successfully subscribed to topic: $topic');
    _logger.log('🎯 Subscription status: $_isSubscribed');
    _logger.log('👂 Now listening for messages on topic: $topic');
    _onStateChanged?.call();
  }
  
  /// Callback when unsubscribed from topic
  void _onUnsubscribed(String? topic) {
    _isSubscribed = false;
    _logger.log('📭 Successfully unsubscribed from topic: $topic');
    _logger.log('🎯 Subscription status: $_isSubscribed');
    _logger.log('🔇 No longer listening for messages on topic: $topic');
    _onStateChanged?.call();
  }
  
  /// Send connection notification to broker
  void _sendConnectionNotification() {
    try {
      if (_client != null && _isConnected) {
        _logger.log('📢 Sending connection notification for client: $_clientId');
        final builder = MqttClientPayloadBuilder();
        builder.addString(_clientId);
        _client!.publishMessage('client/connect', MqttQos.atMostOnce, builder.payload!);
      }
    } catch (e) {
      _logger.log('❌ Error sending connection notification: $e');
    }
  }
  
  /// Send disconnection notification to broker
  void _sendDisconnectionNotification() {
    try {
      if (_client != null && _isConnected) {
        _logger.log('📢 Sending disconnection notification for client: $_clientId');
        final builder = MqttClientPayloadBuilder();
        builder.addString(_clientId);
        _client!.publishMessage('client/disconnect', MqttQos.atMostOnce, builder.payload!);
      }
    } catch (e) {
      _logger.log('❌ Error sending disconnection notification: $e');
    }
  }
  
  /// Process incoming MQTT messages
  Future<void> _processIncomingMessage(String topic, String message) async {
    // Log reception first
    _logger.log('🔍 Processing message from topic: $topic');
    
    // Handle specific topics
    if (topic == _shareTopic) {
      _logger.log('📦 Processing share topic message');
      
      try {
        // Notify via callback for file share messages
        if (_onFileShareMessage != null) {
          _logger.log('📥 File notification received');
          await _onFileShareMessage!(message);
        } else {
          _logger.log('⚠️ No file share message handler registered');
        }
      } catch (e) {
        _logger.log('❌ Error processing file share message: $e');
      }
    }
  }
  
  // File share message callback
  Function(String)? _onFileShareMessage;
  
  /// Set callback for file share messages
  void setFileShareMessageHandler(Function(String) callback) {
    _onFileShareMessage = callback;
    _logger.log('✅ File share message handler registered');
  }
  
  /// Clean up resources
  void dispose() {
    disconnect();
  }
}
