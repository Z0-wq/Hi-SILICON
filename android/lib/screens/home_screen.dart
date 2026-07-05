import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clockTimer;
  int _elapsedSecs = 0;

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _elapsedSecs = 0;
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSecs++);
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  state.connected ? Icons.wifi : Icons.wifi_off,
                  color: state.connected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  state.connected ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 13,
                    color: state.connected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isTraining
          ? _TrainingView(
              elapsedSecs: _elapsedSecs,
              fmt: _fmt,
              onPause: () {
                context.read<AppState>().pauseTraining();
              },
              onResume: () {
                context.read<AppState>().resumeTraining();
              },
              onFinish: () async {
                _stopClock();
                final appState = context.read<AppState>();
                final record = await appState.finishTraining();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                      record != null ? '训练记录已保存' : '保存失败，请检查连接')),
                );
              },
            )
          : _ModeSelectView(
              onStart: () {
                context.read<AppState>().startTraining();
                _startClock();
              },
            ),
    );
  }
}

/* ─── 模式选择页 ───────────────────────────────────────────────── */
class _ModeSelectView extends StatelessWidget {
  final VoidCallback onStart;
  const _ModeSelectView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final modes = [
      {'key': 'pullup', 'label': '引体向上', 'icon': Icons.fitness_center,
       'desc': '背部、二头肌训练'},
      {'key': 'pushup', 'label': '俯卧撑', 'icon': Icons.accessibility_new,
       'desc': '胸部、三头肌训练'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择运动模式',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: modes.map((m) {
              final isSelected = state.currentMode == m['key'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ModeCard(
                    label: m['label'] as String,
                    desc: m['desc'] as String,
                    icon: m['icon'] as IconData,
                    isSelected: isSelected,
                    onTap: () => context.read<AppState>().switchMode(m['key'] as String),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          /* GO 按钮 */
          Center(
            child: GestureDetector(
              onTap: state.connected ? onStart : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.connected ? Colors.green : Colors.grey.shade300,
                  boxShadow: state.connected
                      ? [BoxShadow(color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 20, spreadRadius: 4)]
                      : [],
                ),
                child: const Center(
                  child: Text('GO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    )),
                ),
              ),
            ),
          ),
          if (!state.connected) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text('请先连接设备', style: TextStyle(color: Colors.red))),
          ],
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.desc, required this.icon,
      required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/* ─── 训练中页 ──────────────────────────────────────────────────── */
class _TrainingView extends StatefulWidget {
  final int elapsedSecs;
  final String Function(int) fmt;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final Future<void> Function() onFinish;
  const _TrainingView({
    required this.elapsedSecs,
    required this.fmt,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  @override
  State<_TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<_TrainingView>
    with SingleTickerProviderStateMixin {
  double _stopProgress = 0.0;
  Timer? _stopTimer;

  void _startHoldStop() {
    _stopProgress  = 0.0;
    _stopTimer?.cancel();
    const total = 1500; // 1.5秒
    const step  = 50;
    _stopTimer = Timer.periodic(const Duration(milliseconds: step), (t) {
      setState(() => _stopProgress = (t.tick * step) / total);
      if (t.tick * step >= total) {
        t.cancel();
        widget.onFinish();
      }
    });
  }

  void _cancelHoldStop() {
    _stopTimer?.cancel();
    setState(() {
      _stopProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final color    = Theme.of(context).colorScheme.primary;
    final warnings = state.livePostureWarnings;
    final freq     = state.currentFrequency;
    final isPaused = state.isPaused;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /* 模式 + 计时 */
          Row(
            children: [
              Icon(Icons.fitness_center, color: color),
              const SizedBox(width: 8),
              Text(
                state.currentMode == 'pullup' ? '引体向上' : '俯卧撑',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(isPaused ? Icons.pause_circle_outline : Icons.timer,
                  color: isPaused ? Colors.orange : Colors.grey.shade600, size: 18),
              const SizedBox(width: 4),
              Text(
                isPaused ? '已暂停' : widget.fmt(widget.elapsedSecs),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isPaused ? Colors.orange : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          /* 计数卡片 */
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Text('动作计数',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('${state.trainingCount}',
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold,
                        color: isPaused ? Colors.grey : color)),
                  Text('次', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: '频率', value: '${freq.toStringAsFixed(1)}次/分'),
                      _StatItem(label: '时长', value: widget.fmt(state.trainDurationSecs)),
                      _StatItem(
                        label: '消耗',
                        value: () {
                          final met = state.currentMode == 'pullup' ? 8.0 : 3.8;
                          final cal = met * 70.0 * (state.trainDurationSecs / 3600.0);
                          return '${cal.toStringAsFixed(1)}千卡';
                        }(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          /* 暂停时显示汇总 */
          if (isPaused) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pause, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('训练已暂停',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          /* 姿态警告 */
          if (!isPaused && warnings.isNotEmpty) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      const SizedBox(width: 6),
                      Text('姿态提示',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800)),
                    ]),
                    const SizedBox(height: 8),
                    ...warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $w',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade900)),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          /* 底部控制栏 */
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /* 暂停/继续 */
              GestureDetector(
                onTap: isPaused ? widget.onResume : widget.onPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaused ? Colors.green : Colors.blue.shade600,
                  ),
                  child: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 40),

              /* 长按结束（圆形进度） */
              GestureDetector(
                onTapDown: (_) => _startHoldStop(),
                onTapUp:   (_) => _cancelHoldStop(),
                onTapCancel: _cancelHoldStop,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: _stopProgress,
                        strokeWidth: 4,
                        backgroundColor: Colors.red.shade100,
                        valueColor: const AlwaysStoppedAnimation(Colors.red),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: const Icon(Icons.stop, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '长按红色按钮结束训练',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
