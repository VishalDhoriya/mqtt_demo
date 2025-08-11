import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';

class ClientMetricsList extends StatefulWidget {
  final MqttService mqttService;
  const ClientMetricsList({Key? key, required this.mqttService}) : super(key: key);

  @override
  State<ClientMetricsList> createState() => _ClientMetricsListState();
}

class _ClientMetricsListState extends State<ClientMetricsList> {
  final Map<String, Map<String, dynamic>> _clientMetrics = {};
  final Map<String, List<Map<String, dynamic>>> _clientHistory = {};
  String? _selectedClientId;
  String _selectedMetric = 'CPU';

  @override
  void initState() {
    super.initState();
    widget.mqttService.addMessageListener('clients/metrics', _onMetricsMessage);
  }
  
  void _onMetricsMessage(String topic, String message) {
    if (topic == 'clients/metrics') {
      try {
        final data = json.decode(message);
        final clientId = data['i'] ?? 'unknown';
        if (mounted) {
          setState(() {
            _clientMetrics[clientId] = data;
            _clientHistory[clientId] ??= [];
            _clientHistory[clientId]!.add(data);
            if (_clientHistory[clientId]!.length > 20) {
              _clientHistory[clientId]!.removeAt(0);
            }
            if (_selectedClientId == null && _clientMetrics.isNotEmpty) {
              _selectedClientId = clientId;
            }
          });
        }
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    widget.mqttService.removeMessageListener('clients/metrics', _onMetricsMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_clientMetrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No Connected Clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text('Waiting for clients to connect...', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.devices, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text('Connected Clients (${_clientMetrics.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: _clientMetrics.length,
            itemBuilder: (context, index) {
              final entry = _clientMetrics.entries.elementAt(index);
              final clientId = entry.key;
              final data = entry.value;
              final isSelected = _selectedClientId == clientId;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _ClientCard(
                  clientId: clientId,
                  data: data,
                  isSelected: isSelected,
                  selectedMetric: _selectedMetric,
                  history: _clientHistory[clientId] ?? [],
                  onClientSelected: () {
                    setState(() { _selectedClientId = clientId; });
                  },
                  onMetricSelected: (metric) {
                    setState(() { _selectedMetric = metric; });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String clientId;
  final Map<String, dynamic> data;
  final bool isSelected;
  final String selectedMetric;
  final List<Map<String, dynamic>> history;
  final VoidCallback onClientSelected;
  final Function(String) onMetricSelected;

  const _ClientCard({
    required this.clientId,
    required this.data,
    required this.isSelected,
    required this.selectedMetric,
    required this.history,
    required this.onClientSelected,
    required this.onMetricSelected,
  });

  @override
  Widget build(BuildContext context) {
    final deviceName = data['name'] ?? '';
    final deviceIp = data['i'] ?? clientId;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onClientSelected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Device name on the left with ellipsis
                  Expanded(
                    child: Text(
                      deviceName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // IP on the right with ellipsis
                  SizedBox(
                    width: 110,
                    child: Text(
                      deviceIp,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _MetricButton(
                              label: 'CPU',
                              value: '${(data['c'] ?? 0).toString()}%',
                              isSelected: selectedMetric == 'CPU',
                              onTap: () => onMetricSelected('CPU'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _MetricButton(
                              label: 'Memory',
                              value: '${(data['m'] ?? 0).toString()}MB',
                              isSelected: selectedMetric == 'Memory',
                              onTap: () => onMetricSelected('Memory'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _MetricButton(
                              label: 'Battery',
                              value: (data['b'] ?? 'N/A').toString(),
                              isSelected: selectedMetric == 'Battery',
                              onTap: () => onMetricSelected('Battery'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildGraph(history, selectedMetric)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph(List<Map<String, dynamic>> history, String selectedMetric) {
    if (history.isEmpty) {
      return Center(child: Text('No data available', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)));
    }
    List<double> points;
    double minY = 0;
    double maxY = 100;
    String unit = '';
    if (selectedMetric == 'CPU') {
      points = history.map((e) => (e['c'] ?? 0).toDouble()).toList().cast<double>();
      unit = '%';
      maxY = 100;
    } else if (selectedMetric == 'Memory') {
      points = history.map((e) => (e['m'] ?? 0).toDouble()).toList().cast<double>();
      unit = 'MB';
      maxY = (points.isNotEmpty ? points.reduce((a, b) => a > b ? a : b) : 100) * 1.2;
      if (maxY < 100) maxY = 100;
    } else {
      points = history.map((e) {
        final b = e['b'];
        if (b is String && b.endsWith('%')) return double.tryParse(b.replaceAll('%', '')) ?? 0.0;
        return (b ?? 0).toDouble();
      }).toList().cast<double>();
      unit = '%';
      maxY = 100;
    }
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i])),
            isCurved: true,
            color: Colors.black,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.13), Colors.black.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const Text('');
                return Text('${value.toInt()}$unit', style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
              reservedSize: 26,
              interval: maxY / 4,
            ),
          ),
        ),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
      ),
    );
  }
}

class _MetricButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: Offset(0,2))] : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value, 
                style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
