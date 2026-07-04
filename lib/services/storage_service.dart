import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction_log.dart';

class StorageService {
  static const String _keyLogs = 'prediction_logs';

  /// Loads all prediction logs from SharedPreferences.
  static Future<List<PredictionLog>> loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyLogs);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => PredictionLog.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // In case of error (e.g. format issues), return empty list.
      return [];
    }
  }

  /// Saves a single prediction log to the list in SharedPreferences.
  static Future<void> saveLog(PredictionLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PredictionLog> currentLogs = await loadLogs();
    
    // Add new log at the beginning of the list
    currentLogs.insert(0, log);

    final String jsonString = jsonEncode(
      currentLogs.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_keyLogs, jsonString);
  }

  /// Updates an existing prediction log in SharedPreferences.
  static Future<void> updateLog(PredictionLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PredictionLog> currentLogs = await loadLogs();
    
    final index = currentLogs.indexWhere((item) => item.id == log.id);
    if (index != -1) {
      currentLogs[index] = log;
    } else {
      currentLogs.insert(0, log);
    }

    final String jsonString = jsonEncode(
      currentLogs.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_keyLogs, jsonString);
  }

  /// Deletes a specific prediction log by ID.
  static Future<void> deleteLog(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PredictionLog> currentLogs = await loadLogs();
    
    currentLogs.removeWhere((item) => item.id == id);

    final String jsonString = jsonEncode(
      currentLogs.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_keyLogs, jsonString);
  }

  /// Clears all prediction logs.
  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLogs);
  }
}
