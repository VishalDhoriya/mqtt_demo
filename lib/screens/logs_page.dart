import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../widgets/collapsible_message_section.dart';

class LogsPage extends StatefulWidget {
  final MqttService mqttService;

  const LogsPage({
    super.key,
    required this.mqttService,
  });

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedTopic = '';

  @override
  void initState() {
    super.initState();
    widget.mqttService.addListener(_onMqttServiceChanged);
    _messageController.text = 'Hello from host!';
    _selectedTopic = widget.mqttService.defaultTopic;
  }

  @override
  void dispose() {
    widget.mqttService.removeListener(_onMqttServiceChanged);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMqttServiceChanged() {
    if (mounted) {
      setState(() {
        // UI will be updated with real connected clients from mqttService
      });
      
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
  }

  Future<void> _publishMessage() async {
    final message = _messageController.text;
    await widget.mqttService.publishMessage(message: message, topic: _selectedTopic);
  }

  void _onTopicChanged(String? newTopic) {
    if (newTopic != null) {
      setState(() {
        _selectedTopic = newTopic;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.mqttService.isBrokerRunning || widget.mqttService.isConnected) ...[
            const SizedBox(height: 20),
            Expanded(
              child: CollapsibleMessageSection(
                mqttService: widget.mqttService,
                scrollController: _scrollController,
                messageController: _messageController,
                onSend: _publishMessage,
                availableTopics: [
                  widget.mqttService.defaultTopic,
                  widget.mqttService.shareTopic,
                ],
                selectedTopic: _selectedTopic,
                onTopicChanged: _onTopicChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
