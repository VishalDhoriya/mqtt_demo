import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class StatusCards extends StatelessWidget {
  final MqttService mqttService;

  const StatusCards({
    super.key,
    required this.mqttService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (mqttService.currentMode == AppMode.broker)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mqttService.isBrokerRunning ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: mqttService.isBrokerRunning ? Colors.black : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mqttService.isBrokerRunning ? Icons.radio_button_on : Icons.radio_button_off,
                      color: mqttService.isBrokerRunning ? Colors.white : Colors.grey.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mqttService.isBrokerRunning ? 'RUNNING' : 'STOPPED',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: mqttService.isBrokerRunning ? Colors.white : Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (mqttService.currentMode == AppMode.client) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mqttService.isConnected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: mqttService.isConnected ? Colors.black : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mqttService.isConnected ? Icons.link : Icons.link_off,
                      color: mqttService.isConnected ? Colors.white : Colors.grey.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mqttService.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: mqttService.isConnected ? Colors.white : Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mqttService.isSubscribed ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: mqttService.isSubscribed ? Colors.black : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mqttService.isSubscribed ? Icons.notifications_active : Icons.notifications_off,
                      color: mqttService.isSubscribed ? Colors.white : Colors.grey.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mqttService.isSubscribed ? 'SUBSCRIBED' : 'NOT SUBSCRIBED',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: mqttService.isSubscribed ? Colors.white : Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
