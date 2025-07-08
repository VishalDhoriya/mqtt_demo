import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class ModeSelection extends StatelessWidget {
  final MqttService mqttService;

  const ModeSelection({
    super.key,
    required this.mqttService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Select Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => mqttService.setMode(AppMode.broker),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: mqttService.currentMode == AppMode.broker 
                          ? Colors.black 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: mqttService.currentMode == AppMode.broker 
                            ? Colors.black 
                            : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'BROKER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mqttService.currentMode == AppMode.broker 
                            ? Colors.white 
                            : Colors.grey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => mqttService.setMode(AppMode.client),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: mqttService.currentMode == AppMode.client 
                          ? Colors.black 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: mqttService.currentMode == AppMode.client 
                            ? Colors.black 
                            : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'CLIENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mqttService.currentMode == AppMode.client 
                            ? Colors.white 
                            : Colors.grey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
