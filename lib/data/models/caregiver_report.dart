import 'package:hive/hive.dart';

part 'caregiver_report.g.dart';

@HiveType(typeId: 13)
class CaregiverReport extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime weekStartDate;

  @HiveField(2)
  DateTime weekEndDate;

  @HiveField(3)
  int totalMemoriesRecalled;

  @HiveField(4)
  int totalRoutinesCompleted;

  @HiveField(5)
  int totalRoutinesMissed;

  @HiveField(6)
  List<String> memoriesRecalledIds;

  @HiveField(7)
  List<String> routinesCompletedIds;

  @HiveField(8)
  double overallCompletionRate;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  DateTime generatedAt;

  CaregiverReport({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    this.totalMemoriesRecalled = 0,
    this.totalRoutinesCompleted = 0,
    this.totalRoutinesMissed = 0,
    this.memoriesRecalledIds = const [],
    this.routinesCompletedIds = const [],
    this.overallCompletionRate = 0.0,
    this.notes,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

