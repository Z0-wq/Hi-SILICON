import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/imu_data.dart';
import '../services/api_service.dart';

// 姿态检测阈值
const double _kRollWarnDeg   = 15.0;  // 身体偏转警告
const double _kPitchPullup   = 20.0;  // 引体向上最小pitch变化范围
const double _kPitchPushup   = 15.0;  // 俯卧撑最小pitch变化范围
const double _kFreqFastLimit = 20.0;  // 节奏过快（次/分）
const double _kFreqSlowLimit = 2.0;   // 节奏过慢（次/分）

// 卡路里MET值
const double _kMetPullup = 8.0;
const double _kMetPushup = 3.8;
const double _kBodyWeight = 70.0;    // 默认体重kg

class AppState extends ChangeNotifier {
  // 🔴 联调时改这里：Mock调试用PC的IP，接SS928时改成SS928的IP
  String _serverIp = '10.20.178.105';
  int _serverPort = 8081;
  bool _connected = false;
  ImuData _liveData = ImuData.mock;
  List<HistoryRecord> _history = [];
  List<ImuData> _chartBuffer = List.generate(50, (_) => ImuData.mock);

  // 运动模式：pullup=引体向上，pushup=俯卧撑
  String _currentMode = 'pullup';

  // 训练状态
  bool _isTraining  = false;
  bool _isPaused    = false;
  DateTime? _trainStartTime;
  int _pausedSecs       = 0;
  DateTime? _pauseStartTime;
  int _countBase        = 0;   // 训练开始时的计数基准
  int _countSnapshot    = 0;   // 暂停时的计数快照
  double _freqSnapshot     = 0.0;  // 暂停时频率快照
  double _caloriesSnapshot = 0.0;  // 暂停时消耗快照
  int _prevCount        = 0;
  double _pitchMin  = 0.0;
  double _pitchMax  = 0.0;
  final List<String> _postureIssues = [];
  int _rollWarnCount   = 0;
  int _pitchWarnCount  = 0;
  bool _freqFastWarned = false;
  bool _freqSlowWarned = false;

  Timer? _pollTimer;
  late ApiService _api;

  String get serverIp   => _serverIp;
  int    get serverPort => _serverPort;
  bool   get connected   => _connected;
  ImuData get liveData   => _liveData;
  List<HistoryRecord> get history => _history;
  List<ImuData> get chartBuffer   => _chartBuffer;
  String get currentMode => _currentMode;
  bool   get isTraining  => _isTraining;
  bool   get isPaused    => _isPaused;

  // 实际计数（暂停时返回快照，运动中动态计算）
  int get trainingCount {
    if (_isPaused) return _countSnapshot;
    return (_liveData.count - _countBase).clamp(0, 9999);
  }

  // 训练有效时长（秒，排除暂停时间）
  int get trainDurationSecs {
    if (_trainStartTime == null) return 0;
    final total = DateTime.now().difference(_trainStartTime!).inSeconds;
    final pauseExtra = _isPaused && _pauseStartTime != null
        ? DateTime.now().difference(_pauseStartTime!).inSeconds
        : 0;
    return (total - _pausedSecs - pauseExtra).clamp(0, 99999);
  }

  // 当前频率（次/分钟），暂停时返回快照值
  double get currentFrequency {
    if (_isPaused) return _freqSnapshot;
    final secs = trainDurationSecs;
    if (secs < 5) return 0;
    return trainingCount / (secs / 60.0);
  }

  // 当前消耗卡路里，暂停时返回快照值
  double get currentCalories {
    if (_isPaused) return _caloriesSnapshot;
    final met = _currentMode == 'pullup' ? _kMetPullup : _kMetPushup;
    return met * _kBodyWeight * (trainDurationSecs / 3600.0);
  }

  // 实时姿态警告（训练中实时显示）
  List<String> get livePostureWarnings {
    if (!_isTraining) return [];
    final warnings = <String>[];
    if (_liveData.roll.abs() > _kRollWarnDeg) {
      warnings.add('身体偏转 ${_liveData.roll.toStringAsFixed(1)}°，保持躯干正直');
    }
    final freq = currentFrequency;
    if (freq > _kFreqFastLimit) warnings.add('节奏过快（${freq.toStringAsFixed(1)}次/分），建议放慢');
    if (trainDurationSecs > 30 && freq < _kFreqSlowLimit && freq > 0) {
      warnings.add('节奏偏慢（${freq.toStringAsFixed(1)}次/分），可适当加快');
    }
    return warnings;
  }

  AppState() { _loadSettings(); }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp   = prefs.getString('server_ip')  ?? '10.20.178.105';
    _serverPort = prefs.getInt('server_port')    ?? 8081;
    _api = ApiService('http://$_serverIp:$_serverPort');
    notifyListeners();
    _startPolling();
  }

  Future<void> saveSettings(String ip, int port) async {
    _serverIp   = ip;
    _serverPort = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setInt('server_port', port);
    _api = ApiService('http://$ip:$port');
    notifyListeners();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final data = await _api.fetchLiveData();
      if (data != null) {
        if (_isTraining && !_isPaused) _updatePostureCheck(data);
        _liveData   = data;
        _connected  = true;
      } else {
        _connected = false;
      }
      _chartBuffer = [..._chartBuffer.skip(1), data ?? ImuData.mock];
      notifyListeners();
    });
  }

  // 姿态检测（每次轮询调用）
  void _updatePostureCheck(ImuData data) {
    // 更新pitch范围
    if (_prevCount == 0 && data.count == 0) {
      _pitchMin = data.pitch;
      _pitchMax = data.pitch;
    } else {
      if (data.pitch < _pitchMin) _pitchMin = data.pitch;
      if (data.pitch > _pitchMax) _pitchMax = data.pitch;
    }

    // 身体偏转
    if (data.roll.abs() > _kRollWarnDeg) _rollWarnCount++;

    // 动作幅度（有新动作时检测）
    if (data.count > _prevCount) {
      final range   = _pitchMax - _pitchMin;
      final minRange = _currentMode == 'pullup' ? _kPitchPullup : _kPitchPushup;
      if (range < minRange) _pitchWarnCount++;
      _pitchMin = data.pitch;
      _pitchMax = data.pitch;
      _prevCount = data.count;
    }

    // 节奏（只记录一次警告到问题列表）
    final freq = currentFrequency;
    if (!_freqFastWarned && freq > _kFreqFastLimit) {
      _postureIssues.add('节奏过快，建议放慢控制');
      _freqFastWarned = true;
    }
    if (!_freqSlowWarned && trainDurationSecs > 30 && freq < _kFreqSlowLimit && freq > 0) {
      _postureIssues.add('节奏偏慢，可适当加快');
      _freqSlowWarned = true;
    }
  }

  // 开始训练
  void startTraining() {
    _isTraining      = true;
    _isPaused        = false;
    _trainStartTime  = DateTime.now();
    _pausedSecs      = 0;
    _pauseStartTime  = null;
    _countBase       = _liveData.count;  // 记录训练开始时的计数基准
    _prevCount       = 0;
    _rollWarnCount   = 0;
    _pitchWarnCount  = 0;
    _freqFastWarned  = false;
    _freqSlowWarned  = false;
    _postureIssues.clear();
    _pitchMin = _liveData.pitch;
    _pitchMax = _liveData.pitch;
    notifyListeners();
  }

  // 暂停训练
  void pauseTraining() {
    if (!_isTraining || _isPaused) return;
    _countSnapshot    = trainingCount;
    _freqSnapshot     = currentFrequency;
    _caloriesSnapshot = currentCalories;
    _isPaused         = true;
    _pauseStartTime   = DateTime.now();
    notifyListeners();
  }

  // 继续训练
  void resumeTraining() {
    if (!_isTraining || !_isPaused) return;
    if (_pauseStartTime != null) {
      _pausedSecs += DateTime.now().difference(_pauseStartTime!).inSeconds;
    }
    _countBase      = _liveData.count - _countSnapshot; // 重新校准base
    _isPaused       = false;
    _pauseStartTime = null;
    notifyListeners();
  }

  // 结束训练并保存，返回保存的记录（失败返回null）
  Future<HistoryRecord?> finishTraining() async {
    if (!_isTraining) return null;
    if (_isPaused) resumeTraining();
    _isTraining = false;
    _isPaused   = false;

    final count    = trainingCount;
    final dSecs    = trainDurationSecs;
    final freq     = dSecs > 0 ? count / (dSecs / 60.0) : 0.0;
    final met      = _currentMode == 'pullup' ? _kMetPullup : _kMetPushup;
    final calories = met * _kBodyWeight * (dSecs / 3600.0);

    // 汇总姿态问题
    final issues = List<String>.from(_postureIssues);
    if (_rollWarnCount > 0)  issues.add('${_rollWarnCount}次身体偏转（roll>${_kRollWarnDeg.toInt()}°）');
    if (_pitchWarnCount > 0) issues.add('${_pitchWarnCount}次动作幅度不足');

    // 生成建议
    final suggestions = _buildSuggestions(issues);

    // 评分：基础分=次数×5（最多70），姿态分=30-问题数×5
    double score = (count * 5.0).clamp(0, 70) + (30.0 - issues.length * 5).clamp(0, 30);
    score = score.clamp(0, 100);

    final action = _currentMode == 'pullup' ? '引体向上' : '俯卧撑';
    final now    = DateTime.now();
    final date   = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    final record = HistoryRecord(
      date:          date,
      action:        action,
      count:         count,
      score:         score,
      durationSecs:  dSecs,
      frequency:     double.parse(freq.toStringAsFixed(1)),
      calories:      double.parse(calories.toStringAsFixed(1)),
      postureIssues: issues,
      suggestions:   suggestions,
    );

    // 重置计数
    _liveData = ImuData.mock;
    _chartBuffer = List.generate(50, (_) => ImuData.mock);
    notifyListeners();

    final ok = await saveHistory(record);
    return ok ? record : null;
  }

  List<String> _buildSuggestions(List<String> issues) {
    final s = <String>[];
    if (issues.any((i) => i.contains('偏转'))) {
      s.add('收紧核心肌群，保持躯干正直，减少身体左右摇摆');
    }
    if (issues.any((i) => i.contains('幅度不足'))) {
      if (_currentMode == 'pullup') {
        s.add('引体向上需完整伸展，下巴需过杆，手臂完全伸直后再起');
      } else {
        s.add('俯卧撑需完整伸展，胸部需接近地面，手臂完全伸直');
      }
    }
    if (issues.any((i) => i.contains('节奏过快'))) {
      s.add('放慢节奏，每个动作控制在3-4秒，注重肌肉感受');
    }
    if (issues.any((i) => i.contains('节奏偏慢'))) {
      s.add('适当加快节奏，保持肌肉张力，避免长时间停顿');
    }
    if (s.isEmpty) s.add('动作规范，继续保持！可适当增加训练量');
    return s;
  }

  // 切换运动模式
  Future<void> switchMode(String mode) async {
    if (_isTraining) return; // 训练中不允许切换
    final ok = await _api.setMode(mode);
    if (ok) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _history = await _api.fetchHistory();
    notifyListeners();
  }

  Future<bool> saveHistory(HistoryRecord record) async {
    final ok = await _api.saveHistory(record);
    if (ok) await loadHistory();
    return ok;
  }

  Future<void> deleteHistory(int index) async {
    if (index < 0 || index >= _history.length) return;
    await _api.deleteHistory(index);
    await loadHistory();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
