import 'package:flutter/material.dart';
import '../../models/imu_data.dart';
import '../../theme.dart';

class RecordDetailScreen extends StatelessWidget {
  final HistoryRecord record;
  final int index;
  const RecordDetailScreen({super.key, required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final sc = scoreColor(record.score);

    return Scaffold(
      backgroundColor: kBgGray,
      appBar: AppBar(
        title: Text(record.action),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成', style: TextStyle(color: kGreen)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /* 成绩大卡 */
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            record.action == '引体向上'
                                ? Icons.fitness_center
                                : Icons.accessibility_new,
                            color: sc, size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.action,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  color: kTextDark)),
                            Text(record.date,
                              style: const TextStyle(
                                  fontSize: 13, color: kTextGray)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${record.score.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold,
                                  color: sc)),
                            Text('标准率',
                              style: const TextStyle(
                                  fontSize: 12, color: kTextGray)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailStat(
                          icon: Icons.sports_score,
                          label: '完成',
                          value: '${record.count}个',
                        ),
                        _DetailStat(
                          icon: Icons.timer_outlined,
                          label: '时长',
                          value: record.durationSecs > 0
                              ? fmtDurationChinese(record.durationSecs) : '-',
                        ),
                        _DetailStat(
                          icon: Icons.speed,
                          label: '频率',
                          value: record.frequency > 0
                              ? '${record.frequency.toStringAsFixed(1)}个/分' : '-',
                        ),
                        _DetailStat(
                          icon: Icons.local_fire_department,
                          label: '消耗',
                          value: record.calories > 0
                              ? '${record.calories.toStringAsFixed(1)}kcal' : '-',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            /* 姿态问题 */
            if (record.postureIssues.isNotEmpty) ...[
              _SectionCard(
                icon: Icons.warning_amber_outlined,
                iconColor: Colors.orange,
                title: '发现问题',
                children: record.postureIssues.map((issue) =>
                  _BulletItem(text: issue, color: Colors.orange)).toList(),
              ),
              const SizedBox(height: 12),
            ],

            /* 建议 */
            if (record.suggestions.isNotEmpty) ...[
              _SectionCard(
                icon: Icons.lightbulb_outline,
                iconColor: kGreen,
                title: '改进建议',
                children: record.suggestions.map((s) =>
                  _BulletItem(text: s, color: kGreen)).toList(),
              ),
              const SizedBox(height: 12),
            ],

            /* 空状态 */
            if (record.postureIssues.isEmpty && record.suggestions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.star, color: kGreen, size: 40),
                      const SizedBox(height: 8),
                      const Text('动作规范，表现优秀！',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600, color: kTextDark)),
                      const SizedBox(height: 4),
                      const Text('继续保持，稳步提升训练量',
                        style: TextStyle(fontSize: 13, color: kTextGray)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: kTextGray, size: 20),
        const SizedBox(height: 4),
        Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold,
              fontSize: 14, color: kTextDark)),
        Text(label,
          style: const TextStyle(fontSize: 11, color: kTextGray)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.icon, required this.iconColor,
      required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(title,
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: iconColor, fontSize: 15)),
            ]),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontSize: 14)),
          Expanded(child: Text(text,
            style: const TextStyle(fontSize: 13, color: kTextDark, height: 1.5))),
        ],
      ),
    );
  }
}
