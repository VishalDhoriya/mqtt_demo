import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'message_log.dart';

class CollapsibleMessageSection extends StatefulWidget {
  final MqttService mqttService;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final Function() onSend;
  final List<String> availableTopics;
  final String selectedTopic;
  final Function(String?) onTopicChanged;

  const CollapsibleMessageSection({
    super.key,
    required this.mqttService,
    required this.scrollController,
    required this.messageController,
    required this.onSend,
    required this.availableTopics,
    required this.selectedTopic,
    required this.onTopicChanged,
  });

  @override
  State<CollapsibleMessageSection> createState() => _CollapsibleMessageSectionState();
}

class _CollapsibleMessageSectionState extends State<CollapsibleMessageSection> with SingleTickerProviderStateMixin {
  bool _isExpanded = false; // Changed to false to start collapsed
  late AnimationController _animationController;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _animationController.drive(CurveTween(curve: Curves.easeInOutCubic));
    _animationController.value = 0.0; // Start collapsed (was 1.0)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.chat,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Message Center',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.mqttService.messages.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.mqttService.clearMessages,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    tooltip: 'Clear messages',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5)
                        .animate(_animationController),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Divider
        Divider(height: 1, color: Colors.grey.shade200),
        
        // Expandable Content
        ClipRect(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _heightFactor,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: _animationController,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildMessageCenter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Send Message Section
        // Text(
        //   'Send Message',
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w500,
        //     color: Colors.grey.shade800,
        //   ),
        // ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Topic:', 
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              borderRadius: BorderRadius.circular(11),
              value: widget.selectedTopic,
              items: widget.availableTopics.map((String topic) {
                return DropdownMenuItem<String>(
                  value: topic,
                  child: Text(
                    topic,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: widget.onTopicChanged,
              underline: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.messageController,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.onSend,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(80, 0),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 8),
        
        // Message Log
        // Text(
        //   'Messages',
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w500,
        //     color: Colors.grey.shade800,
        //   ),
        // ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200, // Fixed height to prevent overflow
          child: MessageLog(
            mqttService: widget.mqttService,
            scrollController: widget.scrollController,
          ),
        ),
      ],
    );
  }
}
