import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/caregiver_report.dart';
import 'memory_repository.dart';
import 'routine_repository.dart';

class ReportRepository {
  static const String _boxName = 'caregiver_reports';
  late Box<CaregiverReport> _box;
  final MemoryRepository _memoryRepository;
  final RoutineRepository _routineRepository;

  ReportRepository({
    required MemoryRepository memoryRepository,
    required RoutineRepository routineRepository,
  })  : _memoryRepository = memoryRepository,
        _routineRepository = routineRepository;

  Future<void> init() async {
    _box = await Hive.openBox<CaregiverReport>(_boxName);
  }

  Future<List<CaregiverReport>> getAllReports() async {
    return _box.values.toList()
      ..sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
  }

  Future<CaregiverReport?> getCurrentWeekReport() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    
    return _box.values.where((r) =>
        r.weekStartDate.year == weekStart.year &&
        r.weekStartDate.month == weekStart.month &&
        r.weekStartDate.day == weekStart.day
    ).firstOrNull;
  }

  Future<CaregiverReport> generateWeeklyReport() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final memoriesRecalled = await _memoryRepository.getWeeklyRecallCount();
    final routinesCompleted = await _routineRepository.getWeeklyCompletionCount();
    final routinesMissed = await _routineRepository.getWeeklyMissedCount();
    final completionRate = await _routineRepository.getOverallCompletionRate();

    final report = CaregiverReport(
      id: const Uuid().v4(),
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      totalMemoriesRecalled: memoriesRecalled,
      totalRoutinesCompleted: routinesCompleted,
      totalRoutinesMissed: routinesMissed,
      overallCompletionRate: completionRate,
    );

    await _box.put(report.id, report);
    return report;
  }

  Future<Map<String, dynamic>> getQuickStats() async {
    final memoriesRecalled = await _memoryRepository.getWeeklyRecallCount();
    final routinesCompleted = await _routineRepository.getWeeklyCompletionCount();
    final routinesMissed = await _routineRepository.getWeeklyMissedCount();
    final completionRate = await _routineRepository.getOverallCompletionRate();

    return {
      'memoriesRecalled': memoriesRecalled,
      'routinesCompleted': routinesCompleted,
      'routinesMissed': routinesMissed,
      'completionRate': completionRate,
    };
  }
}


