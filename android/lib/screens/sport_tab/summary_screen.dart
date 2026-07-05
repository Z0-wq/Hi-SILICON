import 'package:flutter/material.dart';
import '../../models/imu_data.dart';
import '../../theme.dart';
import '../data_tab/record_detail_screen.dart';

class SummaryScreen extends StatefulWidget {
  final HistoryRecord? record;
  const SummaryScreen({super.key, required this.record});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final saved  = record != null;

    return Scaffold(
      backgroundColor: kBgGray,
      body: SafeArea(
        child: Column(
          children: [
            /* 顶部完成动画 */
            Container(
              color: kCardWhite,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: saved ? kGreen : Colors.grey,
                      ),
                      child: Icon(
                        saved ? Icons.check : Icons.error_outline,
                        color: Colors.white, size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    saved ? '训练完成！' : '训练结束',
                    style: const TextStyle(fontSize: 24,
                        fontWeight: FontWeight.bold, color: kTextDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    saved ? '记录已保存' : '保存失败，请检查连接',
                    style: TextStyle(
                      fontSize: 13,
                      color: saved ? kTextGray : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /* 成绩快览 */
            if (record != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SumStat(label: '完成', value: '${record.count}个'),
                        _SumStat(
                          label: '时长',
                          value: fmtDurationChinese(record.durationSecs),
                        ),
                        _SumStat(
                          label: '标准率',
                          value: '${record.score.toStringAsFixed(0)}%',
                          valueColor: scoreColor(record.score),
                        ),
                        _SumStat(
                          label: '消耗',
                          value: '${record.calories.toStringAsFixed(1)}kcal',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            /* 按钮区 */
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kGreen),
                        foregroundColor: kGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('完成'),
                    ),
                  ),
                  if (record != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordDetailScreen(
                                record: record, index: -1),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: kGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('查看数据'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SumStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.bold,
            color: valueColor ?? kTextDark,
          )),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextGray)),
      ],
    );
  }
}
