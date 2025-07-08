import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class ClientSection extends StatelessWidget {
  final MqttService mqttService;
  final TextEditingController brokerIpController;
  final TextEditingController messageController;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onSubscribe;
  final VoidCallback onUnsubscribe;
  final VoidCallback onPublishMessage;

  const ClientSection({
    super.key,
    required this.mqttService,
    required this.brokerIpController,
    required this.messageController,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSubscribe,
    required this.onUnsubscribe,
    required this.onPublishMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Client Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text(
                  'Connection Info',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the BROKER device\'s IP address below',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  '(This device\'s IP is shown at the top)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: brokerIpController,
            decoration: InputDecoration(
              labelText: 'Broker IP Address',
              labelStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              hintText: 'e.g., 192.168.1.105',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
              prefixIcon: Icon(
                Icons.router,
                color: Colors.grey.shade600,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            enabled: !mqttService.isConnected,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: mqttService.isConnected ? onDisconnect : onConnect,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: mqttService.isConnected ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mqttService.isConnected ? Colors.grey.shade400 : Colors.black,
                  width: 1,
                ),
              ),
              child: Text(
                mqttService.isConnected ? 'DISCONNECT' : 'CONNECT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mqttService.isConnected ? Colors.black : Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          if (mqttService.isConnected) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: mqttService.isSubscribed ? onUnsubscribe : onSubscribe,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: mqttService.isSubscribed ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: mqttService.isSubscribed ? Colors.grey.shade400 : Colors.black,
                    width: 1,
                  ),
                ),
                child: Text(
                  mqttService.isSubscribed ? 'UNSUBSCRIBE' : 'SUBSCRIBE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: mqttService.isSubscribed ? Colors.black : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      prefixIcon: Icon(
                        Icons.message,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onPublishMessage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: const Text(
                      'PUBLISH',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
