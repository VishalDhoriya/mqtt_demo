import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Discovery method for finding MQTT brokers
enum DiscoveryMethod {
  udp,    // UDP broadcast discovery
  scan,   // Port scanning (brute force)
  manual, // Manual broker entry
}

/// Represents a discovered MQTT broker
class DiscoveredBroker {
  final String name;
  final String host;
  final int port;
  final String? type;
  final DateTime discoveredAt;
  final bool isLocal;
  final bool isManual;
  final String? deviceName;

  DiscoveredBroker({
    required this.name,
    required this.host,
    required this.port,
    this.type,
    required this.discoveredAt,
    this.isLocal = false,
    this.isManual = false,
    this.deviceName,
  });

  String get displayName => deviceName ?? (name.isEmpty ? host : name);
  String get endpoint => '$host:$port';

  @override
  String toString() => 'DiscoveredBroker(name: $name, host: $host, port: $port, deviceName: $deviceName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredBroker &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => host.hashCode ^ port.hashCode;
}

/// Service for discovering MQTT brokers using multiple discovery methods
class BrokerDiscoveryService {
  static const Duration _refreshInterval = Duration(seconds: 30);
  static const int _broadcastPort = 5555; // UDP port for broker announcements
  static const int _scanStartPort = 1883;
  static const int _scanEndPort = 1884;
  static const int _scanTimeoutMs = 1000;

  final List<DiscoveredBroker> _discoveredBrokers = [];
  final StreamController<List<DiscoveredBroker>> _brokersController =
      StreamController<List<DiscoveredBroker>>.broadcast();

  Timer? _refreshTimer;
  bool _isDiscovering = false;
  RawDatagramSocket? _socket;
  DiscoveryMethod _currentMethod = DiscoveryMethod.udp;

  /// Stream of discovered brokers
  Stream<List<DiscoveredBroker>> get brokersStream => _brokersController.stream;

  /// Current list of discovered brokers
  List<DiscoveredBroker> get brokers => List.unmodifiable(_discoveredBrokers);

  /// Whether discovery is currently active
  bool get isDiscovering => _isDiscovering;

  /// Current discovery method
  DiscoveryMethod get currentMethod => _currentMethod;

  /// UDP port for broadcasting
  int get udpPort => _broadcastPort;

  /// Scan start port
  int get scanStartPort => _scanStartPort;

  /// Scan end port
  int get scanEndPort => _scanEndPort;

  /// Scan timeout in milliseconds
  int get scanTimeoutMs => _scanTimeoutMs;

  /// Start discovering MQTT brokers
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    debugPrint('[BrokerDiscovery] Starting ${_currentMethod.name} discovery...');
    _isDiscovering = true;
    
    try {
      switch (_currentMethod) {
        case DiscoveryMethod.udp:
          await _startUdpListener();
          break;
        case DiscoveryMethod.scan:
          await _startPortScanning();
          break;
        case DiscoveryMethod.manual:
          // Manual method doesn't need automatic discovery
          _isDiscovering = false;
          return;
      }
      _startPeriodicRefresh();
    } catch (e) {
      debugPrint('[BrokerDiscovery] Failed to start discovery: $e');
      _isDiscovering = false;
      rethrow;
    }
  }

  /// Stop discovering MQTT brokers
  void stopDiscovery() {
    if (!_isDiscovering) return;

    debugPrint('[BrokerDiscovery] Stopping UDP broadcast discovery...');
    _isDiscovering = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _socket?.close();
    _socket = null;
  }

  /// Manually refresh the discovery
  Future<void> refreshDiscovery() async {
    if (!_isDiscovering) return;
    
    debugPrint('[BrokerDiscovery] Manually refreshing discovery...');
    // Clear old discoveries but keep manual entries
    _discoveredBrokers.removeWhere((broker) => !broker.isManual);
    _notifyBrokersChanged();
  }

  /// Add a broker manually (for manual IP input)
  Future<void> addManualBroker(String host, int port, {String? name}) async {
    final deviceName = await _getDeviceName();
    final broker = DiscoveredBroker(
      name: name ?? 'Manual Entry',
      host: host,
      port: port,
      discoveredAt: DateTime.now(),
      isLocal: false,
      isManual: true,
      deviceName: deviceName,
    );

    _addBroker(broker);
    _notifyBrokersChanged();
  }

  /// Remove a manually added broker
  void removeManualBroker(String host, int port) {
    _discoveredBrokers.removeWhere((broker) => 
        broker.host == host && 
        broker.port == port && 
        broker.isManual);
    _notifyBrokersChanged();
  }

  /// Set the discovery method
  Future<void> setDiscoveryMethod(DiscoveryMethod method) async {
    if (_currentMethod == method) return;
    
    debugPrint('[BrokerDiscovery] Switching discovery method to: $method');
    _currentMethod = method;
    
    if (_isDiscovering) {
      // Restart discovery with new method
      stopDiscovery();
      await startDiscovery();
    }
  }

  /// Start UDP listener for broker announcements
  Future<void> _startUdpListener() async {
    try {
      debugPrint('[BrokerDiscovery] Starting UDP listener on port $_broadcastPort...');
      
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleUdpMessage(datagram);
          }
        }
      });
      
      debugPrint('[BrokerDiscovery] UDP listener started successfully');
      
    } catch (e) {
      debugPrint('[BrokerDiscovery] Failed to start UDP listener: $e');
      rethrow;
    }
  }

  /// Handle incoming UDP broadcast messages
  void _handleUdpMessage(Datagram datagram) {
    try {
      final message = String.fromCharCodes(datagram.data);
      final data = jsonDecode(message);
      
      if (data['type'] == 'mqtt-broker-announcement') {
        final broker = DiscoveredBroker(
          name: data['brokerName'] ?? 'MQTT Broker',
          host: datagram.address.address,
          port: data['port'] ?? 1883,
          discoveredAt: DateTime.now(),
          isLocal: true,
          isManual: false,
          deviceName: data['deviceName'],
        );
        
        _addBroker(broker);
        _notifyBrokersChanged();
        
        debugPrint('[BrokerDiscovery] Received broker announcement from ${broker.deviceName ?? datagram.address.address}:${broker.port}');
      }
    } catch (e) {
      debugPrint('[BrokerDiscovery] Error handling UDP message: $e');
    }
  }

  /// Start port scanning discovery
  Future<void> _startPortScanning() async {
    debugPrint('[BrokerDiscovery] Starting port scanning...');
    
    try {
      // Get local network interfaces
      final interfaces = await NetworkInterface.list();
      final subnets = <String>{};
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // Extract subnet (e.g., 192.168.1.0/24)
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              subnets.add(subnet);
            }
          }
        }
      }
      
      // Scan each subnet
      for (final subnet in subnets) {
        _scanSubnet(subnet);
      }
    } catch (e) {
      debugPrint('[BrokerDiscovery] Error starting port scanning: $e');
    }
  }

  /// Scan a subnet for MQTT brokers
  void _scanSubnet(String subnet) async {
    debugPrint('[BrokerDiscovery] Scanning subnet: $subnet.0/24');
    
    final scanFutures = <Future<void>>[];
    
    // Scan IPs 1-254 in the subnet
    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      
      // Scan each port in the range
      for (int port = _scanStartPort; port <= _scanEndPort; port++) {
        final future = _scanPort(ip, port);
        scanFutures.add(future);
      }
    }
    
    // Wait for all scans to complete (but don't block the UI)
    Future.wait(scanFutures).then((_) {
      debugPrint('[BrokerDiscovery] Completed scanning subnet: $subnet.0/24');
    }).catchError((error) {
      debugPrint('[BrokerDiscovery] Error scanning subnet $subnet.0/24: $error');
    });
  }

  /// Scan a specific IP and port for MQTT broker
  Future<void> _scanPort(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: _scanTimeoutMs),
      );
      
      // Successfully connected - likely an MQTT broker
      await socket.close();
      
      final deviceName = await _getDeviceName();
      final broker = DiscoveredBroker(
        name: 'MQTT Broker',
        host: ip,
        port: port,
        discoveredAt: DateTime.now(),
        isLocal: true,
        isManual: false,
        deviceName: deviceName,
      );
      
      _addBroker(broker);
      _notifyBrokersChanged();
      
      debugPrint('[BrokerDiscovery] Found broker at $ip:$port');
    } catch (e) {
      // Connection failed - not an MQTT broker or unreachable
      // This is expected for most IPs, so don't log
    }
  }

  /// Get device name for this device
  Future<String?> _getDeviceName() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('hostname', []);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('hostname', []);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      }
      return null;
    } catch (e) {
      debugPrint('[BrokerDiscovery] Error getting device name: $e');
      return null;
    }
  }

  /// Start periodic refresh of discovery
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_isDiscovering) {
        // For UDP discovery, we just clear stale entries periodically
        // Active brokers will keep announcing themselves
        _clearStaleEntries();
      }
    });
  }

  /// Clear stale broker entries (older than 2 minutes)
  void _clearStaleEntries() {
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2));
    final removedCount = _discoveredBrokers.length;
    
    _discoveredBrokers.removeWhere((broker) => 
        !broker.isManual && broker.discoveredAt.isBefore(cutoffTime));
    
    final newCount = _discoveredBrokers.length;
    if (removedCount != newCount) {
      debugPrint('[BrokerDiscovery] Removed ${removedCount - newCount} stale broker entries');
      _notifyBrokersChanged();
    }
  }

  /// Add a broker to the list (avoiding duplicates)
  void _addBroker(DiscoveredBroker broker) {
    final existingIndex = _discoveredBrokers.indexWhere(
      (existing) => existing.host == broker.host && existing.port == broker.port,
    );
    
    if (existingIndex >= 0) {
      // Update existing broker
      _discoveredBrokers[existingIndex] = broker;
    } else {
      // Add new broker
      _discoveredBrokers.add(broker);
    }
  }

  /// Notify listeners of broker changes
  void _notifyBrokersChanged() {
    if (!_brokersController.isClosed) {
      _brokersController.add(brokers);
    }
  }

  /// Dispose resources
  void dispose() {
    stopDiscovery();
    _brokersController.close();
  }
}
