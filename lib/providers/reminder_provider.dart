import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/reminder.dart';
import '../data/repositories/reminder_repository.dart';
import '../services/notification_service.dart';

/// Provider for managing reminders
class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _repository;
  final NotificationService _notificationService;
  final _uuid = const Uuid();
  
  List<Reminder> _reminders = [];
  Reminder? _nextReminder;
  bool _isLoading = false;

  ReminderProvider({
    required ReminderRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

  List<Reminder> get reminders => _reminders;
  Reminder? get nextReminder => _nextReminder;
  bool get isLoading => _isLoading;

  List<Reminder> get todayReminders =>
      _reminders.where((r) => r.isToday).toList();
  
  List<Reminder> get tomorrowReminders =>
      _reminders.where((r) => r.isTomorrow).toList();
  
  List<Reminder> get thisWeekReminders =>
      _reminders.where((r) => r.isThisWeek && !r.isToday && !r.isTomorrow).toList();
  
  List<Reminder> get overdueReminders =>
      _reminders.where((r) => r.isOverdue).toList();

  /// Load all reminders
  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _reminders = await _repository.getAllReminders();
      _nextReminder = await _repository.getNextReminder();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new reminder
  Future<void> addReminder({
    required String title,
    String description = '',
    required DateTime dateTime,
    RepeatType repeatType = RepeatType.none,
    bool isImportant = false,
  }) async {
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title,
      description: description,
      dateTime: dateTime,
      repeatType: repeatType,
      isImportant: isImportant,
    );
    
    await _repository.addReminder(reminder);
    await _notificationService.scheduleReminder(reminder);
    await loadReminders();
  }

  /// Update an existing reminder
  Future<void> updateReminder(Reminder reminder) async {
    await _repository.updateReminder(reminder);
    await _notificationService.cancelReminder(reminder.id);
    await _notificationService.scheduleReminder(reminder);
    await loadReminders();
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    await _repository.deleteReminder(id);
    await _notificationService.cancelReminder(id);
    await loadReminders();
  }

  /// Mark reminder as completed
  Future<void> markCompleted(String id) async {
    await _repository.markAsCompleted(id);
    await loadReminders();
  }

  /// Mark reminder as missed
  Future<void> markMissed(String id) async {
    await _repository.markAsMissed(id);
    await loadReminders();
  }

  /// Get reminder by ID
  Future<Reminder?> getReminderById(String id) async {
    return await _repository.getReminderById(id);
  }
}


