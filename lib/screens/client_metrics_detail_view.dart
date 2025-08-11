import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ClientMetricsDetailView extends StatefulWidget {
  final String clientId;
  final Map<String, dynamic> data;
  const ClientMetricsDetailView({Key? key, required this.clientId, required this.data}) : super(key: key);

  @override
  State<ClientMetricsDetailView> createState() => _ClientMetricsDetailViewState();
}

class _ClientMetricsDetailViewState extends State<ClientMetricsDetailView> {
  String selectedMetric = 'cpu';

  @override
  Widget build(BuildContext context) {
  // Extract device name and IP from data
  final deviceName = widget.data['name'] ?? '';
  final ip = widget.data['i'] ?? widget.clientId;
    final cpu = widget.data['c']?.toDouble() ?? 0.0;
    final memory = widget.data['m']?.toDouble() ?? 0.0;
    final battery = widget.data['b']?.toString() ?? 'N/A';
    // For demo, fake data points for the graph
    List<double> cpuPoints = List.generate(30, (i) => cpu + (i % 5 - 2) * 2.0);
    List<double> memoryPoints = List.generate(30, (i) => memory + (i % 5 - 2) * 5.0);
    List<double> batteryPoints = List.generate(30, (i) => double.tryParse(battery.replaceAll('%','')) ?? 0.0);
    List<double> graphPoints;
    String graphLabel;
    String unit;
    if (selectedMetric == 'cpu') {
      graphPoints = cpuPoints;
      graphLabel = 'CPU Usage';
      unit = '%';
    } else if (selectedMetric == 'memory') {
      graphPoints = memoryPoints;
      graphLabel = 'Memory Usage';
      unit = 'MB';
    } else {
      graphPoints = batteryPoints;
      graphLabel = 'Battery Level';
      unit = '%';
    }



    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        return Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ip, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _MetricButton(
                                label: 'CPU',
                                value: '${cpu.toStringAsFixed(1)}%',
                                selected: selectedMetric == 'cpu',
                                onTap: () => setState(() => selectedMetric = 'cpu'),
                              ),
                              _MetricButton(
                                label: 'Memory',
                                value: '${memory.toStringAsFixed(1)} MB',
                                selected: selectedMetric == 'memory',
                                onTap: () => setState(() => selectedMetric = 'memory'),
                              ),
                              _MetricButton(
                                label: 'Battery',
                                value: battery,
                                selected: selectedMetric == 'battery',
                                onTap: () => setState(() => selectedMetric = 'battery'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isNarrow ? 0 : 14),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(graphLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: LineChart(
                                      LineChartData(
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: List.generate(graphPoints.length, (i) => FlSpot(i.toDouble(), graphPoints[i])),
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
                                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                if (value == 0 || value == 100) return const Text('');
                                                return Text('${value.toInt()}$unit', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                              },
                                              reservedSize: 26,
                                              interval: 20,
                                            ),
                                          ),
                                        ),
                                        minX: 0,
                                        maxX: 29,
                                        minY: 0,
                                        maxY: 100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _MetricButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 11)),
            const SizedBox(height: 1),
            Text(value, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
