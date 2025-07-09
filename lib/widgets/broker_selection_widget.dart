import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/broker_discovery_service.dart';

/// Widget for selecting MQTT brokers (discovered or manual)
class BrokerSelectionWidget extends StatefulWidget {
  final Function(String host, int port) onBrokerSelected;
  final BrokerDiscoveryService discoveryService;

  const BrokerSelectionWidget({
    super.key,
    required this.onBrokerSelected,
    required this.discoveryService,
  });

  @override
  State<BrokerSelectionWidget> createState() => _BrokerSelectionWidgetState();
}

class _BrokerSelectionWidgetState extends State<BrokerSelectionWidget> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '1883');
  bool _showDiscoverySettings = false;

  @override
  void initState() {
    super.initState();
    // Start discovery when widget is created
    widget.discoveryService.startDiscovery();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with refresh button
        Row(
          children: [
            Text(
              'Discovery Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                widget.discoveryService.refreshDiscovery();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Discovery method selection
        _buildDiscoveryMethodSelection(),
        const SizedBox(height: 16),
        
        // Manual entry form or discovered brokers list
        if (widget.discoveryService.currentMethod == DiscoveryMethod.manual)
          _buildManualEntryForm()
        else
          // Discovered brokers list
          StreamBuilder<List<DiscoveredBroker>>(
            stream: widget.discoveryService.brokersStream,
            builder: (context, snapshot) {
              final brokers = snapshot.data ?? [];
              
              if (brokers.isEmpty) {
                return _buildEmptyState();
              }
              
              return _buildBrokersList(brokers);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          widget.discoveryService.isDiscovering
              ? const CircularProgressIndicator(color: Colors.black)
              : Icon(Icons.search_off, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 8),
          Text(
            widget.discoveryService.isDiscovering
                ? 'Searching for brokers...'
                : 'No brokers found',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Use manual entry below to connect to a specific broker',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBrokersList(List<DiscoveredBroker> brokers) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: brokers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final broker = brokers[index];
          return _buildBrokerTile(broker);
        },
      ),
    );
  }

  Widget _buildBrokerTile(DiscoveredBroker broker) {
    final hasDeviceName = broker.deviceName != null && broker.deviceName!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device name as primary title
            if (hasDeviceName) ...[
              Text(
                broker.deviceName!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],
            // IP address as secondary info
            Text(
              broker.endpoint,
              style: TextStyle(
                color: hasDeviceName ? Colors.grey.shade600 : Colors.black,
                fontSize: hasDeviceName ? 13 : 16,
                fontFamily: 'monospace',
                fontWeight: hasDeviceName ? FontWeight.normal : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            broker.isManual ? 'Manual Entry' : 'Discovered',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ),
        trailing: broker.isManual
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () {
                  widget.discoveryService.removeManualBroker(broker.host, broker.port);
                },
              )
            : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          widget.onBrokerSelected(broker.host, broker.port);
        },
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Host input
        TextField(
          controller: _hostController,
          decoration: const InputDecoration(
            labelText: 'Broker Host/IP',
            hintText: 'e.g., 192.168.1.100',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        
        // Port input
        TextField(
          controller: _portController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Port',
            hintText: '1883',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        
        // Connect button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _connectToManualBroker,
            child: const Text('Connect to Broker'),
          ),
        ),
      ],
    );
  }

  void _connectToManualBroker() {
    final host = _hostController.text.trim();
    final portText = _portController.text.trim();
    
    if (host.isEmpty || portText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both host and port'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }
    
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid port number (1-65535)'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }
    
    widget.onBrokerSelected(host, port);
  }

  Widget _buildDiscoveryMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovery method selection header
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Discovery Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDiscoverySettings = !_showDiscoverySettings;
                  });
                },
                child: Icon(
                  _showDiscoverySettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
          
          // Discovery method buttons (always visible)
          const SizedBox(height: 8),
          _buildDiscoveryMethodButtons(),
          
          // Advanced settings (expandable)
          if (_showDiscoverySettings) ...[
            const SizedBox(height: 8),
            _buildAdvancedDiscoverySettings(),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryMethodButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildDiscoveryMethodButton(
            icon: Icons.broadcast_on_home_outlined,
            label: 'UDP',
            isSelected: widget.discoveryService.currentMethod == DiscoveryMethod.udp,
            onTap: () {
              widget.discoveryService.setDiscoveryMethod(DiscoveryMethod.udp);
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDiscoveryMethodButton(
            icon: Icons.search_outlined,
            label: 'Scan',
            isSelected: widget.discoveryService.currentMethod == DiscoveryMethod.scan,
            onTap: () {
              widget.discoveryService.setDiscoveryMethod(DiscoveryMethod.scan);
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDiscoveryMethodButton(
            icon: Icons.edit_outlined,
            label: 'Manual',
            isSelected: widget.discoveryService.currentMethod == DiscoveryMethod.manual,
            onTap: () {
              widget.discoveryService.setDiscoveryMethod(DiscoveryMethod.manual);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryMethodButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedDiscoverySettings() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDiscoveryDescription(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.discoveryService.currentMethod == DiscoveryMethod.scan) ...[
            Text(
              'Scan Range: ${widget.discoveryService.scanStartPort}-${widget.discoveryService.scanEndPort}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Timeout: ${widget.discoveryService.scanTimeoutMs}ms per port',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ] else if (widget.discoveryService.currentMethod == DiscoveryMethod.udp) ...[
            Text(
              'UDP Port: ${widget.discoveryService.udpPort}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _getDiscoveryDescription() {
    switch (widget.discoveryService.currentMethod) {
      case DiscoveryMethod.udp:
        return 'UDP Discovery listens for broker announcements';
      case DiscoveryMethod.scan:
        return 'Port Scan searches for brokers on common ports';
      case DiscoveryMethod.manual:
        return 'Manual Entry allows you to connect to a specific broker';
    }
  }
}
