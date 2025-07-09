import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'device_info_helper.dart';
import 'message_logger.dart';

/// Manages UDP broadcasting for MQTT broker discovery
class UdpBroadcastManager {
  final MessageLogger _logger;
  
  Timer? _broadcastTimer;
  RawDatagramSocket? _broadcastSocket;
  DateTime? _brokerStartTime;
  
  static const int _broadcastPort = 5555;
  static const Duration _fastBroadcastInterval = Duration(seconds: 5);
  static const Duration _slowBroadcastInterval = Duration(seconds: 30);
  static const Duration _fastBroadcastDuration = Duration(minutes: 2);
  
  UdpBroadcastManager(this._logger);
  
  /// Start UDP broadcasting for broker discovery
  Future<void> startBroadcast() async {
    try {
      _logger.log('🔧 Setting up UDP broadcast socket...');
      
      // Create UDP socket for broadcasting
      _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _broadcastSocket!.broadcastEnabled = true;
      
      // Record broker start time for smart broadcasting
      _brokerStartTime = DateTime.now();
      
      // Get device name
      final deviceName = await DeviceInfoHelper.getDeviceName();
      _logger.log('📱 Device name: ${deviceName ?? 'Unknown Device'}');
      
      // Start with fast broadcasting for initial discovery
      _logger.log('🚀 Starting fast broadcast mode (${_fastBroadcastInterval.inSeconds}s interval for ${_fastBroadcastDuration.inMinutes} minutes)');
      _startSmartBroadcasting(deviceName);
      
      // Send initial announcement immediately
      await _sendBrokerAnnouncement(deviceName);
      
      _logger.log('✅ UDP broadcast started successfully');
    } catch (e) {
      _logger.log('❌ Failed to start UDP broadcast: $e');
      rethrow;
    }
  }
  
  /// Stop UDP broadcasting
  Future<void> stopBroadcast() async {
    try {
      if (_broadcastTimer != null) {
        _logger.log('🛑 Stopping UDP broadcast timer...');
        _broadcastTimer!.cancel();
        _broadcastTimer = null;
      }
      
      if (_broadcastSocket != null) {
        _logger.log('🔌 Closing UDP broadcast socket...');
        _broadcastSocket!.close();
        _broadcastSocket = null;
      }
      
      _logger.log('✅ UDP broadcast stopped');
    } catch (e) {
      _logger.log('❌ Error stopping UDP broadcast: $e');
      // Force cleanup
      _broadcastTimer = null;
      _broadcastSocket = null;
    }
  }
  
  /// Start smart broadcasting with fast initial period, then slow maintenance
  void _startSmartBroadcasting(String? deviceName) {
    // Start with fast broadcasting
    _broadcastTimer = Timer.periodic(_fastBroadcastInterval, (timer) async {
      final elapsed = DateTime.now().difference(_brokerStartTime!);
      
      if (elapsed >= _fastBroadcastDuration) {
        // Switch to slow broadcasting
        _logger.log('🔄 Switching to slow broadcast mode (${_slowBroadcastInterval.inSeconds}s interval)');
        timer.cancel();
        
        _broadcastTimer = Timer.periodic(_slowBroadcastInterval, (slowTimer) async {
          await _sendBrokerAnnouncement(deviceName);
        });
      }
      
      await _sendBrokerAnnouncement(deviceName);
    });
  }
  
  /// Send broker announcement via UDP broadcast
  Future<void> _sendBrokerAnnouncement(String? deviceName) async {
    try {
      final announcement = {
        'type': 'mqtt-broker-announcement',
        'deviceName': deviceName ?? 'Unknown Device',
        'brokerName': 'MQTT Broker',
        'port': 1883,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final message = jsonEncode(announcement);
      final data = message.codeUnits;
      
      // Send to broadcast address
      _broadcastSocket!.send(data, InternetAddress('255.255.255.255'), _broadcastPort);
      
      _logger.log('📡 Sent broker announcement: ${deviceName ?? 'Unknown Device'}');
    } catch (e) {
      _logger.log('❌ Error sending broker announcement: $e');
    }
  }
  
  /// Clean up resources
  void dispose() {
    _brokerStartTime = null;
    stopBroadcast();
  }
}
