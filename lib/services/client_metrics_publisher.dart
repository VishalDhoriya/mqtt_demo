import 'dart:async';
import 'dart:convert';
import '../services/mqtt_client_manager.dart';
import '../services/performance_service.dart';

/// Publishes client metrics to MQTT at a regular interval with a minimal payload.
class ClientMetricsPublisher {
  final MqttClientManager mqttClientManager;
  final PerformanceService performanceService;
  final Duration interval;
  Timer? _timer;

  ClientMetricsPublisher({
    required this.mqttClientManager,
    required this.performanceService,
    this.interval = const Duration(seconds: 5),
  });

  void start() {
    _timer?.cancel();
    print('DEBUG: ClientMetricsPublisher timer started');
    _timer = Timer.periodic(interval, (_) {
      print('DEBUG: Timer tick, calling _collectAndPublish');
      _collectAndPublish();
    });
  }

  void stop() {
    print('DEBUG: ClientMetricsPublisher timer stopped');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _collectAndPublish() async {
    print('DEBUG: _collectAndPublish called');
    try {
      // Collect metrics from performanceService
      final cpu = performanceService.cpuUsage;
      final memory = performanceService.memoryUsage;
      final network = performanceService.networkUsage;
      final disk = performanceService.diskUsage;
      final battery = performanceService.batteryLevel;
      final clientId = mqttClientManager.clientId;
      // Extract IP and device name from clientId
      final parts = clientId.split('_');
      final deviceName = parts.length >= 3 ? parts[2] : 'Unknown';
      final deviceIpDashed = parts.isNotEmpty ? parts.last : '';
      final deviceIp = deviceIpDashed.replaceAll('-', '.');
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Add memory and network fields for broker test
      // Limit network and disk to 2 decimal places (extract number from string, fallback to 0.0)
      double parseValue(String s) {
        final match = RegExp(r"([\d.]+)").firstMatch(s);
        return match != null ? double.parse(double.parse(match.group(1) ?? '0').toStringAsFixed(2)) : 0.0;
      }
      final payload = jsonEncode({
        'i': deviceIp,
        'name': deviceName,
        'c': double.parse(cpu.toStringAsFixed(2)),
        'm': double.parse(memory.toStringAsFixed(2)),
        'b': battery,
        't': timestamp,
      });

      // Publish to MQTT
      await mqttClientManager.publishMessage(
        message: payload,
        topic: 'clients/metrics',
      );
      // Log to terminal for debugging
      // ignore: avoid_print
      print('📤 Metrics published: $payload');
    } catch (e) {
      // Optionally log error
      // ignore: avoid_print
      print('❌ Error publishing metrics: $e');
    }
  }
}
