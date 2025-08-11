import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'; // Import for WidgetsBindingObserver

// Use the same channel name as defined in MainActivity.kt
const platform = MethodChannel('com.example.mqtt_demo/performance');

/// A data class to hold a snapshot of all performance metrics.
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

/// A singleton service that is now lifecycle-aware and uses a dynamic clock speed.
class PerformanceService with WidgetsBindingObserver {
  // --- Singleton Setup ---
  PerformanceService._privateConstructor() {
    init();
  }
  static final PerformanceService instance = PerformanceService._privateConstructor();

  // --- State Variables ---
  Timer? _timer;
  final List<double> _cpuDataPoints = [];
  final int _maxDataPoints = 30;
  
  // This will hold the actual clock tick rate of the device.
  double _clockTicksPerSecond = 100.0; // Start with a safe default.

  Map<String, int> _lastMetrics = {};
  DateTime _lastTimestamp = DateTime.now();
  
  final ValueNotifier<PerformanceData> notifier = ValueNotifier(PerformanceData());

  /// Initializes the service, gets static data, and registers the lifecycle listener.
  Future<void> init() async {
    // Register this service to listen to app lifecycle events.
    WidgetsBinding.instance.addObserver(this);
    
    // Fetch the device's actual clock tick rate once at startup.
    try {
      final int? ticks = await platform.invokeMethod<int>('getClockTicksPerSecond');
      if (ticks != null && ticks > 0) {
        _clockTicksPerSecond = ticks.toDouble();
        print("✅ Successfully fetched device clock ticks per second: $_clockTicksPerSecond");
      }
    } catch (e) {
      print("⚠️ Could not fetch clock ticks, falling back to 100Hz. Error: $e");
    }
    
    // Start the timer now that we are initialized.
    _startTimer();
  }
  
  // --- Lifecycle Management ---
  
  @override
  // This method is called automatically by the Flutter framework.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // The app has come into the foreground.
        print("✅ App resumed, starting performance timer.");
        _startTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // The app is in the background or closing.
        print("⛔️ App paused, stopping performance timer to save battery.");
        _stopTimer();
        break;
      case AppLifecycleState.hidden:
        // This state is not used on Android/iOS, but good practice to handle.
        break;
    }
  }

  void _startTimer() {
    // Prevent multiple timers from running.
    if (_timer?.isActive ?? false) return;
    
    // Update immediately when resuming, then start the periodic timer.
    _updateMetrics();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _updateMetrics());
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  // --- Core Logic ---
  Future<void> _updateMetrics() async {
    try {
      // Fetch all metrics in a single batch, just like before.
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

      double cpuUsage = notifier.value.cpuUsage; // Default to old value
      if (_lastMetrics.containsKey('cpuJiffies') && currentMetrics.containsKey('cpuJiffies')) {
        final cpuJiffiesDiff = currentMetrics['cpuJiffies']! - _lastMetrics['cpuJiffies']!;
        
        // *** This now uses the dynamically fetched clock speed ***
        final cpuSecondsUsed = cpuJiffiesDiff / _clockTicksPerSecond;
        
        final cpuUsageRatio = cpuSecondsUsed / deltaSeconds;
        cpuUsage = cpuUsageRatio * 100.0;
        
        _cpuDataPoints.add(cpuUsage);
        if (_cpuDataPoints.length > _maxDataPoints) {
          _cpuDataPoints.removeAt(0);
        }
      }

      String networkUsage = notifier.value.networkUsage; // Default to old value
      if (_lastMetrics.containsKey('netRxBytes') && currentMetrics.containsKey('netRxBytes')) {
        final rxDiff = currentMetrics['netRxBytes']! - _lastMetrics['netRxBytes']!;
        final txDiff = currentMetrics['netTxBytes']! - _lastMetrics['netTxBytes']!;
        final totalSpeed = ((rxDiff + txDiff) / deltaSeconds) / 1024;
        networkUsage = '${totalSpeed.toStringAsFixed(1)} KB/s';
      }

      String diskUsage = notifier.value.diskUsage; // Default to old value
      if (_lastMetrics.containsKey('diskReadBytes') && currentMetrics.containsKey('diskReadBytes')) {
        final readDiff = currentMetrics['diskReadBytes']! - _lastMetrics['diskReadBytes']!;
        final writeDiff = currentMetrics['diskWriteBytes']! - _lastMetrics['diskWriteBytes']!;
        final totalSpeed = ((readDiff + writeDiff) / deltaSeconds) / 1024;
        diskUsage = '${totalSpeed.toStringAsFixed(1)} KB/s';
      }

      _lastMetrics = currentMetrics;
      _lastTimestamp = now;

      // Update the notifier with a new data object containing all metrics.
      notifier.value = PerformanceData(
        cpuUsage: cpuUsage,
        memoryUsage: currentMemory,
        networkUsage: networkUsage,
        diskUsage: diskUsage,
        batteryLevel: '$currentBattery%',
        cpuDataPoints: List.from(_cpuDataPoints),
      );

    } catch (e) {
      print("Failed to fetch performance metrics: $e");
    }
  }

  void dispose() {
    // Unregister the observer to prevent memory leaks when the service is no longer needed.
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    notifier.dispose();
  }
}