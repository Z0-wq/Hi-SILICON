import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../models/imu_data.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buffer = context.watch<AppState>().chartBuffer;
    return Scaffold(
      appBar: AppBar(title: const Text('实时波形')),
      body: buffer.isEmpty
          ? const Center(child: Text('等待数据...'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: '加速度 (mg)',
                  buffer: buffer,
                  lines: [
                    _LineConfig('X', Colors.red, (d) => d.accX.toDouble()),
                    _LineConfig('Y', Colors.green, (d) => d.accY.toDouble()),
                    _LineConfig('Z', Colors.blue, (d) => d.accZ.toDouble()),
                  ],
                  minY: -2000,
                  maxY: 2000,
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: '角速度 (0.1 dps)',
                  buffer: buffer,
                  lines: [
                    _LineConfig('X', Colors.red, (d) => d.gyroX.toDouble()),
                    _LineConfig('Y', Colors.green, (d) => d.gyroY.toDouble()),
                    _LineConfig('Z', Colors.blue, (d) => d.gyroZ.toDouble()),
                  ],
                  minY: -2000,
                  maxY: 2000,
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: '姿态角 (°)',
                  buffer: buffer,
                  lines: [
                    _LineConfig('Roll', Colors.orange, (d) => d.roll),
                    _LineConfig('Pitch', Colors.purple, (d) => d.pitch),
                  ],
                  minY: -180,
                  maxY: 180,
                ),
              ],
            ),
    );
  }
}

class _LineConfig {
  final String label;
  final Color color;
  final double Function(ImuData) getValue;
  const _LineConfig(this.label, this.color, this.getValue);
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<ImuData> buffer;
  final List<_LineConfig> lines;
  final double minY;
  final double maxY;

  const _ChartCard({
    required this.title,
    required this.buffer,
    required this.lines,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  ...lines.map((l) => Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(children: [
                          Container(width: 12, height: 3, color: l.color),
                          const SizedBox(width: 4),
                          Text(l.label, style: const TextStyle(fontSize: 11)),
                        ]),
                      )),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: lines.map((l) {
                    return LineChartBarData(
                      spots: List.generate(buffer.length, (i) =>
                          FlSpot(i.toDouble(), l.getValue(buffer[i]))),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: l.color,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
