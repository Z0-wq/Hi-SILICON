import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'summary_screen.dart';
class TrainingScreen extends StatefulWidget {
  final String goal;
  const TrainingScreen({super.key, required this.goal});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  // 计时器
  Timer? _clockTimer;
  int _clockSecs = 0;

  // 长按结束
  double _stopProgress = 0.0;
  Timer? _stopTimer;

  // 目标达成
  bool _goalReached = false;

  // 姿态动画
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().startTraining();
      _startClock();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _stopTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (!state.isPaused) setState(() => _clockSecs++);
    });
  }

  void _onMainButtonTap() {
    final state = context.read<AppState>();
    if (state.isPaused) {
      state.resumeTraining();
    } else {
      state.pauseTraining();
    }
  }

  void _startHoldStop() {
    _stopProgress = 0.0;
    _stopTimer?.cancel();
    const total = 2000;
    const step  = 40;
    _stopTimer = Timer.periodic(const Duration(milliseconds: step), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _stopProgress = (t.tick * step) / total);
      if (t.tick * step >= total) {
        t.cancel();
        _finishTraining();
      }
    });
  }

  void _cancelHoldStop() {
    _stopTimer?.cancel();
    if (mounted) setState(() => _stopProgress = 0.0);
  }

  Future<void> _finishTraining() async {
    _clockTimer?.cancel();
    _stopTimer?.cancel();
    final appState = context.read<AppState>();
    final record   = await appState.finishTraining();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SummaryScreen(record: record)),
    );
  }

  // 检查目标是否达成
  void _checkGoal(int count, int secs) {
    if (_goalReached) return;
    bool reached = false;
    if (widget.goal == '10' && count >= 10) reached = true;
    else if (widget.goal == '20' && count >= 20) reached = true;
    else if (widget.goal == '30' && count >= 30) reached = true;
    else if (widget.goal == '50' && count >= 50) reached = true;
    else if (widget.goal == 't1' && secs >= 60) reached = true;
    else if (widget.goal == 't3' && secs >= 180) reached = true;
    else if (widget.goal == 't5' && secs >= 300) reached = true;

    if (reached) {
      _goalReached = true;
      context.read<AppState>().pauseTraining();
      _showGoalDialog();
    }
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.emoji_events, color: kGreen),
          SizedBox(width: 8),
          Text('目标完成！'),
        ]),
        content: Text(
          widget.goal.startsWith('t')
              ? '已达到目标时长，继续还是结束？'
              : '已完成目标 ${widget.goal} 个，继续还是结束？',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().resumeTraining();
            },
            child: const Text('再来一组', style: TextStyle(color: kGreen)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishTraining();
            },
            style: FilledButton.styleFrom(backgroundColor: kGreen),
            child: const Text('结束'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final isPaused = state.isPaused;
    final count    = state.trainingCount;
    final freq     = state.currentFrequency;
    final dSecs    = state.trainDurationSecs;
    final calories = state.currentCalories;
    final score    = state.livePostureWarnings.isEmpty ? 100.0 :
                     (100.0 - state.livePostureWarnings.length * 10).clamp(0, 100).toDouble();
    final warnings = state.livePostureWarnings;
    final modeName = state.currentMode == 'pullup' ? '引体向上' : '俯卧撑';

    // 目标检测（非暂停且非自由模式时）
    if (!isPaused && widget.goal != 'free') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkGoal(count, dSecs);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            /* ── 背景占位（摄像头区域）── */
            _CameraPlaceholder(modeName: modeName, isPaused: isPaused),

            /* ── 顶部栏 ── */
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TrainingTopBar(modeName: modeName, goal: widget.goal),
            ),

            /* ── 数据卡片 ── */
            Positioned(
              top: 80, left: 16, right: 16,
              child: _DataCard(
                clockSecs: _clockSecs,
                count:     count,
                freq:      freq,
                calories:  calories,
                score:     score,
                isPaused:  isPaused,
                warnings:  warnings,
              ),
            ),

            /* ── 底部控制区 ── */
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _ControlBar(
                isPaused:     isPaused,
                stopProgress: _stopProgress,
                onMainTap:    _onMainButtonTap,
                onHoldStart:  _startHoldStop,
                onHoldCancel: _cancelHoldStop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── 背景摄像头占位 ───────────────────────────────── */
class _CameraPlaceholder extends StatelessWidget {
  final String modeName;
  final bool isPaused;
  const _CameraPlaceholder({required this.modeName, required this.isPaused});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              modeName == '引体向上' ? Icons.fitness_center : Icons.accessibility_new,
              size: 80,
              color: Colors.white.withValues(alpha: isPaused ? 0.2 : 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              isPaused ? '已暂停' : modeName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isPaused ? 0.5 : 0.2),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ── 顶部栏 ──────────────────────────────────────── */
class _TrainingTopBar extends StatelessWidget {
  final String modeName;
  final String goal;
  const _TrainingTopBar({required this.modeName, required this.goal});

  String _goalLabel(String g) {
    switch (g) {
      case 'free': return '自由模式';
      case 't1':   return '目标1分钟';
      case 't3':   return '目标3分钟';
      case 't5':   return '目标5分钟';
      default:     return '目标${g}个';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(modeName,
                style: const TextStyle(color: Colors.white,
                    fontSize: 17, fontWeight: FontWeight.bold)),
              Text(_goalLabel(goal),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/* ── 数据卡片 ─────────────────────────────────────── */
class _DataCard extends StatelessWidget {
  final int clockSecs;
  final int count;
  final double freq;
  final double calories;
  final double score;
  final bool isPaused;
  final List<String> warnings;

  const _DataCard({
    required this.clockSecs, required this.count, required this.freq,
    required this.calories, required this.score, required this.isPaused,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          /* 计时器 */
          Text(fmtDuration(clockSecs),
            style: TextStyle(
              color: isPaused ? Colors.orange : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            )),
          const SizedBox(height: 16),

          /* 大号计数 */
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count',
                style: TextStyle(
                  color: isPaused
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  height: 1,
                )),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text('个',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 20,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 16),

          /* 小数据行 */
          Row(
            children: [
              _MiniStat(label: '频率', value: '${freq.toStringAsFixed(1)}个/分'),
              _Divider(),
              _MiniStat(label: '消耗', value: '${calories.toStringAsFixed(1)}kcal'),
              _Divider(),
              _MiniStat(
                label: '标准率',
                value: '${score.toStringAsFixed(0)}%',
                valueColor: scoreColor(score),
              ),
            ],
          ),

          /* 姿态警告 */
          if (!isPaused && warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: warnings.map((w) => Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(w,
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12))),
                  ],
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

/* ── 底部控制栏 ──────────────────────────────────── */
class _ControlBar extends StatelessWidget {
  final bool isPaused;
  final double stopProgress;
  final VoidCallback onMainTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;

  const _ControlBar({
    required this.isPaused,
    required this.stopProgress,
    required this.onMainTap,
    required this.onHoldStart,
    required this.onHoldCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /* 左侧预留：摄像头翻转 */
          _SideButton(icon: Icons.flip_camera_ios, onTap: null),

          /* 主控按钮：短按暂停/继续 */
          GestureDetector(
            onTap: onMainTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGreen,
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withValues(alpha: 0.4),
                    blurRadius: 16, spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          /* 长按结束按钮 */
          GestureDetector(
            onTapDown: (_) => onHoldStart(),
            onTapUp:   (_) => onHoldCancel(),
            onTapCancel: onHoldCancel,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: stopProgress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.red),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stopProgress > 0
                        ? Colors.red : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                        color: Colors.red, width: 1.5),
                  ),
                  child: const Icon(Icons.stop,
                      color: Colors.red, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SideButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: onTap != null ? 0.15 : 0.05),
        ),
        child: Icon(icon,
          color: Colors.white.withValues(alpha: onTap != null ? 0.8 : 0.3),
          size: 22),
      ),
    );
  }
}
