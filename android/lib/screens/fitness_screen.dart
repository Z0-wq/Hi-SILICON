import 'package:flutter/material.dart';

class FitnessScreen extends StatelessWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('训练指导')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            title: '平板支撑',
            icon: Icons.accessibility,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DetailPage(action: _plank),
            )),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: '深蹲',
            icon: Icons.fitness_center,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DetailPage(action: _squat),
            )),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: '俯卧撑',
            icon: Icons.sports_gymnastics,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DetailPage(action: _pushup),
            )),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: '瑜伽山式',
            icon: Icons.self_improvement,
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DetailPage(action: _mountain),
            )),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: '瑜伽树式',
            icon: Icons.nature_people,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const _DetailPage(action: _tree),
            )),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionGuide {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keyPoints;
  final List<String> commonErrors;
  final String rollRange;
  final String pitchRange;
  final List<String> tips;

  const _ActionGuide({
    required this.name,
    required this.icon,
    required this.color,
    required this.keyPoints,
    required this.commonErrors,
    required this.rollRange,
    required this.pitchRange,
    required this.tips,
  });
}

const _plank = _ActionGuide(
  name: '平板支撑',
  icon: Icons.accessibility,
  color: Colors.blue,
  keyPoints: [
    '双肘撑地，肘关节位于肩关节正下方',
    '身体呈一条直线，从头到脚保持水平',
    '收紧核心，臀部不塌陷、不抬高',
    '颈部保持中立，目光看向地面',
  ],
  commonErrors: [
    '塌腰：腰部下沉，腹部接近地面',
    '撅臀：臀部抬高，身体呈倒V型',
    '耸肩：肩膀向耳朵方向收缩',
    '憋气：忘记呼吸，导致肌肉紧张',
  ],
  rollRange: '±3°',
  pitchRange: '0~5°',
  tips: [
    '初学者可从膝盖支撑开始，逐步过渡到标准平板',
    '保持自然呼吸，不要憋气',
    '感觉腰部不适时立即停止，检查姿势',
    '建议每组 30~60 秒，休息 30 秒后重复',
  ],
);

const _squat = _ActionGuide(
  name: '深蹲',
  icon: Icons.fitness_center,
  color: Colors.orange,
  keyPoints: [
    '双脚与肩同宽，脚尖略微外展',
    '下蹲时膝盖与脚尖方向一致',
    '臀部向后坐，大腿至少与地面平行',
    '躯干保持直立，核心收紧',
  ],
  commonErrors: [
    '膝盖内扣：膝盖向内夹，容易损伤',
    '重心前移：脚跟离地，膝盖过度前伸',
    '弓背：背部弯曲，腰椎压力大',
    '下蹲不足：大腿未达到水平，训练效果差',
  ],
  rollRange: '±5°',
  pitchRange: '10~20°',
  tips: [
    '初学者可对着镜子练习，观察膝盖轨迹',
    '下蹲时吸气，起立时呼气',
    '脚跟始终贴地，重心在脚掌中后部',
    '建议每组 15~20 次，做 3~4 组',
  ],
);

const _pushup = _ActionGuide(
  name: '俯卧撑',
  icon: Icons.sports_gymnastics,
  color: Colors.green,
  keyPoints: [
    '双手与肩同宽，手掌位于肩关节正下方',
    '身体呈一条直线，核心收紧',
    '下降至胸部接近地面，肘关节约 90°',
    '推起时手臂伸直但不锁死',
  ],
  commonErrors: [
    '塌腰：腹部下沉，腰椎压力大',
    '撅臀：臀部抬高，核心未发力',
    '肘关节外展过大：肩关节压力大',
    '动作幅度不足：未充分下降',
  ],
  rollRange: '±3°',
  pitchRange: '0~5°',
  tips: [
    '初学者可从跪姿俯卧撑或上斜俯卧撑开始',
    '下降时吸气，推起时呼气',
    '肘关节与躯干夹角约 45°，避免过度外展',
    '建议每组力竭次数，做 3~4 组',
  ],
);

const _mountain = _ActionGuide(
  name: '瑜伽山式',
  icon: Icons.self_improvement,
  color: Colors.purple,
  keyPoints: [
    '双脚并拢或略微分开，脚掌均匀受力',
    '膝盖微屈不锁死，大腿肌肉上提',
    '骨盆中立，尾骨微收',
    '脊柱延展，头顶向上，下巴微收',
    '双肩放松下沉，手臂自然垂于身体两侧',
  ],
  commonErrors: [
    '重心偏移：身体向前或向后倾斜',
    '骨盆前倾：腰部过度前凸',
    '耸肩：肩膀紧张上提',
    '膝盖锁死：膝关节过度伸直',
  ],
  rollRange: '±2°',
  pitchRange: '±3°',
  tips: [
    '山式是所有站立体式的基础，需反复练习',
    '闭眼练习可提高平衡感和身体觉知',
    '保持自然呼吸，感受身体的稳定与延展',
    '建议保持 1~3 分钟',
  ],
);

const _tree = _ActionGuide(
  name: '瑜伽树式',
  icon: Icons.nature_people,
  color: Colors.teal,
  keyPoints: [
    '单腿站立，支撑腿膝盖微屈',
    '另一腿脚掌贴于支撑腿大腿内侧',
    '骨盆保持水平，髋关节外展',
    '双手合十于胸前或向上伸展',
    '目光注视前方固定点，保持平衡',
  ],
  commonErrors: [
    '支撑腿膝盖锁死：关节压力大',
    '骨盆倾斜：身体向一侧歪斜',
    '脚掌压在膝盖上：容易损伤膝关节',
    '耸肩：肩膀紧张上提',
  ],
  rollRange: '±8°',
  pitchRange: '±5°',
  tips: [
    '初学者可将脚掌放在小腿内侧或脚踝处',
    '可靠墙练习，逐步提高平衡能力',
    '保持自然呼吸，不要憋气',
    '建议每侧保持 30~60 秒',
  ],
);

class _DetailPage extends StatelessWidget {
  final _ActionGuide action;
  const _DetailPage({required this.action});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(action.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: action.color.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(action.icon, size: 48, color: action.color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('标准动作要领与常见错误', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: '动作要领', icon: Icons.check_circle_outline, items: action.keyPoints),
          const SizedBox(height: 12),
          _Section(title: '常见错误', icon: Icons.warning_amber, items: action.commonErrors, color: Colors.orange),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sensors, size: 18, color: action.color),
                      const SizedBox(width: 8),
                      const Text('IMU 数据参考', style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DataRow(label: '横滚角 (Roll)', value: action.rollRange),
                  _DataRow(label: '俯仰角 (Pitch)', value: action.pitchRange),
                  const SizedBox(height: 8),
                  Text(
                    '佩戴 IMU 设备时，保持数据在参考范围内表示姿态标准',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(title: '训练建议', icon: Icons.lightbulb_outline, items: action.tips, color: Colors.blue),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color? color;

  const _Section({
    required this.title,
    required this.icon,
    required this.items,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
