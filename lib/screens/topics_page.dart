import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/topic_manager.dart';
import 'topic_room_page.dart';

class TopicsPage extends StatefulWidget {
  final MqttService mqttService;

  const TopicsPage({
    super.key,
    required this.mqttService,
  });

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  late final TopicManager _topicManager;
  Map<String, TopicInfo> _topics = {};
  Map<String, List<MqttMessage>> _messagesByTopic = {};

  @override
  void initState() {
    super.initState();
    _topicManager = widget.mqttService.topicManager;
    _loadTopicData();
    
    // Listen to TopicManager updates
    _topicManager.addListener(_onTopicManagerChanged);
    widget.mqttService.addListener(_onMqttServiceChanged);
  }

  @override
  void dispose() {
    _topicManager.removeListener(_onTopicManagerChanged);
    widget.mqttService.removeListener(_onMqttServiceChanged);
    super.dispose();
  }

  void _loadTopicData() {
    _topics = _topicManager.topics;
    _messagesByTopic = _topicManager.messagesByTopic;
  }

  void _onTopicManagerChanged() {
    setState(() {
      _loadTopicData();
    });
  }

  void _onMqttServiceChanged() {
    setState(() {
      // This handles general MQTT service changes
    });
  }

  void _navigateToTopicRoom(String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TopicRoomPage(
          topic: topic,
          mqttService: widget.mqttService,
          messages: _messagesByTopic[topic]?.map((msg) => TopicMessage(
            topic: msg.topic,
            content: msg.content,
            timestamp: msg.timestamp,
            sender: msg.senderName,
          )).toList() ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedTopics = _topics.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.topic_outlined, size: 24),
              const SizedBox(width: 8),
              const Text(
                'MQTT Topics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sortedTopics.length} topics',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Join topic rooms to see all messages published to each MQTT topic',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Topics List
          Expanded(
            child: sortedTopics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: sortedTopics.length,
                    itemBuilder: (context, index) {
                      final topic = sortedTopics[index];
                      final topicInfo = _topics[topic]!;
                      final messages = _messagesByTopic[topic] ?? [];
                      final isSubscribed = widget.mqttService.subscribedTopics.contains(topic);
                      final lastMessage = messages.isNotEmpty ? messages.first : null;
                      
                      return _buildTopicCard(
                        topic: topic,
                        messageCount: topicInfo.messageCount,
                        isSubscribed: isSubscribed,
                        lastMessage: lastMessage != null ? TopicMessage(
                          topic: lastMessage.topic,
                          content: lastMessage.content,
                          timestamp: lastMessage.timestamp,
                          sender: lastMessage.senderName,
                        ) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Topics Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.mqttService.isConnected || widget.mqttService.isBrokerRunning
                ? 'Start sending messages to see topics appear'
                : 'Connect to a broker or start one to see topics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard({
    required String topic,
    required int messageCount,
    required bool isSubscribed,
    TopicMessage? lastMessage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSubscribed ? Colors.green.shade200 : Colors.grey.shade200,
          width: isSubscribed ? 2 : 1,
        ),          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _navigateToTopicRoom(topic),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic Header
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 20,
                      color: isSubscribed ? Colors.green.shade600 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topic,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSubscribed ? Colors.green.shade700 : Colors.black,
                        ),
                      ),
                    ),
                    if (isSubscribed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'SUBSCRIBED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Message Info
                Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$messageCount ${messageCount == 1 ? 'message' : 'messages'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (lastMessage != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(lastMessage.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Last Message Preview
                if (lastMessage != null && lastMessage.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lastMessage.content.length > 50
                                ? '${lastMessage.content.substring(0, 50)}...'
                                : lastMessage.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class TopicMessage {
  final String topic;
  final String content;
  final DateTime timestamp;
  final String sender;

  TopicMessage({
    required this.topic,
    required this.content,
    required this.timestamp,
    required this.sender,
  });
}
