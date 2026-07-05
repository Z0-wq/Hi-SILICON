import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/imu_data.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.liveData;
    final analysis = _RunAnalysis.from(data);

    return Scaffold(
      appBar: AppBar(title: const Text('跑姿分析')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverallCard(analysis: analysis),
          const SizedBox(height: 12),
          _MetricCard(
            title: '躯干前倾角',
            icon: Icons.accessibility_new,
            value: '${data.pitch.abs().toStringAsFixed(1)}°',
            status: analysis.trunkStatus,
            suggestion: analysis.trunkSuggestion,
            color: analysis.trunkColor,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            title: '左右摆动',
            icon: Icons.swap_horiz,
            value: '${data.roll.abs().toStringAsFixed(1)}°',
            status: analysis.swingStatus,
            suggestion: analysis.swingSuggestion,
            color: analysis.swingColor,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            title: '垂直振幅',
            icon: Icons.height,
            value: '${analysis.verticalAmp} mg',
            status: analysis.verticalStatus,
            suggestion: analysis.verticalSuggestion,
            color: analysis.verticalColor,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            title: '冲击力',
            icon: Icons.bolt,
            value: '${analysis.impact} mg',
            status: analysis.impactStatus,
            suggestion: analysis.impactSuggestion,
            color: analysis.impactColor,
          ),
          const SizedBox(height: 12),
          _TipsCard(tips: analysis.tips),
        ],
      ),
    );
  }
}

class _RunAnalysis {
  final String trunkStatus;
  final String trunkSuggestion;
  final Color trunkColor;

  final String swingStatus;
  final String swingSuggestion;
  final Color swingColor;

  final int verticalAmp;
  final String verticalStatus;
  final String verticalSuggestion;
  final Color verticalColor;

  final int impact;
  final String impactStatus;
  final String impactSuggestion;
  final Color impactColor;

  final double overallScore;
  final List<String> tips;

  const _RunAnalysis({
    required this.trunkStatus, required this.trunkSuggestion, required this.trunkColor,
    required this.swingStatus, required this.swingSuggestion, required this.swingColor,
    required this.verticalAmp, required this.verticalStatus, required this.verticalSuggestion, required this.verticalColor,
    required this.impact, required this.impactStatus, required this.impactSuggestion, required this.impactColor,
    required this.overallScore, required this.tips,
  });

  factory _RunAnalysis.from(ImuData d) {
    // 躯干前倾角：pitch 理想范围 5°~15°
    final trunk = d.pitch.abs();
    String trunkStatus; String trunkSuggestion; Color trunkColor;
    if (trunk < 3) {
      trunkStatus = '过于直立'; trunkColor = Colors.orange;
      trunkSuggestion = '身体稍微前倾 5~10°，有助于利用重力推进，减少腿部负担。';
    } else if (trunk <= 15) {
      trunkStatus = '姿态良好'; trunkColor = Colors.green;
      trunkSuggestion = '躯干前倾角度适中，保持当前姿态。';
    } else if (trunk <= 25) {
      trunkStatus = '前倾偏大'; trunkColor = Colors.orange;
      trunkSuggestion = '前倾角度过大，注意收紧核心，避免腰部过度弯曲。';
    } else {
      trunkStatus = '严重前倾'; trunkColor = Colors.red;
      trunkSuggestion = '前倾角度过大，容易导致腰背疲劳，请立即调整姿态。';
    }

    // 左右摆动：roll 理想 < 10°
    final swing = d.roll.abs();
    String swingStatus; String swingSuggestion; Color swingColor;
    if (swing <= 8) {
      swingStatus = '摆动正常'; swingColor = Colors.green;
      swingSuggestion = '左右摆动幅度适中，跑步效率高。';
    } else if (swing <= 15) {
      swingStatus = '摆动偏大'; swingColor = Colors.orange;
      swingSuggestion = '左右摆动偏大，注意保持躯干稳定，收紧核心肌群。';
    } else {
      swingStatus = '摆动过大'; swingColor = Colors.red;
      swingSuggestion = '左右摆动严重，能量损耗大，建议降低速度，专注于直线跑动。';
    }

    // 垂直振幅：accZ 偏离 1g(1000mg) 的幅度
    final vertAmp = (d.accZ - 1000).abs();
    String vertStatus; String vertSuggestion; Color vertColor;
    if (vertAmp < 150) {
      vertStatus = '振幅适中'; vertColor = Colors.green;
      vertSuggestion = '垂直振幅良好，步伐轻盈高效。';
    } else if (vertAmp < 300) {
      vertStatus = '振幅偏大'; vertColor = Colors.orange;
      vertSuggestion = '垂直振幅偏大，尝试缩短步幅、提高步频，减少上下弹跳。';
    } else {
      vertStatus = '振幅过大'; vertColor = Colors.red;
      vertSuggestion = '垂直振幅过大，跑步效率低，建议练习小步快频跑法。';
    }

    // 冲击力：accZ 峰值
    final impact = d.accZ.abs();
    String impactStatus; String impactSuggestion; Color impactColor;
    if (impact < 1500) {
      impactStatus = '冲击适中'; impactColor = Colors.green;
      impactSuggestion = '落地冲击力适中，关节负担小。';
    } else if (impact < 2500) {
      impactStatus = '冲击偏大'; impactColor = Colors.orange;
      impactSuggestion = '落地冲击偏大，建议采用前脚掌或中足落地，减少膝关节压力。';
    } else {
      impactStatus = '冲击过大'; impactColor = Colors.red;
      impactSuggestion = '落地冲击过大，长期可能导致膝关节损伤，请立即调整落地方式。';
    }

    // 综合评分
    int score = 100;
    if (trunkColor == Colors.orange) score -= 10;
    if (trunkColor == Colors.red) score -= 25;
    if (swingColor == Colors.orange) score -= 10;
    if (swingColor == Colors.red) score -= 20;
    if (vertColor == Colors.orange) score -= 8;
    if (vertColor == Colors.red) score -= 15;
    if (impactColor == Colors.orange) score -= 7;
    if (impactColor == Colors.red) score -= 15;

    // 综合建议
    final tips = <String>[];
    if (trunkColor != Colors.green) tips.add('调整躯干前倾角至 5~15°');
    if (swingColor != Colors.green) tips.add('收紧核心，减少左右摆动');
    if (vertColor != Colors.green) tips.add('提高步频至 170~180 步/分，减少弹跳');
    if (impactColor != Colors.green) tips.add('改用中足落地，降低冲击力');
    if (tips.isEmpty) tips.add('跑姿优秀，继续保持！');

    return _RunAnalysis(
      trunkStatus: trunkStatus, trunkSuggestion: trunkSuggestion, trunkColor: trunkColor,
      swingStatus: swingStatus, swingSuggestion: swingSuggestion, swingColor: swingColor,
      verticalAmp: vertAmp, verticalStatus: vertStatus, verticalSuggestion: vertSuggestion, verticalColor: vertColor,
      impact: impact, impactStatus: impactStatus, impactSuggestion: impactSuggestion, impactColor: impactColor,
      overallScore: score.toDouble().clamp(0, 100),
      tips: tips,
    );
  }
}

class _OverallCard extends StatelessWidget {
  final _RunAnalysis analysis;
  const _OverallCard({required this.analysis});

  Color _color(double s) {
    if (s >= 90) return Colors.green;
    if (s >= 70) return Colors.orange;
    return Colors.red;
  }

  String _grade(double s) {
    if (s >= 90) return '跑姿优秀';
    if (s >= 70) return '跑姿良好';
    if (s >= 50) return '需要改善';
    return '跑姿较差';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(analysis.overallScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircularProgressIndicator(
              value: analysis.overallScore / 100,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              strokeWidth: 8,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('跑姿综合评分', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${analysis.overallScore.toInt()} 分',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
                Text(_grade(analysis.overallScore), style: TextStyle(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String status;
  final String suggestion;
  final Color color;

  const _MetricCard({
    required this.title, required this.icon, required this.value,
    required this.status, required this.suggestion, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status, style: TextStyle(color: color, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(suggestion, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  const _TipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Theme.of(context).colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('改善建议', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
