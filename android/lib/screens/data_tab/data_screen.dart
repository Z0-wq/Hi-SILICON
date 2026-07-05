import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/imu_data.dart';
import '../../theme.dart';
import 'record_detail_screen.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  String _filter   = 'all';
  bool   _showChart = false;  // false=数字概览，true=曲线图

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final history = state.history;

    final filtered = _filter == 'all' ? history
        : history.where((r) =>
            (_filter == 'pullup' && r.action == '引体向上') ||
            (_filter == 'pushup' && r.action == '俯卧撑')).toList();

    final now      = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2,'0')}';
    final thisMonth = history.where((r) => r.date.startsWith(monthKey)).toList();
    final monthCount = thisMonth.length;
    final monthSecs  = thisMonth.fold(0, (s, r) => s + r.durationSecs);
    final monthScore = thisMonth.isEmpty ? 0.0
        : thisMonth.fold(0.0, (s, r) => s + r.score) / thisMonth.length;

    final grouped = <String, List<HistoryRecord>>{};
    for (final r in filtered) {
      grouped.putIfAbsent(r.date, () => []).add(r);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: kBgGray,
      appBar: AppBar(
        title: const Text('数据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppState>().loadHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          /* 月概览 */
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kGreen, Color(0xFF5BA318)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Text('${now.month}月训练概览',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      /* 切换按钮 */
                      GestureDetector(
                        onTap: () => setState(() => _showChart = !_showChart),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Icon(
                              _showChart ? Icons.grid_view : Icons.show_chart,
                              color: Colors.white, size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showChart ? '数字' : '曲线',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (!_showChart)
                  /* 数字概览 */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MonthStat(label: '训练次数', value: '$monthCount次'),
                        _MonthStat(label: '总时长',
                            value: fmtDurationChinese(monthSecs)),
                        _MonthStat(
                          label: '平均标准率',
                          value: '${monthScore.toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  )
                else
                  /* 曲线图（最近7条记录的count趋势）*/
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _MiniChart(
                      records: history.reversed.take(7).toList().reversed.toList()),
                  ),
              ],
            ),
          ),

          /* 筛选Tab */
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _FilterChip(label: '全部', value: 'all',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              const SizedBox(width: 8),
              _FilterChip(label: '引体向上', value: 'pullup',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
              const SizedBox(width: 8),
              _FilterChip(label: '俯卧撑', value: 'pushup',
                  current: _filter,
                  onTap: (v) => setState(() => _filter = v)),
            ]),
          ),
          const SizedBox(height: 8),

          /* 历史列表 */
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('暂无训练记录',
                    style: TextStyle(color: kTextGray)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dates.length,
                    itemBuilder: (ctx, i) {
                      final date    = dates[i];
                      final records = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 2),
                            child: Text(date,
                              style: const TextStyle(
                                  fontSize: 13, color: kTextGray,
                                  fontWeight: FontWeight.w500)),
                          ),
                          ...records.map((r) {
                            final globalIdx = history.indexOf(r);
                            return _RecordCard(
                              record:      r,
                              globalIndex: globalIdx,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                  RecordDetailScreen(
                                    record: r, index: globalIdx))),
                              onDelete: () async {
                                await context
                                    .read<AppState>()
                                    .deleteHistory(globalIdx);
                              },
                            );
                          }),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/* ── 曲线图（简单折线）──────────────────────────── */
class _MiniChart extends StatelessWidget {
  final List<HistoryRecord> records;
  const _MiniChart({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox(height: 80,
        child: Center(child: Text('暂无数据',
            style: TextStyle(color: Colors.white54))));
    }
    final maxCount = records.map((r) => r.count).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _LinePainter(records: records, maxCount: maxCount),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: records.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('${r.count}',
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          )).toList(),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<HistoryRecord> records;
  final int maxCount;
  _LinePainter({required this.records, required this.maxCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.length < 2) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < records.length; i++) {
      final x = i * size.width / (records.length - 1);
      final y = size.height * 0.85 *
          (1 - records[i].count / (maxCount == 0 ? 1 : maxCount));
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}

/* ── 辅助组件 ────────────────────────────────────── */
class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  const _MonthStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value,
      required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kGreen : kCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? kGreen : Colors.grey.shade300),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : kTextGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HistoryRecord record;
  final int globalIndex;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  const _RecordCard({required this.record, required this.globalIndex,
      required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sc = scoreColor(record.score);
    return Dismissible(
      key: ValueKey('rec_${globalIndex}_${record.date}_${record.action}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 2),
            Text('删除', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        bool ok = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('删除记录'),
            content: Text(
                '确定删除「${record.action} ${record.count}个」这条记录？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () { ok = true; Navigator.pop(ctx); },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        return ok;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapUp: (d) => showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            d.globalPosition.dx, d.globalPosition.dy,
            d.globalPosition.dx, d.globalPosition.dy,
          ),
          items: [
            PopupMenuItem(
              onTap: () async {
                bool ok = false;
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除记录'),
                    content: Text('确定删除「${record.action}」？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消')),
                      TextButton(
                        onPressed: () { ok = true; Navigator.pop(ctx); },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (ok) await onDelete();
              },
              child: const Row(children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('删除', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(
                color: Colors.black12, blurRadius: 4,
                offset: Offset(0, 1))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  record.action == '引体向上'
                      ? Icons.fitness_center : Icons.accessibility_new,
                  color: sc, size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.action,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 15, color: kTextDark)),
                  const SizedBox(height: 3),
                  Text(
                    '${record.count}个'
                    '${record.durationSecs > 0 ? ' · ${fmtDurationChinese(record.durationSecs)}' : ''}'
                    '${record.frequency > 0 ? ' · ${record.frequency.toStringAsFixed(1)}个/分' : ''}',
                    style: const TextStyle(fontSize: 12, color: kTextGray),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${record.score.toStringAsFixed(0)}%',
                style: TextStyle(color: sc,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kTextGray, size: 20),
          ]),
        ),
      ),
    );
  }
}
