import 'package:hive/hive.dart';
import '../models/reminder.dart';
import '../../core/constants.dart';

class ReminderRepository {
  late Box<Reminder> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Reminder>(AppConstants.remindersBox);
  }

  Box<Reminder> get box => _box;

  Future<List<Reminder>> getAllReminders() async {
    final reminders = _box.values.toList();
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return reminders;
  }

  Future<Reminder?> getReminderById(String id) async {
    try {
      return _box.values.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Reminder>> getTodayReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _box.values
        .where((r) =>
            r.dateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(tomorrow))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Reminder>> getTomorrowReminders() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayAfter = tomorrow.add(const Duration(days: 1));

    return _box.values
        .where((r) =>
            r.dateTime.isAfter(tomorrow.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(dayAfter))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Reminder>> getThisWeekReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _box.values
        .where((r) =>
            r.dateTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
            r.dateTime.isBefore(weekEnd))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<Reminder?> getNextReminder() async {
    final now = DateTime.now();
    final upcoming = _box.values
        .where((r) => r.dateTime.isAfter(now) && r.status == ReminderStatus.pending)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  Future<List<Reminder>> getPendingReminders() async {
    return _box.values
        .where((r) => r.status == ReminderStatus.pending)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<List<Reminder>> getOverdueReminders() async {
    final now = DateTime.now();
    return _box.values
        .where((r) => r.dateTime.isBefore(now) && r.status == ReminderStatus.pending)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> addReminder(Reminder reminder) async {
    await _box.put(reminder.id, reminder);
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _box.put(reminder.id, reminder);
  }

  Future<void> deleteReminder(String id) async {
    await _box.delete(id);
  }

  Future<void> markAsCompleted(String id) async {
    final reminder = await getReminderById(id);
    if (reminder != null) {
      await updateReminder(reminder.copyWith(status: ReminderStatus.completed));
    }
  }

  Future<void> markAsMissed(String id) async {
    final reminder = await getReminderById(id);
    if (reminder != null) {
      await updateReminder(reminder.copyWith(status: ReminderStatus.missed));
    }
  }

  Future<void> close() async {
    await _box.close();
  }
}


