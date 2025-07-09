import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../services/network_helper.dart';
import '../services/broker_discovery_service.dart';
import '../widgets/broker_selection_widget.dart';
import '../widgets/message_log.dart';

class JoinSessionScreen extends StatefulWidget {
  final MqttService mqttService;
  final VoidCallback onBackToHome;

  const JoinSessionScreen({
    super.key,
    required this.mqttService,
    required this.onBackToHome,
  });

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final TextEditingController _brokerIpController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BrokerDiscoveryService _discoveryService = BrokerDiscoveryService();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _brokerIpController.text = '192.168.1.105'; // Default IP
    _messageController.text = 'Hello from client!';
    widget.mqttService.addListener(_onMqttServiceChanged);
    widget.mqttService.setMode(AppMode.client);
  }

  @override
  void dispose() {
    widget.mqttService.removeListener(_onMqttServiceChanged);
    _brokerIpController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _discoveryService.dispose();
    super.dispose();
  }

  void _onMqttServiceChanged() {
    if (mounted) {
      setState(() {});
      
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

  Future<void> _connect(String brokerIp) async {
    setState(() {
      _isConnecting = true;
    });

    if (brokerIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter broker IP address')),
      );
      setState(() {
        _isConnecting = false;
      });
      return;
    }
    
    if (!NetworkHelper.isValidIPAddress(brokerIp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address')),
      );
      setState(() {
        _isConnecting = false;
      });
      return;
    }

    final success = await widget.mqttService.connect(brokerIp);
    
    setState(() {
      _isConnecting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to session successfully!')),
      );
      // Auto-subscribe to the default topic
      await widget.mqttService.subscribe();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to session')),
      );
    }
  }

  Future<void> _disconnect() async {
    await widget.mqttService.disconnect();
    widget.onBackToHome();
  }

  Future<void> _publishMessage() async {
    final message = _messageController.text;
    await widget.mqttService.publishMessage(message: message);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Status Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Session',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_isConnecting)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Connecting to session...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          else if (widget.mqttService.isConnected)
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 12),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Connected to ${widget.mqttService.brokerIp}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Find and connect to an available session',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: widget.mqttService.isConnected ? _disconnect : widget.onBackToHome,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.mqttService.isConnected ? 'Disconnect' : 'Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Connection Section
          if (!widget.mqttService.isConnected) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'Available Sessions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  BrokerSelectionWidget(
                    discoveryService: _discoveryService,
                    onBrokerSelected: (brokerIp, port) {
                      _brokerIpController.text = brokerIp;
                      _connect(brokerIp);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                ],
              ),
            ),
          ],

          // Message Controls (when connected)
          if (widget.mqttService.isConnected) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  Text(
                    'Send Message',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ],

          // Message Log
          SizedBox(
            height: 300,
            child: MessageLog(
              mqttService: widget.mqttService,
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }
}
