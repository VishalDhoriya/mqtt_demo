import 'package:flutter/material.dart';
import '../services/network_helper.dart';

class DeviceIPDisplay extends StatefulWidget {
  const DeviceIPDisplay({super.key});

  @override
  State<DeviceIPDisplay> createState() => _DeviceIPDisplayState();
}

class _DeviceIPDisplayState extends State<DeviceIPDisplay> {
  String? _deviceIpAddress;

  @override
  void initState() {
    super.initState();
    _getDeviceIP();
  }

  void _getDeviceIP() async {
    String? ip = await NetworkHelper.getDeviceIPAddress();
    if (mounted) {
      setState(() {
        _deviceIpAddress = ip;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.device_hub,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Device IP Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _getDeviceIP,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _deviceIpAddress ?? 'Detecting...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: _deviceIpAddress != null ? Colors.black : Colors.grey.shade600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _deviceIpAddress != null 
                ? 'Share this IP with client devices' 
                : 'Scanning network interfaces...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
