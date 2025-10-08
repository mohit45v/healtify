import 'dart:async';
import 'package:health/health.dart';

class HealthService {
  HealthService();

  final Health _health = Health();

  Future<bool> requestPermissions() async {
    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    final granted = await _health.requestAuthorization(types, permissions: permissions);
    return granted;
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final steps = await _health.getTotalStepsInInterval(start, now);
      return steps ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double?> getLatestHeartRate() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 3));
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      return (data.first.value as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<double> getTodayActiveEnergy() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final samples = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      double total = 0.0;
      for (final s in samples) {
        final v = s.value;
        if (v is num) total += v.toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }
}

extension on HealthValue {
  num toDouble() {
    if (this is num) {
      return this as num;
    } else if (this is String) {
      return num.tryParse(this as String) ?? (throw Exception('Cannot convert String to num'));
    } else {
      throw Exception('Cannot convert HealthValue to num');
    }
  }
}


