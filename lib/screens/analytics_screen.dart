import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

// Import your service file
import '../services/performance_service.dart';

// ===========================================================================
// Main Page Widget (No Changes)
// ===========================================================================
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<bool> _selectedMode = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              _selectedMode[0] ? 'Analytics' : 'Explorer',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const Spacer(),
            _CoolToggle(
              selectedIndex: _selectedMode[0] ? 0 : 1,
              onChanged: (index) {
                setState(() {
                  _selectedMode = [index == 0, index == 1];
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _selectedMode[0]
          ?  AnalyticsDashboard()
          : const FilesystemExplorer(),
    );
  }
}

class _CoolToggle extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onChanged;
  const _CoolToggle({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CoolToggleButton(
            text: 'Analytics',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _CoolToggleButton(
            text: 'Explorer',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _CoolToggleButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _CoolToggleButton({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Analytics Dashboard Widget
// ===========================================================================
class AnalyticsDashboard extends StatelessWidget {
   AnalyticsDashboard({Key? key}) : super(key: key);

  final PerformanceService performanceService = PerformanceService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PerformanceData>(
      valueListenable: performanceService.notifier,
      builder: (context, data, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          children: [
            // Top compact metrics bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricText(label: 'CPU', value: '${data.cpuUsage.toStringAsFixed(1)}%'),
                  _VerticalDivider(),
                  _MetricText(label: 'Memory', value: '${data.memoryUsage.toStringAsFixed(1)} MB'),
                  _VerticalDivider(),
                  _MetricText(label: 'Network', value: data.networkUsage),
                  _VerticalDivider(),
                  _MetricText(label: 'Disk', value: data.diskUsage),
                  _VerticalDivider(),
                  _MetricText(label: 'Battery', value: data.batteryLevel),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // CPU Usage Line Chart
            CpuLineChart(dataPoints: data.cpuDataPoints),
            
            // --- The "Connected Clients" section has been removed ---
          ],
        );
      },
    );
  }
}

// ===========================================================================
// CPU LINE CHART WIDGET
// ===========================================================================
class CpuLineChart extends StatelessWidget {
  final List<double> dataPoints;
  const CpuLineChart({Key? key, required this.dataPoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double maxVal = dataPoints.isEmpty ? 100 : dataPoints.reduce(max);
    final double yAxisMax = (maxVal * 1.25).ceilToDouble().clamp(100, 800);

    return AspectRatio(
      aspectRatio: 2.8, // Shorter and wider chart
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 24, right: 16, bottom: 6),
          child: dataPoints.length < 2
            ? const Center(child: Text("Monitoring CPU...", style: TextStyle(color: Colors.grey)))
            : LineChart(
                LineChartData(
                  lineBarsData: [_lineBarData()],
                  gridData: _gridData(yAxisMax),
                  borderData: FlBorderData(show: false),
                  titlesData: _titlesData(yAxisMax),
                  minX: 0,
                  maxX: 29,
                  minY: 0,
                  maxY: yAxisMax,
                ),
              ),
        ),
      ),
    );
  }

  LineChartBarData _lineBarData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.black,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  FlTitlesData _titlesData(double yAxisMax) => FlTitlesData(
    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value == 0 || value >= yAxisMax) return const Text('');
          return Text(
            '   ${value.toInt()}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          );
        },
        // *** CHANGED: Increased reservedSize for more padding ***
        reservedSize: 30,
        // margin: 12,
        interval: yAxisMax / 4,
      ),
    ),
  );

  FlGridData _gridData(double yAxisMax) => FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: yAxisMax / 3,
  );
}

// --- Helper and Filesystem Explorer Widgets (No changes below this line) ---

class _MetricText extends StatelessWidget {
  final String label;
  final String value;
  const _MetricText({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade300,
    );
  }
}

class FilesystemExplorer extends StatefulWidget {
  const FilesystemExplorer({Key? key}) : super(key: key);
  @override
  _FilesystemExplorerState createState() => _FilesystemExplorerState();
}

class _FilesystemExplorerState extends State<FilesystemExplorer> {
  final _pathController = TextEditingController(text: '/proc/self/');
  List<Map<String, dynamic>> _directoryContent = [];
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listDirectory();
  }
  
  Future<void> _listDirectory({String? newPath}) async {
    final String currentPath = newPath ?? _pathController.text;
    if (newPath != null) { _pathController.text = currentPath; }
    _clearResults();
    if(mounted) setState(() { _isLoading = true; });
    try {
      final List<dynamic>? result = await platform.invokeMethod('listDirectoryWithPermissions', {'path': currentPath});
      if (result != null) {
        final List<Map<String, dynamic>> typedResult = result.map((item) => Map<String, dynamic>.from(item)).toList();
        typedResult.sort((a, b) {
          if (a['isDirectory'] != b['isDirectory']) return a['isDirectory'] ? -1 : 1;
          return (a['name'] as String).compareTo(b['name'] as String);
        });
        if (mounted) setState(() { _directoryContent = typedResult; });
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() { _errorMessage = "Failed to list directory.\nError: ${e.message}"; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  
  Future<void> _readFileContent(String filePath) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AlertDialog(title: Text("Reading File..."), content: Center(child: CircularProgressIndicator())));
    String content;
    try {
      content = await platform.invokeMethod('getProcFileContent', {'path': filePath}) ?? "No content returned.";
    } on PlatformException catch (e) {
      content = "Error reading file:\n\n${e.message}";
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(p.basename(filePath)), content: SingleChildScrollView(child: SelectableText(content)), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Close"))]));
  }

  void _clearResults() {
    if (mounted) setState(() { _directoryContent = []; _errorMessage = ''; });
  }

  void _goUp() {
    if (_pathController.text.trim() == '/') return;
    String parentPath = p.dirname(_pathController.text);
    _listDirectory(newPath: parentPath);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: 'Path',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (path) => _listDirectory(newPath: path),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: _goUp,
                tooltip: 'Up',
                padding: const EdgeInsets.only(left: 4),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_errorMessage.isNotEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13))));
    }
    if (_directoryContent.isEmpty && !_isLoading) {
      return const Center(child: Text('Empty or inaccessible.', style: TextStyle(fontSize: 13)));
    }
    return ListView.separated(
      itemCount: _directoryContent.length,
      separatorBuilder: (context, idx) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final item = _directoryContent[index];
        final bool isDirectory = item['isDirectory'];
        return ListTile(
          dense: true,
          leading: Icon(isDirectory ? Icons.folder_rounded : Icons.article_outlined, size: 20),
          title: Text(item['name'], style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          subtitle: _buildPermissionChips(item),
          onTap: () => isDirectory ? _listDirectory(newPath: item['path']) : _readFileContent(item['path']),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        );
      },
    );
  }

  Widget _buildPermissionChips(Map<String, dynamic> item) {
    return Row(
      children: [
        _PermChip(label: 'R', enabled: item['canRead'] as bool),
        _PermChip(label: 'W', enabled: item['canWrite'] as bool),
        _PermChip(label: 'X', enabled: item['canExecute'] as bool),
      ],
    );
  }
}

class _PermChip extends StatelessWidget {
  final String label;
  final bool enabled;
  const _PermChip({required this.label, required this.enabled});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: enabled ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: enabled ? Colors.green.shade900 : Colors.red.shade900)),
    );
  }
}