import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class MessageLog extends StatelessWidget {
  final MqttService mqttService;
  final ScrollController scrollController;

  const MessageLog({
    super.key,
    required this.mqttService,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  'Message Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: mqttService.clearMessages,
                  style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Messages
          Expanded(
            child: mqttService.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Messages will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: mqttService.messages.length,
                    itemBuilder: (context, index) {
                      final message = mqttService.messages[index];
                      final bool isEven = index % 2 == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                        decoration: BoxDecoration(
                          color: isEven ? Colors.transparent : Colors.grey.shade50,
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
