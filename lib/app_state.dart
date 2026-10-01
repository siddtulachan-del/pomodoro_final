import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerPhase { sprint, breakTime }

enum AppThemeMode { light, dark, system }

class DailyRecord {
  const DailyRecord({
    required this.dateKey,
    required this.sprintsCompleted,
    required this.dailyGoal,
  });

  final String dateKey;
  final int sprintsCompleted;
  final int dailyGoal;

  bool get goalMet => sprintsCompleted >= dailyGoal;

  Map<String, dynamic> toJson() => {
    'sprintsCompleted': sprintsCompleted,
    'dailyGoal': dailyGoal,
  };

  factory DailyRecord.fromJson(String dateKey, Map<String, dynamic> json) {
    return DailyRecord(
      dateKey: dateKey,
      sprintsCompleted: json['sprintsCompleted'] as int? ?? 0,
      dailyGoal: json['dailyGoal'] as int? ?? 4,
    );
  }
}

class AppState extends ChangeNotifier {
  static const int maxSprintMinutes = 25;
  static const int minBreakMinutes = 5;
  static const int sprintSeconds = maxSprintMinutes * 60;

  static String dateKeyFor(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Timer? _timer;
  bool _isRunning = false;
  bool _sessionActive = false;

  TimerPhase _phase = TimerPhase.sprint;
  int _remainingSeconds = sprintSeconds;
  int _currentSprint = 1;
  int _totalSprints = 4;
  int _breakMinutes = 5;
  int _dailyGoal = 4;
  bool _sessionComplete = false;
  AppThemeMode _themeMode = AppThemeMode.system;

  final Map<String, DailyRecord> _history = {};

  bool get isRunning => _isRunning;
  bool get sessionActive => _sessionActive;
  bool get inFocusMode => _sessionActive && !_sessionComplete;
  TimerPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  int get currentSprint => _currentSprint;
  int get totalSprints => _totalSprints;
  int get breakMinutes => _breakMinutes;
  int get dailyGoal => _dailyGoal;
  bool get sessionComplete => _sessionComplete;
  AppThemeMode get themeMode => _themeMode;

  ThemeMode get materialThemeMode => switch (_themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  List<DailyRecord> get historyRecords {
    final records = _history.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return records;
  }

  DailyRecord get todayRecord {
    final key = dateKeyFor(DateTime.now());
    return _history[key] ??
        DailyRecord(dateKey: key, sprintsCompleted: 0, dailyGoal: _dailyGoal);
  }

  int get todaySprintsCompleted => todayRecord.sprintsCompleted;
  int get sprintsLeftToGoal =>
      (_dailyGoal - todaySprintsCompleted).clamp(0, _dailyGoal);
  bool get todayGoalMet => todayRecord.goalMet;

  String get phaseLabel {
    if (_sessionComplete) return 'Done';
    return _phase == TimerPhase.sprint ? 'Sprint' : 'Break';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _totalSprints = prefs.getInt('totalSprints') ?? 4;
    _breakMinutes = (prefs.getInt('breakMinutes') ?? minBreakMinutes)
        .clamp(minBreakMinutes, 30)
        .toInt();
    _dailyGoal = prefs.getInt('dailyGoal') ?? 4;
    _themeMode = AppThemeMode.values[prefs.getInt('themeMode') ?? 2];

    final historyJson = prefs.getString('history');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _history
        ..clear()
        ..addAll(
          decoded.map(
            (key, value) => MapEntry(
              key,
              DailyRecord.fromJson(key, value as Map<String, dynamic>),
            ),
          ),
        );
    }

    _ensureTodayRecord();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalSprints', _totalSprints);
    await prefs.setInt('breakMinutes', _breakMinutes);
    await prefs.setInt('dailyGoal', _dailyGoal);
    await prefs.setInt('themeMode', _themeMode.index);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _history.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString('history', encoded);
  }

  void _ensureTodayRecord() {
    final key = dateKeyFor(DateTime.now());
    _history.putIfAbsent(
      key,
      () =>
          DailyRecord(dateKey: key, sprintsCompleted: 0, dailyGoal: _dailyGoal),
    );
  }

  void _recordSprintCompleted() {
    _ensureTodayRecord();
    final key = dateKeyFor(DateTime.now());
    final current = _history[key]!;
    _history[key] = DailyRecord(
      dateKey: key,
      sprintsCompleted: current.sprintsCompleted + 1,
      dailyGoal: _dailyGoal,
    );
    _saveHistory();
  }

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void startResume() {
    if (_sessionComplete) {
      resetSession();
    }

    enterImmersiveMode();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    _sessionActive = true;
    _isRunning = true;
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  void _tick() {
    if (!_isRunning) return;

    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
      return;
    }

    _onPhaseComplete();
  }

  void _onPhaseComplete() {
    if (_phase == TimerPhase.sprint) {
      _recordSprintCompleted();

      if (_currentSprint >= _totalSprints) {
        _finishSession();
        return;
      }

      _phase = TimerPhase.breakTime;
      _remainingSeconds = _breakMinutes * 60;
    } else {
      _currentSprint++;
      _phase = TimerPhase.sprint;
      _remainingSeconds = sprintSeconds;
    }
    notifyListeners();
  }

  void _finishSession() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _sessionComplete = true;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void resetSession() {
    exitImmersiveMode();
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _sessionActive = false;
    _phase = TimerPhase.sprint;
    _remainingSeconds = sprintSeconds;
    _currentSprint = 1;
    _sessionComplete = false;
    notifyListeners();
  }

  void stopSession() {
    resetSession();
  }

  void setTotalSprints(int value) {
    if (_sessionActive) return;
    _totalSprints = value;
    _saveSettings();
    notifyListeners();
  }

  void setBreakMinutes(int value) {
    if (_sessionActive) return;
    _breakMinutes = value.clamp(minBreakMinutes, 30).toInt();
    _saveSettings();
    notifyListeners();
  }

  void setDailyGoal(int value) {
    _dailyGoal = value;
    _ensureTodayRecord();
    final key = dateKeyFor(DateTime.now());
    final current = _history[key]!;
    _history[key] = DailyRecord(
      dateKey: key,
      sprintsCompleted: current.sprintsCompleted,
      dailyGoal: _dailyGoal,
    );
    _saveSettings();
    _saveHistory();
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
