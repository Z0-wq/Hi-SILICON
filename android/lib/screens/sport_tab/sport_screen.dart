import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';
import 'training_screen.dart';

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  String _selectedGoal = 'free';

  static const _goals = [
    {'key': 'free',  'label': '自由'},
    {'key': '10',    'label': '10个'},
    {'key': '20',    'label': '20个'},
    {'key': '30',    'label': '30个'},
    {'key': '50',    'label': '50个'},
    {'key': 't1',    'label': '1分钟'},
    {'key': 't3',    'label': '3分钟'},
    {'key': 't5',    'label': '5分钟'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now   = DateTime.now();
    final hour  = now.hour;
    final greeting = hour < 6 ? '夜深了' : hour < 12 ? '早上好' :
                     hour < 18 ? '下午好' : '晚上好';

    return Scaffold(
      backgroundColor: kBgGray,
      body: SafeArea(
        child: Column(
          children: [
            /* ── 顶部栏 ── */
            _TopBar(greeting: greeting, connected: state.connected),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    /* ── 模式选择 ── */
                    const Text('选择运动',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: kTextDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _ModeCard(
                          mode: 'pullup',
                          label: '引体向上',
                          icon: Icons.fitness_center,
                          description: '背阔肌 · 肱二头肌',
                          isSelected: state.currentMode == 'pullup',
                          lastRecord: _lastRecord(state, 'pullup'),
                          onTap: () => state.switchMode('pullup'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ModeCard(
                          mode: 'pushup',
                          label: '俯卧撑',
                          icon: Icons.accessibility_new,
                          description: '胸大肌 · 肱三头肌',
                          isSelected: state.currentMode == 'pushup',
                          lastRecord: _lastRecord(state, 'pushup'),
                          onTap: () => state.switchMode('pushup'),
                        )),
                      ],
                    ),
                    const SizedBox(height: 28),

                    /* ── 目标设定条 ── */
                    const Text('设定目标',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: kTextDark)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _goals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final g = _goals[i];
                          final isSelected = _selectedGoal == g['key'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGoal = g['key']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? kGreen : kCardWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? kGreen : Colors.grey.shade300),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: kGreen.withValues(alpha: 0.3),
                                      blurRadius: 8, offset: const Offset(0, 2))
                                ] : [],
                              ),
                              child: Text(g['label']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : kTextGray,
                                  fontWeight: isSelected
                                      ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                )),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),

                    /* ── GO 按钮 ── */
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: state.connected ? () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                  TrainingScreen(goal: _selectedGoal)));
                            } : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.connected
                                    ? kGreen : Colors.grey.shade300,
                                boxShadow: state.connected ? [
                                  BoxShadow(
                                    color: kGreen.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  )
                                ] : [],
                              ),
                              child: const Center(
                                child: Text('GO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.connected
                                ? '将使用IMU传感器自动计数'
                                : '请先连接设备',
                            style: TextStyle(
                              fontSize: 13,
                              color: state.connected
                                  ? kTextGray : Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _lastRecord(AppState state, String mode) {
    final action = mode == 'pullup' ? '引体向上' : '俯卧撑';
    try {
      final r = state.history.lastWhere((h) => h.action == action);
      return '上次：${r.count}个 · ${r.score.toStringAsFixed(0)}%标准';
    } catch (_) {
      return null;
    }
  }
}

/* ── 顶部栏 ─────────────────────────────────────── */
class _TopBar extends StatelessWidget {
  final String greeting;
  final bool connected;
  const _TopBar({required this.greeting, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kCardWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: kTextDark)),
              const Text('开始今日训练',
                style: TextStyle(fontSize: 13, color: kTextGray)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: connected ? kGreenLight : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(connected ? Icons.wifi : Icons.wifi_off,
                  size: 14,
                  color: connected ? kGreen : Colors.red),
                const SizedBox(width: 4),
                Text(connected ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 12,
                    color: connected ? kGreen : Colors.red,
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ── 模式卡片 ────────────────────────────────────── */
class _ModeCard extends StatelessWidget {
  final String mode;
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final String? lastRecord;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode, required this.label, required this.icon,
    required this.description, required this.isSelected,
    this.lastRecord, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kGreen : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? kGreen.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? kGreenLight : kBgGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                color: isSelected ? kGreen : kTextGray, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? kGreen : kTextDark,
              )),
            const SizedBox(height: 2),
            Text(description,
              style: const TextStyle(fontSize: 11, color: kTextGray)),
            if (lastRecord != null) ...[
              const SizedBox(height: 6),
              Text(lastRecord!,
                style: TextStyle(fontSize: 11,
                    color: isSelected ? kGreen : kTextGray)),
            ],
          ],
        ),
      ),
    );
  }
}
