import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/topic_manager.dart';
import 'topics_page.dart';

class TopicRoomPage extends StatefulWidget {
  final String topic;
  final MqttService mqttService;
  final List<TopicMessage> messages;

  const TopicRoomPage({
    super.key,
    required this.topic,
    required this.mqttService,
    required this.messages,
  });

  @override
  State<TopicRoomPage> createState() => _TopicRoomPageState();
}

class _TopicRoomPageState extends State<TopicRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final TopicManager _topicManager;
  List<MqttMessage> _currentMessages = [];
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _topicManager = widget.mqttService.topicManager;
    _updateMessages();
    _isSubscribed = widget.mqttService.subscribedTopics.contains(widget.topic);
    
    // Listen for real-time updates
    _topicManager.addListener(_onTopicManagerChanged);
    widget.mqttService.addListener(_onMqttServiceChanged);
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _topicManager.removeListener(_onTopicManagerChanged);
    widget.mqttService.removeListener(_onMqttServiceChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateMessages() {
    // Get messages for this topic from TopicManager
    final messagesByTopic = _topicManager.messagesByTopic;
    _currentMessages = messagesByTopic[widget.topic] ?? [];
    
    // Sort by timestamp (oldest first for chat-like display)
    _currentMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void _onTopicManagerChanged() {
    setState(() {
      _updateMessages();
    });
    
    // Auto-scroll to bottom when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onMqttServiceChanged() {
    setState(() {
      _isSubscribed = widget.mqttService.subscribedTopics.contains(widget.topic);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    await widget.mqttService.publishMessage(
      message: message,
      topic: widget.topic,
    );
    
    _messageController.clear();
  }

  Future<void> _toggleSubscription() async {
    if (_isSubscribed) {
      await widget.mqttService.unsubscribeFromTopic(widget.topic);
    } else {
      await widget.mqttService.subscribeToTopic(widget.topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = widget.mqttService.isConnected || widget.mqttService.canPublishFromHost;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              '${_currentMessages.length} ${_currentMessages.length == 1 ? 'message' : 'messages'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Subscribe/Unsubscribe button
          if (widget.mqttService.isConnected)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _toggleSubscription,
                icon: Icon(
                  _isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                  size: 18,
                  color: _isSubscribed ? Colors.green.shade600 : Colors.grey.shade600,
                ),
                label: Text(
                  _isSubscribed ? 'Subscribed' : 'Subscribe',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isSubscribed ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: _isSubscribed ? Colors.green.shade50 : Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          if (!widget.mqttService.isConnected && !widget.mqttService.isBrokerRunning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not connected to MQTT broker. Connect to see real-time messages.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages List
          Expanded(
            child: _currentMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentMessages.length,
                    itemBuilder: (context, index) {
                      final mqttMessage = _currentMessages[index];
                      final topicMessage = TopicMessage(
                        topic: mqttMessage.topic,
                        content: mqttMessage.content,
                        timestamp: mqttMessage.timestamp,
                        sender: mqttMessage.senderName,
                      );
                      return _buildMessageBubble(topicMessage, index);
                    },
                  ),
          ),
          
          // Message Input
          if (canPublish)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
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
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send the first message to this topic',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TopicMessage message, int index) {
    final showTimestamp = index == 0 || 
        (index > 0 && _currentMessages[index - 1].timestamp.difference(message.timestamp).inMinutes.abs() > 5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatMessageTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.sender,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
