import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState();

  // Water tracking
  int _waterCount = 0;
  int _dailyWaterGoal = 8; // default glasses per day

  // Progress tracking (0..1)
  double _weeklyProgress = 0.0;

  // Theme
  bool _darkMode = false;

  // Steps goal and weekly history (Mon..Sun)
  int _stepGoal = 10000;
  List<int> _weeklySteps = List<int>.filled(7, 0, growable: false);

  bool _initialized = false;
  bool get initialized => _initialized;

  int get waterCount => _waterCount;
  int get dailyWaterGoal => _dailyWaterGoal;
  double get weeklyProgress => _weeklyProgress;
  bool get darkMode => _darkMode;
  int get stepGoal => _stepGoal;
  List<int> get weeklySteps => List<int>.unmodifiable(_weeklySteps);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _waterCount = prefs.getInt('waterCount') ?? 0;
    _dailyWaterGoal = prefs.getInt('dailyWaterGoal') ?? 8;
    _weeklyProgress = prefs.getDouble('weeklyProgress') ?? 0.0;
    _darkMode = prefs.getBool('darkMode') ?? false;
    _stepGoal = prefs.getInt('stepGoal') ?? 10000;
    final stepsStored = prefs.getStringList('weeklySteps');
    if (stepsStored != null && stepsStored.length == 7) {
      _weeklySteps = stepsStored.map((e) => int.tryParse(e) ?? 0).toList(growable: false);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  void incrementWater() {
    _waterCount += 1;
    notifyListeners();
    _saveInt('waterCount', _waterCount);
  }

  void resetWaterForToday() {
    _waterCount = 0;
    notifyListeners();
    _saveInt('waterCount', _waterCount);
  }

  void setDailyWaterGoal(int goal) {
    if (goal < 1) return;
    _dailyWaterGoal = goal;
    notifyListeners();
    _saveInt('dailyWaterGoal', _dailyWaterGoal);
  }

  void setWeeklyProgress(double value) {
    if (value < 0.0) value = 0.0;
    if (value > 1.0) value = 1.0;
    _weeklyProgress = value;
    notifyListeners();
    _saveDouble('weeklyProgress', _weeklyProgress);
  }

  void toggleDarkMode(bool enabled) async {
    _darkMode = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
  }

  Future<void> setStepGoal(int goal) async {
    if (goal < 1000) return; // sanity
    _stepGoal = goal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stepGoal', _stepGoal);
  }

  Future<void> recordTodaySteps(int steps) async {
    // Map DateTime.monday..sunday -> indices 0..6
    final now = DateTime.now();
    final weekdayIndex = (now.weekday - DateTime.monday).clamp(0, 6);
    _weeklySteps = List<int>.from(_weeklySteps);
    _weeklySteps[weekdayIndex] = steps;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('weeklySteps', _weeklySteps.map((e) => e.toString()).toList(growable: false));
  }
}


