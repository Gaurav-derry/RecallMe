import 'package:hive/hive.dart';

part 'routine.g.dart';

@HiveType(typeId: 11)
enum RoutineFrequency {
  @HiveField(0)
  once,
  @HiveField(1)
  daily,
  @HiveField(2)
  twiceDaily,
  @HiveField(3)
  weekly,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 12)
class Routine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? imagePath; // Routine photo

  @HiveField(4)
  RoutineFrequency frequency;

  @HiveField(5)
  List<int> timesOfDay; // Hours (e.g., [8, 20] for 8 AM and 8 PM)

  @HiveField(6)
  String? place; // Location

  @HiveField(7)
  DateTime? scheduledDate; // For one-time schedules

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  List<DateTime> completionHistory; // Track when completed

  @HiveField(11)
  int notificationId;

  Routine({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    this.frequency = RoutineFrequency.daily,
    this.timesOfDay = const [8],
    this.place,
    this.scheduledDate,
    this.isActive = true,
    DateTime? createdAt,
    this.completionHistory = const [],
    this.notificationId = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompletedToday {
    final now = DateTime.now();
    return completionHistory.any((date) =>
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
  }

  int get completionRate {
    if (completionHistory.isEmpty) return 0;
    final daysActive = DateTime.now().difference(createdAt).inDays + 1;
    return ((completionHistory.length / daysActive) * 100).clamp(0, 100).toInt();
  }

  String get frequencyText {
    switch (frequency) {
      case RoutineFrequency.once:
        return 'Once';
      case RoutineFrequency.daily:
        return 'Daily';
      case RoutineFrequency.twiceDaily:
        return 'Twice Daily';
      case RoutineFrequency.weekly:
        return 'Weekly';
      case RoutineFrequency.custom:
        return 'Custom';
    }
  }

  Routine copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    RoutineFrequency? frequency,
    List<int>? timesOfDay,
    String? place,
    DateTime? scheduledDate,
    bool? isActive,
    DateTime? createdAt,
    List<DateTime>? completionHistory,
    int? notificationId,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      frequency: frequency ?? this.frequency,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      place: place ?? this.place,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      completionHistory: completionHistory ?? this.completionHistory,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

