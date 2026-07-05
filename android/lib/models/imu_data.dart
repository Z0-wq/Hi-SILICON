class ImuData {
  final int seq;
  final int accX;
  final int accY;
  final int accZ;
  final int gyroX;
  final int gyroY;
  final int gyroZ;
  final int timestamp;
  final int count;
  final double roll;
  final double pitch;

  const ImuData({
    required this.seq,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
    required this.count,
    required this.roll,
    required this.pitch,
  });

  factory ImuData.fromJson(Map<String, dynamic> j) => ImuData(
        seq: j['seq'] ?? 0,
        accX: j['acc_x'] ?? 0,
        accY: j['acc_y'] ?? 0,
        accZ: j['acc_z'] ?? 0,
        gyroX: j['gyro_x'] ?? 0,
        gyroY: j['gyro_y'] ?? 0,
        gyroZ: j['gyro_z'] ?? 0,
        timestamp: j['timestamp'] ?? 0,
        count: j['count'] ?? 0,
        roll: (j['roll'] ?? 0.0).toDouble(),
        pitch: (j['pitch'] ?? 0.0).toDouble(),
      );

  static ImuData get mock => const ImuData(
        seq: 0, accX: -375, accY: 500, accZ: 34,
        gyroX: 0, gyroY: 1, gyroZ: 0,
        timestamp: 0, count: 0, roll: 0.0, pitch: 0.0,
      );
}

class HistoryRecord {
  final String date;
  final String action;
  final int count;
  final double score;
  final int durationSecs;          // 训练时长（秒）
  final double frequency;          // 频率（次/分钟）
  final double calories;           // 估算卡路里
  final List<String> postureIssues; // 姿态问题列表
  final List<String> suggestions;  // 建议列表

  const HistoryRecord({
    required this.date,
    required this.action,
    required this.count,
    required this.score,
    this.durationSecs = 0,
    this.frequency = 0.0,
    this.calories = 0.0,
    this.postureIssues = const [],
    this.suggestions = const [],
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        date:          j['date'] ?? '',
        action:        j['action'] ?? '',
        count:         j['count'] ?? 0,
        score:         (j['score'] ?? 0.0).toDouble(),
        durationSecs:  j['duration_secs'] ?? 0,
        frequency:     (j['frequency'] ?? 0.0).toDouble(),
        calories:      (j['calories'] ?? 0.0).toDouble(),
        postureIssues: List<String>.from(j['posture_issues'] ?? []),
        suggestions:   List<String>.from(j['suggestions'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'date':          date,
        'action':        action,
        'count':         count,
        'score':         score,
        'duration_secs': durationSecs,
        'frequency':     frequency,
        'calories':      calories,
        'posture_issues': postureIssues,
        'suggestions':   suggestions,
      };
}
