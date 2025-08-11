import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Use the same channel name as defined in MainActivity.kt
const platform = MethodChannel('com.example.mqtt_demo/performance');

// This class will hold all the performance data.
class PerformanceData {
  final double cpuUsage;
  final double memoryUsage;
  final String networkUsage;
  final String diskUsage;
  final String batteryLevel;
  final List<double> cpuDataPoints;

  PerformanceData({
    this.cpuUsage = 0.0,
    this.memoryUsage = 0.0,
    this.networkUsage = '...',
    this.diskUsage = '...',
    this.batteryLevel = '...',
    this.cpuDataPoints = const [],
  });
}

// The Singleton Service
class PerformanceService {
  // --- Singleton Setup ---
  PerformanceService._privateConstructor() {
    // Start the timer when the service is first created.
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _updateMetrics());
  }
  static final PerformanceService instance = PerformanceService._privateConstructor();

  // --- State Variables ---
  // These now live here, outside the widget tree.
  Timer? _timer;
  final List<double> _cpuDataPoints = [];
  final int _maxDataPoints = 30;

  Map<String, int> _lastMetrics = {};
  DateTime _lastTimestamp = DateTime.now();
  
  // --- Public Notifier ---
  // This is the magic part. Widgets can listen to this notifier.
  // When we update its .value, all listening widgets will rebuild.
  final ValueNotifier<PerformanceData> notifier = ValueNotifier(PerformanceData());

  // --- Logic ---
  // This is the same logic as before, but it now lives in the service.
  Future<void> _updateMetrics() async {
    try {
      final results = await Future.wait([
        platform.invokeMapMethod<String, int>('getPerformanceMetrics'),
        platform.invokeMethod<double>('getAppMemoryUsageMB'),
        platform.invokeMethod<int>('getBatteryDetails'),
      ]);

      final currentMetrics = results[0] as Map<String, int>;
      final currentMemory = results[1] as double;
      final currentBattery = results[2] as int;
      final now = DateTime.now();
      
      final deltaSeconds = now.difference(_lastTimestamp).inMilliseconds > 0 
          ? now.difference(_lastTimestamp).inMilliseconds / 1000.0 
          : 1.0;

      double cpuUsage = 0.0;
      if (_lastMetrics.containsKey('cpuJiffies') && currentMetrics.containsKey('cpuJiffies')) {
        final cpuJiffiesDiff = currentMetrics['cpuJiffies']! - _lastMetrics['cpuJiffies']!;
        const double clockTicksPerSecond = 100.0;
        final cpuSecondsUsed = cpuJiffiesDiff / clockTicksPerSecond;
        final cpuUsageRatio = cpuSecondsUsed / deltaSeconds;
        cpuUsage = cpuUsageRatio * 100.0;
        
        _cpuDataPoints.add(cpuUsage);
        if (_cpuDataPoints.length > _maxDataPoints) {
          _cpuDataPoints.removeAt(0);
        }
      }

      String networkUsage = '...';
      if (_lastMetrics.containsKey('netRxBytes') && currentMetrics.containsKey('netRxBytes')) {
        final rxDiff = currentMetrics['netRxBytes']! - _lastMetrics['netRxBytes']!;
        final txDiff = currentMetrics['netTxBytes']! - _lastMetrics['netTxBytes']!;
        final totalSpeed = ((rxDiff + txDiff) / deltaSeconds) / 1024;
        networkUsage = '${totalSpeed.toStringAsFixed(1)} KB/s';
      }

      String diskUsage = '...';
      if (_lastMetrics.containsKey('diskReadBytes') && currentMetrics.containsKey('diskReadBytes')) {
        final readDiff = currentMetrics['diskReadBytes']! - _lastMetrics['diskReadBytes']!;
        final writeDiff = currentMetrics['diskWriteBytes']! - _lastMetrics['diskWriteBytes']!;
        final totalSpeed = ((readDiff + writeDiff) / deltaSeconds) / 1024;
        diskUsage = '${totalSpeed.toStringAsFixed(1)} KB/s';
      }

      _lastMetrics = currentMetrics;
      _lastTimestamp = now;

      // Update the notifier with a new data object.
      // This will trigger a rebuild in any listening widgets.
      notifier.value = PerformanceData(
        cpuUsage: cpuUsage,
        memoryUsage: currentMemory,
        networkUsage: networkUsage,
        diskUsage: diskUsage,
        batteryLevel: '$currentBattery%',
        cpuDataPoints: List.from(_cpuDataPoints), // Pass a copy
      );

    } catch (e) {
      print("Failed to fetch performance metrics: $e");
    }
  }

  void dispose() {
    _timer?.cancel();
    notifier.dispose();
  }
}