import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class BrokerSection extends StatelessWidget {
  final MqttService mqttService;
  final VoidCallback onStartBroker;
  final VoidCallback onStopBroker;

  const BrokerSection({
    super.key,
    required this.mqttService,
    required this.onStartBroker,
    required this.onStopBroker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Broker Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: mqttService.isBrokerRunning ? onStopBroker : onStartBroker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: mqttService.isBrokerRunning ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mqttService.isBrokerRunning ? Colors.grey.shade400 : Colors.black,
                  width: 1,
                ),
              ),
              child: Text(
                mqttService.isBrokerRunning ? 'STOP BROKER' : 'START BROKER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mqttService.isBrokerRunning ? Colors.black : Colors.white,
                  letterSpacing: 1,
                ),
              ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Port', '1883'),
                _buildInfoRow('Topic', 'test/topic'),
                _buildInfoRow('QoS', '0 (At most once)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
