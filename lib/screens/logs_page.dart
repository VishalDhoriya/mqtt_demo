import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../widgets/message_log.dart';

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
            Text(
              'Send Message',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Topic Selection
            Row(
              children: [
                const Text('Topic:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedTopic,
                  items: [
                    widget.mqttService.defaultTopic,
                    widget.mqttService.shareTopic,
                  ].map((String topic) {
                    return DropdownMenuItem<String>(
                      value: topic,
                      child: Text(topic),
                    );
                  }).toList(),
                  onChanged: _onTopicChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _publishMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _publishMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(
              'Message Log',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Message Log takes remaining space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MessageLog(
                  mqttService: widget.mqttService,
                  scrollController: _scrollController,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
