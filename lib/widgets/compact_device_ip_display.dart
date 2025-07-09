import 'package:flutter/material.dart';
import '../services/network_helper.dart';

class CompactDeviceIPDisplay extends StatefulWidget {
  const CompactDeviceIPDisplay({super.key});

  @override
  State<CompactDeviceIPDisplay> createState() => _CompactDeviceIPDisplayState();
}

class _CompactDeviceIPDisplayState extends State<CompactDeviceIPDisplay> {
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device IP Address',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _deviceIpAddress ?? 'Detecting...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: _deviceIpAddress != null ? Colors.black : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _getDeviceIP,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.refresh,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
