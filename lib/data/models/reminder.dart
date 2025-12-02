import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 1)
enum RepeatType {
  @HiveField(0)
  none,
  
  @HiveField(1)
  daily,
  
  @HiveField(2)
  weekly,
  
  @HiveField(3)
  monthly,
}

@HiveType(typeId: 2)
enum ReminderStatus {
  @HiveField(0)
  pending,
  
  @HiveField(1)
  completed,
  
  @HiveField(2)
  missed,
  
  @HiveField(3)
  snoozed,
}

@HiveType(typeId: 3)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  RepeatType repeatType;

  @HiveField(5)
  ReminderStatus status;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isImportant;

  Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.repeatType = RepeatType.none,
    this.status = ReminderStatus.pending,
    this.isImportant = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    RepeatType? repeatType,
    ReminderStatus? status,
    bool? isImportant,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      repeatType: repeatType ?? this.repeatType,
      status: status ?? this.status,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if the reminder is for today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if the reminder is for tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// Check if the reminder is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    return dateTime.isAfter(now) && dateTime.isBefore(weekEnd);
  }

  /// Check if the reminder is overdue
  bool get isOverdue {
    return dateTime.isBefore(DateTime.now()) && status == ReminderStatus.pending;
  }

  /// Get a friendly TTS description
  String get ttsDescription {
    final buffer = StringBuffer();
    buffer.write('$title ');
    
    if (description.isNotEmpty) {
      buffer.write(description);
      buffer.write('. ');
    }
    
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (isToday) {
      buffer.write('Today at $displayHour:${minute.toString().padLeft(2, '0')} $period');
    } else if (isTomorrow) {
      buffer.write('Tomorrow at $displayHour:${minute.toString().padLeft(2, '0')} $period');
    } else {
      buffer.write('On ${_monthName(dateTime.month)} ${dateTime.day} at $displayHour:${minute.toString().padLeft(2, '0')} $period');
    }
    
    return buffer.toString();
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  String toString() {
    return 'Reminder(id: $id, title: $title, dateTime: $dateTime, status: $status)';
  }
}


