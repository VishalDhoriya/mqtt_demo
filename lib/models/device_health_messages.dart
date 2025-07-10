/// Device Health Monitoring Message Formats
/// 
/// Optimized for mobile-only WiFi testbed with minimal MQTT payloads.
/// All devices are mobile phones on the same WiFi network.
/// MQTT broker runs on mobile device with limited capacity.
/// 
/// Priority Levels:
/// - CRITICAL: Essential for testbed operation
/// - HIGH: Important for monitoring and reliability
/// 
/// Design Constraints:
/// - Mobile devices only (Android/iOS)
/// - Same WiFi network only
/// - Minimal payload sizes for mobile MQTT broker
/// - Essential data only

import 'dart:convert';

/// Base class for all device health messages
abstract class DeviceHealthMessage {
  final String deviceId;
  final DateTime timestamp;
  final String messageType;

  DeviceHealthMessage({
    required this.deviceId,
    required this.messageType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson();
  String toMqttMessage() => jsonEncode(toJson());
}

// =============================================================================
// CRITICAL PRIORITY TOPICS
// =============================================================================

/// Device registration message for topic: testbed/device/{device_id}/register
/// CRITICAL - Minimal device info for mobile testbed with coordination support
class DeviceRegistrationMessage extends DeviceHealthMessage {
  final String deviceName;
  final String osType; // Android, iOS
  final int ramGb; // Rounded to nearest GB
  final int batteryPercent;
  final String wifiName; // WiFi network name for verification
  final String role; // coord (coordinator), work (worker), idle

  DeviceRegistrationMessage({
    required String deviceId,
    required this.deviceName,
    required this.osType,
    required this.ramGb,
    required this.batteryPercent,
    required this.wifiName,
    this.role = 'idle', // Default to idle until assigned
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'register',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'name': deviceName,
      'os': osType,
      'ram': ramGb,
      'bat': batteryPercent,
      'wifi': wifiName,
      'role': role,
    };
  }

  factory DeviceRegistrationMessage.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationMessage(
      deviceId: json['id'],
      deviceName: json['name'],
      osType: json['os'],
      ramGb: json['ram'],
      batteryPercent: json['bat'],
      wifiName: json['wifi'],
      role: json['role'] ?? 'idle',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }
}

/// Network status message for topic: testbed/device/{device_id}/network/status  
/// CRITICAL - WiFi-only network monitoring for mobile testbed
class NetworkStatusMessage extends DeviceHealthMessage {
  final bool connected; // WiFi connection status
  final int signalPercent; // WiFi signal 0-100%
  final int latencyMs; // Rounded ping time
  final String wifiName; // WiFi network name

  NetworkStatusMessage({
    required String deviceId,
    required this.connected,
    required this.signalPercent,
    required this.latencyMs,
    required this.wifiName,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'network',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'conn': connected,
      'sig': signalPercent,
      'lat': latencyMs,
      'wifi': wifiName,
    };
  }

  factory NetworkStatusMessage.fromJson(Map<String, dynamic> json) {
    return NetworkStatusMessage(
      deviceId: json['id'],
      connected: json['conn'],
      signalPercent: json['sig'],
      latencyMs: json['lat'],
      wifiName: json['wifi'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }
}

// =============================================================================
// HIGH PRIORITY TOPICS
// =============================================================================

/// Device heartbeat message for topic: testbed/device/{device_id}/heartbeat
/// HIGH PRIORITY - Minimal liveness monitoring for mobile devices
class DeviceHeartbeatMessage extends DeviceHealthMessage {
  final String status; // ok, warn, error
  final int batteryPercent;

  DeviceHeartbeatMessage({
    required String deviceId,
    required this.status,
    required this.batteryPercent,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'beat',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'stat': status,
      'bat': batteryPercent,
    };
  }

  factory DeviceHeartbeatMessage.fromJson(Map<String, dynamic> json) {
    return DeviceHeartbeatMessage(
      deviceId: json['id'],
      status: json['stat'],
      batteryPercent: json['bat'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }
}

/// System resource usage for topic: testbed/device/{device_id}/system/resources
/// HIGH PRIORITY - Minimal resource monitoring for mobile devices
class SystemResourceMessage extends DeviceHealthMessage {
  final int cpuPercent; // 0-100, rounded
  final int memoryPercent; // 0-100, calculated percentage
  final int batteryPercent; // 0-100
  final int tempCelsius; // Rounded temperature

  SystemResourceMessage({
    required String deviceId,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.batteryPercent,
    required this.tempCelsius,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'resources',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'cpu': cpuPercent,
      'mem': memoryPercent,
      'bat': batteryPercent,
      'temp': tempCelsius,
    };
  }

  factory SystemResourceMessage.fromJson(Map<String, dynamic> json) {
    return SystemResourceMessage(
      deviceId: json['id'],
      cpuPercent: json['cpu'],
      memoryPercent: json['mem'],
      batteryPercent: json['bat'],
      tempCelsius: json['temp'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }

  // Convenience getters
  bool get isLowBattery => batteryPercent < 20;
  bool get isHighCpu => cpuPercent > 80;
  bool get isHighMemory => memoryPercent > 85;
  bool get isOverheating => tempCelsius > 45; // Mobile device threshold
}

/// Device status message for topic: testbed/device/{device_id}/status/health
/// HIGH PRIORITY - Simplified health status for mobile testbed with coordination
class DeviceStatusMessage extends DeviceHealthMessage {
  final String health; // ok, warn, error
  final String activity; // idle, busy, coord (coordinating)
  final bool available; // available for tasks
  final String? cluster; // cluster/room ID (null if not in cluster)
  final String? coordBy; // coordinator device ID (null if coordinator or idle)

  DeviceStatusMessage({
    required String deviceId,
    required this.health,
    required this.activity,
    required this.available,
    this.cluster,
    this.coordBy,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'status',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'health': health,
      'act': activity,
      'avail': available,
    };
    
    // Only add cluster fields if they exist (keep payload minimal)
    if (cluster != null) json['cluster'] = cluster!;
    if (coordBy != null) json['coord'] = coordBy!;
    
    return json;
  }

  factory DeviceStatusMessage.fromJson(Map<String, dynamic> json) {
    return DeviceStatusMessage(
      deviceId: json['id'],
      health: json['health'],
      activity: json['act'],
      available: json['avail'],
      cluster: json['cluster'],
      coordBy: json['coord'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }
}

/// Cluster coordination message for topic: testbed/cluster/{cluster_id}/coord
/// HIGH PRIORITY - Minimal cluster coordination tracking for federated learning
class ClusterCoordinationMessage extends DeviceHealthMessage {
  final String clusterId; // cluster/room identifier  
  final String taskId; // current task being worked on
  final String coordId; // coordinator device ID
  final List<String> workers; // worker device IDs in this cluster
  final String status; // active, paused, complete

  ClusterCoordinationMessage({
    required String deviceId, // coordinator's device ID
    required this.clusterId,
    required this.taskId,
    required this.coordId,
    required this.workers,
    required this.status,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'cluster',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'cluster': clusterId,
      'task': taskId,
      'coord': coordId,
      'workers': workers,
      'stat': status,
    };
  }

  factory ClusterCoordinationMessage.fromJson(Map<String, dynamic> json) {
    return ClusterCoordinationMessage(
      deviceId: json['id'],
      clusterId: json['cluster'],
      taskId: json['task'],
      coordId: json['coord'],
      workers: List<String>.from(json['workers']),
      status: json['stat'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }

  // Convenience getters
  int get workerCount => workers.length;
  bool get isActive => status == 'active';
  bool get isComplete => status == 'complete';
}

/// Cluster overview message for topic: testbed/clusters/overview
/// ANALYTICS - Overall cluster landscape for dashboard visualization
class ClusterOverviewMessage extends DeviceHealthMessage {
  final List<String> activeClusters; // List of active cluster IDs
  final Map<String, String> clusterCoordinators; // cluster_id -> coordinator_id
  final Map<String, int> clusterSizes; // cluster_id -> worker_count
  final int totalDevices; // Total devices in testbed
  final int availableDevices; // Devices not in any cluster

  ClusterOverviewMessage({
    required String deviceId, // System/broker device ID
    required this.activeClusters,
    required this.clusterCoordinators,
    required this.clusterSizes,
    required this.totalDevices,
    required this.availableDevices,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'overview',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'clusters': activeClusters,
      'coords': clusterCoordinators,
      'sizes': clusterSizes,
      'total': totalDevices,
      'avail': availableDevices,
    };
  }

  factory ClusterOverviewMessage.fromJson(Map<String, dynamic> json) {
    return ClusterOverviewMessage(
      deviceId: json['id'],
      activeClusters: List<String>.from(json['clusters']),
      clusterCoordinators: Map<String, String>.from(json['coords']),
      clusterSizes: Map<String, int>.from(json['sizes']),
      totalDevices: json['total'],
      availableDevices: json['avail'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }

  // Convenience getters
  int get clusterCount => activeClusters.length;
  int get assignedDevices => totalDevices - availableDevices;
  double get utilizationRate => totalDevices > 0 ? assignedDevices / totalDevices : 0.0;
}

/// Task progress message for topic: testbed/task/{task_id}/progress
/// ANALYTICS - Task execution monitoring for federated learning
class TaskProgressMessage extends DeviceHealthMessage {
  final String taskId; // Task identifier
  final String clusterId; // Associated cluster ID
  final String phase; // init, training, sync, complete
  final int progressPercent; // 0-100
  final int completedWorkers; // Number of workers that completed current phase
  final int totalWorkers; // Total workers in cluster
  final Map<String, dynamic>? metrics; // Optional task-specific metrics

  TaskProgressMessage({
    required String deviceId, // Coordinator device ID
    required this.taskId,
    required this.clusterId,
    required this.phase,
    required this.progressPercent,
    required this.completedWorkers,
    required this.totalWorkers,
    this.metrics,
    DateTime? timestamp,
  }) : super(
          deviceId: deviceId,
          messageType: 'progress',
          timestamp: timestamp,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = {
      'id': deviceId,
      'type': messageType,
      'time': timestamp.millisecondsSinceEpoch,
      'task': taskId,
      'cluster': clusterId,
      'phase': phase,
      'prog': progressPercent,
      'done': completedWorkers,
      'total': totalWorkers,
    };
    
    // Only add metrics if they exist
    if (metrics != null && metrics!.isNotEmpty) {
      json['metrics'] = metrics!;
    }
    
    return json;
  }

  factory TaskProgressMessage.fromJson(Map<String, dynamic> json) {
    return TaskProgressMessage(
      deviceId: json['id'],
      taskId: json['task'],
      clusterId: json['cluster'],
      phase: json['phase'],
      progressPercent: json['prog'],
      completedWorkers: json['done'],
      totalWorkers: json['total'],
      metrics: json['metrics'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['time']),
    );
  }

  // Convenience getters
  bool get isComplete => phase == 'complete';
  bool get allWorkersComplete => completedWorkers >= totalWorkers;
  double get completionRate => totalWorkers > 0 ? completedWorkers / totalWorkers : 0.0;
}

// =============================================================================
// TOPIC DEFINITIONS
// =============================================================================

/// Static class containing device health topic definitions optimized for mobile testbed
class DeviceHealthTopics {
  // CRITICAL Topics - Essential for mobile testbed operation
  static const String deviceRegister = 'testbed/device/{device_id}/register';
  static const String networkStatus = 'testbed/device/{device_id}/network/status';
  
  // HIGH PRIORITY Topics - Important for mobile device monitoring
  static const String deviceHeartbeat = 'testbed/device/{device_id}/heartbeat';
  static const String systemResources = 'testbed/device/{device_id}/system/resources';
  static const String deviceStatus = 'testbed/device/{device_id}/status/health';
  
  // COORDINATION Topics - For cluster/room management
  static const String clusterCoordination = 'testbed/cluster/{cluster_id}/coord';
  
  // ENHANCED ANALYTICS Topics - For detailed cluster monitoring
  static const String clusterStatus = 'testbed/cluster/{cluster_id}/status';
  static const String clusterMembers = 'testbed/cluster/{cluster_id}/members';
  static const String allClusters = 'testbed/clusters/overview';
  static const String coordinatorCommands = 'testbed/coordinator/{coord_id}/commands';
  static const String taskProgress = 'testbed/task/{task_id}/progress';
  
  /// Get actual topic name with device ID substituted
  static String getTopicForDevice(String topicTemplate, String deviceId) {
    return topicTemplate.replaceAll('{device_id}', deviceId);
  }
  
  /// Get actual topic name with cluster ID substituted
  static String getTopicForCluster(String topicTemplate, String clusterId) {
    return topicTemplate.replaceAll('{cluster_id}', clusterId);
  }
  
  /// Get actual topic name with coordinator ID substituted
  static String getTopicForCoordinator(String topicTemplate, String coordId) {
    return topicTemplate.replaceAll('{coord_id}', coordId);
  }
  
  /// Get actual topic name with task ID substituted
  static String getTopicForTask(String topicTemplate, String taskId) {
    return topicTemplate.replaceAll('{task_id}', taskId);
  }
  
  /// Get all topic templates for mobile testbed
  static List<String> getAllTopics() {
    return [
      deviceRegister,
      networkStatus,
      deviceHeartbeat,
      systemResources,
      deviceStatus,
      clusterCoordination,
      clusterStatus,
      clusterMembers,
      allClusters,
      coordinatorCommands,
      taskProgress,
    ];
  }
  
  /// Get critical topics for mobile testbed
  static List<String> getCriticalTopics() {
    return [deviceRegister, networkStatus];
  }
  
  /// Get high priority topics for mobile monitoring
  static List<String> getHighPriorityTopics() {
    return [deviceHeartbeat, systemResources, deviceStatus];
  }
  
  /// Get coordination topics for cluster management
  static List<String> getCoordinationTopics() {
    return [
      clusterCoordination,
      clusterStatus,
      clusterMembers,
      allClusters,
      coordinatorCommands,
      taskProgress,
    ];
  }
  
  /// Get analytics topics for dashboard visualization
  static List<String> getAnalyticsTopics() {
    return [
      clusterStatus,
      clusterMembers,
      allClusters,
      taskProgress,
    ];
  }
}

// =============================================================================
// USAGE EXAMPLES
// =============================================================================

/// Example usage and helper functions optimized for mobile testbed
class DeviceHealthMessageExamples {
  
  /// Example: Create a minimal device registration message
  static DeviceRegistrationMessage createSampleRegistration(String deviceId) {
    return DeviceRegistrationMessage(
      deviceId: deviceId,
      deviceName: 'Mobile-Device-01',
      osType: 'Android',
      ramGb: 8,
      batteryPercent: 85,
      wifiName: 'TestLab-WiFi',
    );
  }
  
  /// Example: Create a minimal heartbeat message
  static DeviceHeartbeatMessage createSampleHeartbeat(String deviceId) {
    return DeviceHeartbeatMessage(
      deviceId: deviceId,
      status: 'ok',
      batteryPercent: 75,
    );
  }
  
  /// Example: Create a minimal system resources message
  static SystemResourceMessage createSampleResources(String deviceId) {
    return SystemResourceMessage(
      deviceId: deviceId,
      cpuPercent: 35,
      memoryPercent: 60,
      batteryPercent: 80,
      tempCelsius: 40,
    );
  }
  
  /// Example: Create a minimal network status message
  static NetworkStatusMessage createSampleNetworkStatus(String deviceId) {
    return NetworkStatusMessage(
      deviceId: deviceId,
      connected: true,
      signalPercent: 85,
      latencyMs: 12,
      wifiName: 'TestLab-WiFi',
    );
  }
  
  /// Example: Create a minimal device status message
  static DeviceStatusMessage createSampleStatus(String deviceId) {
    return DeviceStatusMessage(
      deviceId: deviceId,
      health: 'ok',
      activity: 'idle',
      available: true,
    );
  }
  
  /// Example: Create a coordinator registration message
  static DeviceRegistrationMessage createCoordinatorRegistration(String deviceId) {
    return DeviceRegistrationMessage(
      deviceId: deviceId,
      deviceName: 'Coordinator-01',
      osType: 'Android',
      ramGb: 8,
      batteryPercent: 90,
      wifiName: 'TestLab-WiFi',
      role: 'coord', // Coordinator role
    );
  }
  
  /// Example: Create a worker device status in a cluster
  static DeviceStatusMessage createWorkerInCluster(String deviceId, String clusterId, String coordId) {
    return DeviceStatusMessage(
      deviceId: deviceId,
      health: 'ok',
      activity: 'busy',
      available: false,
      cluster: clusterId,
      coordBy: coordId,
    );
  }
  
  /// Example: Create a cluster coordination message
  static ClusterCoordinationMessage createClusterCoordination(
    String coordId, 
    String clusterId, 
    List<String> workerIds
  ) {
    return ClusterCoordinationMessage(
      deviceId: coordId,
      clusterId: clusterId,
      taskId: 'federated_learning_${DateTime.now().millisecondsSinceEpoch}',
      coordId: coordId,
      workers: workerIds,
      status: 'active',
    );
  }
  
  /// Example: Create cluster overview for analytics dashboard
  static ClusterOverviewMessage createClusterOverview() {
    return ClusterOverviewMessage(
      deviceId: 'system_broker',
      activeClusters: ['room_A', 'room_B'],
      clusterCoordinators: {
        'room_A': 'coord_device_1',
        'room_B': 'coord_device_2',
      },
      clusterSizes: {
        'room_A': 4,
        'room_B': 4,
      },
      totalDevices: 10,
      availableDevices: 2,
    );
  }
  
  /// Generate a typical device ID for mobile testbed
  static String generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'mobile_$timestamp';
  }
  
  /// Calculate WiFi signal percentage from dBm (for conversion)
  static int signalDbmToPercent(double dbm) {
    if (dbm >= -30) return 100;
    if (dbm <= -90) return 0;
    return ((dbm + 90) * 100 / 60).round();
  }
}
