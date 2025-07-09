import 'dart:async';
import 'package:flutter/foundation.dart';

/// A single MQTT message with metadata
class MqttMessage {
  final String topic;
  final String content;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final MessageType type;

  MqttMessage({
    required this.topic,
    required this.content,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    this.type = MessageType.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'senderName': senderName,
      'type': type.toString(),
    };
  }

  factory MqttMessage.fromJson(Map<String, dynamic> json) {
    return MqttMessage(
      topic: json['topic'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
      senderName: json['senderName'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.user,
      ),
    );
  }
}

enum MessageType {
  user,
  system,
  file,
  notification,
}

/// Topic information with metadata
class TopicInfo {
  final String name;
  final String displayName;
  final String description;
  final bool isDefault;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int messageCount;
  final bool isSubscribed;

  TopicInfo({
    required this.name,
    required this.displayName,
    required this.description,
    this.isDefault = false,
    this.isSystem = false,
    required this.createdAt,
    required this.lastActivity,
    this.messageCount = 0,
    this.isSubscribed = false,
  });

  TopicInfo copyWith({
    String? name,
    String? displayName,
    String? description,
    bool? isDefault,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? lastActivity,
    int? messageCount,
    bool? isSubscribed,
  }) {
    return TopicInfo(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      messageCount: messageCount ?? this.messageCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Centralized topic and message management service
class TopicManager extends ChangeNotifier {
  // Private data storage
  final Map<String, List<MqttMessage>> _messagesByTopic = {};
  final Map<String, TopicInfo> _topics = {};
  final Set<String> _subscribedTopics = {};
  
  // Stream controllers for real-time updates
  final StreamController<Map<String, List<MqttMessage>>> _messagesController =
      StreamController<Map<String, List<MqttMessage>>>.broadcast();
  final StreamController<Map<String, TopicInfo>> _topicsController =
      StreamController<Map<String, TopicInfo>>.broadcast();
  final StreamController<MqttMessage> _newMessageController =
      StreamController<MqttMessage>.broadcast();

  // Configuration - SINGLE PLACE TO MANAGE ALL TOPICS
  static const Map<String, Map<String, dynamic>> _predefinedTopics = {
    // Main communication topics
    'test/topic': {
      'displayName': 'General Chat',
      'description': 'Default topic for general MQTT conversations',
      'isDefault': true,
      'isSystem': false,
    },
    'share/topic': {
      'displayName': 'File Sharing',
      'description': 'Topic for sharing files between devices',
      'isDefault': false,
      'isSystem': true,
    },
    
    // System/connection topics  
    'client/connect': {
      'displayName': 'Client Connections',
      'description': 'Notifications when clients connect to broker',
      'isDefault': false,
      'isSystem': true,
    },
    'client/disconnect': {
      'displayName': 'Client Disconnections', 
      'description': 'Notifications when clients disconnect from broker',
      'isDefault': false,
      'isSystem': true,
    },
    
    // ADD NEW TOPICS HERE - This is the single place to manage topics!
    // 'your/new/topic': {
    //   'displayName': 'Your Topic Name',
    //   'description': 'Description of your topic',
    //   'isDefault': false,
    //   'isSystem': false,
    // },
  };

  TopicManager() {
    _initializePredefinedTopics();
  }

  // Getters for external access
  Map<String, List<MqttMessage>> get messagesByTopic => Map.unmodifiable(_messagesByTopic);
  Map<String, TopicInfo> get topics => Map.unmodifiable(_topics);
  Set<String> get subscribedTopics => Set.unmodifiable(_subscribedTopics);
  List<String> get allTopicNames => _topics.keys.toList()..sort();
  List<String> get defaultTopics => _topics.values.where((t) => t.isDefault).map((t) => t.name).toList();
  List<String> get systemTopics => _topics.values.where((t) => t.isSystem).map((t) => t.name).toList();
  
  // Streams for real-time updates
  Stream<Map<String, List<MqttMessage>>> get messagesStream => _messagesController.stream;
  Stream<Map<String, TopicInfo>> get topicsStream => _topicsController.stream;
  Stream<MqttMessage> get newMessageStream => _newMessageController.stream;

  /// Initialize predefined topics
  void _initializePredefinedTopics() {
    final now = DateTime.now();
    
    _predefinedTopics.forEach((topicName, config) {
      _topics[topicName] = TopicInfo(
        name: topicName,
        displayName: config['displayName'],
        description: config['description'],
        isDefault: config['isDefault'],
        isSystem: config['isSystem'],
        createdAt: now,
        lastActivity: now,
      );
      _messagesByTopic[topicName] = [];
    });
    
    debugPrint('[TopicManager] Initialized ${_topics.length} predefined topics');
  }

  /// Add a new message to a topic
  void addMessage({
    required String topic,
    required String content,
    required String senderId,
    String? senderName,
    MessageType type = MessageType.user,
  }) {
    final message = MqttMessage(
      topic: topic,
      content: content,
      timestamp: DateTime.now(),
      senderId: senderId,
      senderName: senderName ?? 'Unknown',
      type: type,
    );

    // Ensure topic exists
    _ensureTopicExists(topic);
    
    // Add message
    _messagesByTopic[topic]!.add(message);
    
    // Update topic info
    _topics[topic] = _topics[topic]!.copyWith(
      lastActivity: message.timestamp,
      messageCount: _messagesByTopic[topic]!.length,
    );

    // Notify listeners
    _messagesController.add(Map.unmodifiable(_messagesByTopic));
    _topicsController.add(Map.unmodifiable(_topics));
    _newMessageController.add(message);
    notifyListeners();

    debugPrint('[TopicManager] Added message to topic: $topic (${_messagesByTopic[topic]!.length} total messages)');
  }

  /// Ensure a topic exists, create if it doesn't
  void _ensureTopicExists(String topicName) {
    if (!_topics.containsKey(topicName)) {
      final now = DateTime.now();
      _topics[topicName] = TopicInfo(
        name: topicName,
        displayName: _generateDisplayName(topicName),
        description: 'Auto-discovered topic',
        isDefault: false,
        isSystem: false,
        createdAt: now,
        lastActivity: now,
      );
      _messagesByTopic[topicName] = [];
      
      debugPrint('[TopicManager] Auto-created topic: $topicName');
    }
  }

  /// Generate a user-friendly display name from topic name
  String _generateDisplayName(String topicName) {
    // Convert "some/topic/name" to "Some Topic Name"
    return topicName
        .split('/')
        .map((part) => part.split('_').map((word) => 
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' '))
        .join(' / ');
  }

  /// Subscribe to a topic
  void subscribeTopic(String topicName) {
    _subscribedTopics.add(topicName);
    _ensureTopicExists(topicName);
    
    _topics[topicName] = _topics[topicName]!.copyWith(isSubscribed: true);
    _topicsController.add(Map.unmodifiable(_topics));
    notifyListeners();
    
    debugPrint('[TopicManager] Subscribed to topic: $topicName');
  }

  /// Unsubscribe from a topic
  void unsubscribeTopic(String topicName) {
    _subscribedTopics.remove(topicName);
    
    if (_topics.containsKey(topicName)) {
      _topics[topicName] = _topics[topicName]!.copyWith(isSubscribed: false);
      _topicsController.add(Map.unmodifiable(_topics));
      notifyListeners();
    }
    
    debugPrint('[TopicManager] Unsubscribed from topic: $topicName');
  }

  /// Get messages for a specific topic
  List<MqttMessage> getMessagesForTopic(String topicName) {
    return List.unmodifiable(_messagesByTopic[topicName] ?? []);
  }

  /// Get topic info
  TopicInfo? getTopicInfo(String topicName) {
    return _topics[topicName];
  }

  /// Get the latest message for a topic
  MqttMessage? getLatestMessage(String topicName) {
    final messages = _messagesByTopic[topicName];
    return messages?.isNotEmpty == true ? messages!.last : null;
  }

  /// Clear all messages for a topic
  void clearTopicMessages(String topicName) {
    if (_messagesByTopic.containsKey(topicName)) {
      _messagesByTopic[topicName]!.clear();
      
      if (_topics.containsKey(topicName)) {
        _topics[topicName] = _topics[topicName]!.copyWith(messageCount: 0);
      }
      
      _messagesController.add(Map.unmodifiable(_messagesByTopic));
      _topicsController.add(Map.unmodifiable(_topics));
      notifyListeners();
      
      debugPrint('[TopicManager] Cleared messages for topic: $topicName');
    }
  }

  /// Clear all messages from all topics
  void clearAllMessages() {
    for (final topicName in _messagesByTopic.keys) {
      _messagesByTopic[topicName]!.clear();
      if (_topics.containsKey(topicName)) {
        _topics[topicName] = _topics[topicName]!.copyWith(messageCount: 0);
      }
    }
    
    _messagesController.add(Map.unmodifiable(_messagesByTopic));
    _topicsController.add(Map.unmodifiable(_topics));
    notifyListeners();
    
    debugPrint('[TopicManager] Cleared all messages from all topics');
  }

  /// Remove a topic completely (if it's not a predefined topic)
  void removeTopic(String topicName) {
    if (_predefinedTopics.containsKey(topicName)) {
      debugPrint('[TopicManager] Cannot remove predefined topic: $topicName');
      return;
    }
    
    _topics.remove(topicName);
    _messagesByTopic.remove(topicName);
    _subscribedTopics.remove(topicName);
    
    _messagesController.add(Map.unmodifiable(_messagesByTopic));
    _topicsController.add(Map.unmodifiable(_topics));
    notifyListeners();
    
    debugPrint('[TopicManager] Removed topic: $topicName');
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final totalMessages = _messagesByTopic.values.fold<int>(0, (sum, messages) => sum + messages.length);
    final totalTopics = _topics.length;
    final subscribedCount = _subscribedTopics.length;
    final systemTopicsCount = _topics.values.where((t) => t.isSystem).length;
    
    return {
      'totalTopics': totalTopics,
      'totalMessages': totalMessages,
      'subscribedTopics': subscribedCount,
      'systemTopics': systemTopicsCount,
      'defaultTopics': _topics.values.where((t) => t.isDefault).length,
    };
  }

  @override
  void dispose() {
    _messagesController.close();
    _topicsController.close();
    _newMessageController.close();
    super.dispose();
  }
}
