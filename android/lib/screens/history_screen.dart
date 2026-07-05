import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/imu_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;

    final grouped = <String, List<HistoryRecord>>{};
    for (final r in history) {
      grouped.putIfAbsent(r.date, () => []).add(r);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppState>().loadHistory(),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(child: Text('暂无训练记录'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dates.length,
              itemBuilder: (ctx, i) {
                final date    = dates[i];
                final records = grouped[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    ),
                    ...records.map((r) {
                      final globalIndex = history.indexOf(r);
                      return _RecordCard(record: r, globalIndex: globalIndex);
                    }),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HistoryRecord record;
  final int globalIndex;
  const _RecordCard({required this.record, required this.globalIndex});

  Color _scoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.red;
  }

  String _fmtDuration(int secs) {
    if (secs < 60) return '$secs秒';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s > 0 ? '$m分$s秒' : '$m分钟';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定删除「${record.action} ${record.count}次」这条记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().deleteHistory(globalIndex);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(record.score);

    return Dismissible(
      key: ValueKey('${record.date}_${record.action}_$globalIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: Text('确定删除「${record.action} ${record.count}次」？'),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(ctx); },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () { confirmed = true; Navigator.pop(ctx); },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (_) => context.read<AppState>().deleteHistory(globalIndex),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              details.globalPosition.dy,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            items: [
              PopupMenuItem(
                onTap: () => _confirmDelete(context),
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          );
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
        /* 折叠状态 */
        leading: CircleAvatar(
          backgroundColor: scoreColor.withValues(alpha: 0.15),
          child: Text(
            record.action.substring(0, 1),
            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(record.action,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '完成 ${record.count} 次'
          '${record.durationSecs > 0 ? '  · ${_fmtDuration(record.durationSecs)}' : ''}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${record.score.toStringAsFixed(0)}分',
            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
          ),
        ),

        /* 展开详情 */
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                /* 数据行 */
                Row(
                  children: [
                    _DetailItem(
                      icon: Icons.timer_outlined,
                      label: '时长',
                      value: record.durationSecs > 0
                          ? _fmtDuration(record.durationSecs) : '-',
                    ),
                    _DetailItem(
                      icon: Icons.speed,
                      label: '频率',
                      value: record.frequency > 0
                          ? '${record.frequency.toStringAsFixed(1)}次/分' : '-',
                    ),
                    _DetailItem(
                      icon: Icons.local_fire_department,
                      label: '消耗',
                      value: record.calories > 0
                          ? '${record.calories.toStringAsFixed(1)}千卡' : '-',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /* 姿态问题 */
                if (record.postureIssues.isNotEmpty) ...[
                  _SectionTitle(
                    icon: Icons.warning_amber_outlined,
                    label: '姿态问题',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 6),
                  ...record.postureIssues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.orange)),
                        Expanded(child: Text(issue, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],

                /* 建议 */
                if (record.suggestions.isNotEmpty) ...[
                  _SectionTitle(
                    icon: Icons.lightbulb_outline,
                    label: '建议',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 6),
                  ...record.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.blue)),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),     // ExpansionTile
        ),   // Card
      ),     // GestureDetector
    );       // Dismissible
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
