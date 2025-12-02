import 'package:hive/hive.dart';
import '../models/routine.dart';

class RoutineRepository {
  static const String _boxName = 'routines';
  late Box<Routine> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Routine>(_boxName);
  }

  Future<List<Routine>> getAllRoutines() async {
    return _box.values.toList()
      ..sort((a, b) => a.timesOfDay.first.compareTo(b.timesOfDay.first));
  }

  Future<List<Routine>> getActiveRoutines() async {
    return _box.values.where((r) => r.isActive).toList()
      ..sort((a, b) => a.timesOfDay.first.compareTo(b.timesOfDay.first));
  }

  Future<Routine?> getRoutineById(String id) async {
    return _box.values.where((r) => r.id == id).firstOrNull;
  }

  Future<void> addRoutine(Routine routine) async {
    await _box.put(routine.id, routine);
  }

  Future<void> updateRoutine(Routine routine) async {
    await _box.put(routine.id, routine);
  }

  Future<void> deleteRoutine(String id) async {
    await _box.delete(id);
  }

  Future<List<Routine>> getTodayRoutines() async {
    final now = DateTime.now();
    return _box.values.where((r) {
      if (!r.isActive) return false;
      
      switch (r.frequency) {
        case RoutineFrequency.once:
          return r.scheduledDate != null &&
              r.scheduledDate!.year == now.year &&
              r.scheduledDate!.month == now.month &&
              r.scheduledDate!.day == now.day;
        case RoutineFrequency.daily:
        case RoutineFrequency.twiceDaily:
          return true;
        case RoutineFrequency.weekly:
          return r.scheduledDate != null &&
              r.scheduledDate!.weekday == now.weekday;
        case RoutineFrequency.custom:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.timesOfDay.first.compareTo(b.timesOfDay.first));
  }

  Future<void> markCompleted(String routineId) async {
    final routine = await getRoutineById(routineId);
    if (routine != null) {
      final history = List<DateTime>.from(routine.completionHistory);
      history.add(DateTime.now());
      final updated = routine.copyWith(completionHistory: history);
      await updateRoutine(updated);
    }
  }

  Future<void> unmarkCompleted(String routineId) async {
    final routine = await getRoutineById(routineId);
    if (routine != null) {
      final now = DateTime.now();
      final history = routine.completionHistory
          .where((date) =>
              date.year != now.year ||
              date.month != now.month ||
              date.day != now.day)
          .toList();
      final updated = routine.copyWith(completionHistory: history);
      await updateRoutine(updated);
    }
  }

  Future<int> getWeeklyCompletionCount() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    for (final routine in _box.values) {
      count += routine.completionHistory
          .where((date) => date.isAfter(weekStart))
          .length;
    }
    return count;
  }

  Future<int> getWeeklyMissedCount() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int expectedCount = 0;
    int completedCount = 0;
    
    for (final routine in _box.values.where((r) => r.isActive)) {
      final daysInWeek = now.weekday;
      switch (routine.frequency) {
        case RoutineFrequency.daily:
          expectedCount += daysInWeek;
          break;
        case RoutineFrequency.twiceDaily:
          expectedCount += daysInWeek * 2;
          break;
        case RoutineFrequency.weekly:
          expectedCount += 1;
          break;
        default:
          expectedCount += daysInWeek;
      }
      
      completedCount += routine.completionHistory
          .where((date) => date.isAfter(weekStart))
          .length;
    }
    
    return (expectedCount - completedCount).clamp(0, expectedCount);
  }

  Future<double> getOverallCompletionRate() async {
    final routines = await getActiveRoutines();
    if (routines.isEmpty) return 100.0;
    
    double totalRate = 0;
    for (final routine in routines) {
      totalRate += routine.completionRate;
    }
    return totalRate / routines.length;
  }
}


