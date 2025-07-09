import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class MessageLog extends StatefulWidget {
  final MqttService mqttService;
  final ScrollController scrollController;

  const MessageLog({
    super.key,
    required this.mqttService,
    required this.scrollController,
  });

  @override
  State<MessageLog> createState() => _MessageLogState();
}

class _MessageLogState extends State<MessageLog> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
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
    _animationController.value = 1.0; // Start expanded
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
      mainAxisSize: MainAxisSize.min,
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
                    Icons.history,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Messages',
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
        
        // Expandable Messages Content
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
              child: _buildMessageList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (widget.mqttService.messages.isEmpty) {
      return SizedBox(
        height: 80, // Reduced height for empty state
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 24, // Smaller icon
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
              Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 180, // Fixed height container to prevent overflow
        child: ListView.builder(
          controller: widget.scrollController,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: widget.mqttService.messages.length,
          itemBuilder: (context, index) {
            final message = widget.mqttService.messages[index];
            
            // Extract message metadata (sender info or message type)
            String? metadata;
            String displayMessage = message;
            
            // Check if message has metadata prefix like "[Client]:" or "[File]:"
            final metadataMatch = RegExp(r'^\[(.*?)\]:').firstMatch(message);
            if (metadataMatch != null) {
              metadata = metadataMatch.group(1);
              displayMessage = message.substring(metadataMatch.end).trim();
            }
            
            // Detect if message contains an emoji at the beginning
            final hasEmoji = displayMessage.contains(RegExp(r'[\p{Emoji}]', unicode: true));
            final emojiMatch = RegExp(r'([\p{Emoji}])', unicode: true).firstMatch(displayMessage);
            final emoji = emojiMatch?.group(0);
            final messageText = hasEmoji && emoji != null 
                ? displayMessage.replaceFirst(emoji, '') 
                : displayMessage;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: 12,
                    endIndent: 12,
                    color: Colors.grey.shade100,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (metadata != null) 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              metadata,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasEmoji && emoji != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8, top: 2),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              messageText.trim(),
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade800,
                                height: 1.5,
                                letterSpacing: 0.2,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
  }
}
