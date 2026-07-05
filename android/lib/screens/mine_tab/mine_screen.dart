import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme.dart';

class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history;
    final totalCount = history.fold(0, (s, r) => s + r.count);
    final totalSecs  = history.fold(0, (s, r) => s + r.durationSecs);

    return Scaffold(
      backgroundColor: kBgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /* 头部 */
              Container(
                color: kCardWhite,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: kGreenLight,
                      child: const Icon(Icons.person,
                          color: kGreen, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('运动达人',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold, color: kTextDark)),
                        const SizedBox(height: 2),
                        Text('累计训练 ${history.length} 次',
                          style: const TextStyle(
                              fontSize: 13, color: kTextGray)),
                      ],
                    ),
                  ],
                ),
              ),

              /* 累计数据卡 */
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF5BA318)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: '训练次数',
                        value: '${history.length}次'),
                    _StatItem(label: '总完成',
                        value: '$totalCount个'),
                    _StatItem(label: '总时长',
                        value: fmtDurationChinese(totalSecs)),
                  ],
                ),
              ),

              /* 设置列表 */
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SettingSection(
                      title: '训练设置',
                      items: [
                        _SettingItem(
                          icon: Icons.monitor_weight_outlined,
                          label: '体重设置',
                          subtitle: '影响卡路里计算，默认70kg',
                          onTap: () => _showWeightDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SettingSection(
                      title: '连接设置',
                      items: [
                        _SettingItem(
                          icon: Icons.wifi,
                          label: '服务器地址',
                          subtitle: '${state.serverIp}:${state.serverPort}',
                          onTap: () => _showServerDialog(context, state),
                        ),
                        _SettingItem(
                          icon: Icons.circle,
                          label: '连接状态',
                          subtitle: state.connected ? '已连接' : '未连接',
                          subtitleColor: state.connected ? kGreen : Colors.red,
                          onTap: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SettingSection(
                      title: '关于',
                      items: [
                        _SettingItem(
                          icon: Icons.videocam_outlined,
                          label: '摄像头辅助',
                          subtitle: '即将推出',
                          enabled: false,
                          onTap: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '70');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置体重'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: kGreen),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showServerDialog(BuildContext context, AppState state) {
    final ipCtrl   = TextEditingController(text: state.serverIp);
    final portCtrl = TextEditingController(text: '${state.serverPort}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                  labelText: 'IP地址', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '端口', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(portCtrl.text) ?? 8081;
              state.saveSettings(ipCtrl.text.trim(), port);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: kGreen),
            child: const Text('保存'),
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
        Text(value,
          style: const TextStyle(color: Colors.white,
              fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;
  const _SettingSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title,
            style: const TextStyle(fontSize: 13,
                color: kTextGray, fontWeight: FontWeight.w500)),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? subtitleColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.subtitleColor,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: enabled ? kGreenLight : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
          color: enabled ? kGreen : Colors.grey, size: 20),
      ),
      title: Text(label,
        style: TextStyle(
          fontSize: 15,
          color: enabled ? kTextDark : kTextGray,
        )),
      subtitle: Text(subtitle,
        style: TextStyle(
          fontSize: 12,
          color: subtitleColor ?? kTextGray,
        )),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: kTextGray, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
