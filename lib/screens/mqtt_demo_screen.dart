import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/mqtt_service.dart';
import '../services/network_helper.dart';
import '../widgets/device_ip_display.dart';
import '../widgets/mode_selection.dart';
import '../widgets/status_cards.dart';
import '../widgets/broker_section.dart';
import '../widgets/client_section.dart';
import '../widgets/message_log.dart';

class MqttDemoScreen extends StatefulWidget {
  const MqttDemoScreen({super.key});

  @override
  State<MqttDemoScreen> createState() => _MqttDemoScreenState();
}

class _MqttDemoScreenState extends State<MqttDemoScreen> {
  final MqttService _mqttService = MqttService();
  final TextEditingController _brokerIpController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Helper method to log UI interactions
  void _logUI(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    if (kDebugMode) {
      print('[$timestamp] UI: $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _logUI('🎬 Initializing MQTT Demo App');
    _brokerIpController.text = '192.168.1.105'; // Default IP
    _messageController.text = 'Hello, MQTT!';
    _mqttService.addListener(_onMqttServiceChanged);
  }

  void _onMqttServiceChanged() {
    _logUI('📊 MQTT Service state changed - updating UI');
    setState(() {});
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _logUI('🧹 Disposing MQTT Demo App');
    _mqttService.removeListener(_onMqttServiceChanged);
    _mqttService.dispose();
    _brokerIpController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'MQTT Demo',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DeviceIPDisplay(),
            const SizedBox(height: 20),
            ModeSelection(mqttService: _mqttService),
            const SizedBox(height: 20),
            StatusCards(mqttService: _mqttService),
            const SizedBox(height: 20),
            if (_mqttService.currentMode == AppMode.broker) 
              BrokerSection(
                mqttService: _mqttService,
                onStartBroker: _startBroker,
                onStopBroker: _stopBroker,
              ),
            if (_mqttService.currentMode == AppMode.client) 
              ClientSection(
                mqttService: _mqttService,
                brokerIpController: _brokerIpController,
                messageController: _messageController,
                onConnect: _connect,
                onDisconnect: _disconnect,
                onSubscribe: _subscribe,
                onUnsubscribe: _unsubscribe,
                onPublishMessage: _publishMessage,
              ),
            const SizedBox(height: 20),
            MessageLog(
              mqttService: _mqttService,
              scrollController: _scrollController,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _startBroker() async {
    _logUI('🚀 User requested to start MQTT broker');
    final success = await _mqttService.startBroker();
    if (success && mounted) {
      _logUI('✅ Broker started successfully - showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MQTT Broker started successfully')),
      );
    } else if (mounted) {
      _logUI('❌ Broker start failed - showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start MQTT broker')),
      );
    }
  }

  Future<void> _stopBroker() async {
    _logUI('🛑 User requested to stop MQTT broker');
    await _mqttService.stopBroker();
    if (mounted) {
      _logUI('✅ Broker stopped - showing confirmation message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MQTT Broker stopped')),
      );
    }
  }

  Future<void> _connect() async {
    final brokerIp = _brokerIpController.text.trim();
    _logUI('🔌 User requested to connect to broker: $brokerIp');
    
    if (brokerIp.isEmpty) {
      _logUI('⚠️  Empty broker IP - showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter broker IP address')),
      );
      return;
    }
    
    if (!NetworkHelper.isValidIPAddress(brokerIp)) {
      _logUI('⚠️  Invalid IP format - showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address')),
      );
      return;
    }
    
    _logUI('✅ IP validation passed - attempting connection');
    final success = await _mqttService.connect(brokerIp);
    if (success && mounted) {
      _logUI('✅ Connection successful - showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to MQTT broker')),
      );
    } else if (mounted) {
      _logUI('❌ Connection failed - showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to MQTT broker')),
      );
    }
  }

  Future<void> _disconnect() async {
    _logUI('🔌 User requested to disconnect from broker');
    await _mqttService.disconnect();
    if (mounted) {
      _logUI('✅ Disconnection completed - showing confirmation message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected from MQTT broker')),
      );
    }
  }

  Future<void> _subscribe() async {
    _logUI('📡 User requested to subscribe to topic');
    await _mqttService.subscribe();
  }

  Future<void> _unsubscribe() async {
    _logUI('📭 User requested to unsubscribe from topic');
    await _mqttService.unsubscribe();
  }

  Future<void> _publishMessage() async {
    final message = _messageController.text;
    _logUI('📤 User requested to publish message: "$message"');
    await _mqttService.publishMessage(message: message);
  }
}
