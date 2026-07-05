import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/imu_data.dart';

class ApiService {
  String baseUrl;

  ApiService(this.baseUrl);

  Future<ImuData?> fetchLiveData() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/imu/live'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return ImuData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  Future<List<HistoryRecord>> fetchHistory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/history'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List list = body is List ? body : (body['records'] as List? ?? []);
        return list.map((e) => HistoryRecord.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> saveHistory(HistoryRecord record) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/history'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(record.toJson()),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 201;
    } catch (_) {}
    return false;
  }

  /// 切换运动模式：'pullup' 或 'pushup'
  Future<bool> setMode(String mode) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/mode'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': mode}),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<String> getMode() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/mode'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['mode'] ?? 'pullup';
      }
    } catch (_) {}
    return 'pullup';
  }

  Future<void> deleteHistory(int index) async {
    try {
      await http
          .delete(Uri.parse('$baseUrl/api/history/$index'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
