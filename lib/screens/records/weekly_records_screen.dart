import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../data/models/routine.dart';
import '../../providers/app_provider.dart';

class WeeklyRecordsScreen extends StatefulWidget {
  const WeeklyRecordsScreen({super.key});

  @override
  State<WeeklyRecordsScreen> createState() => _WeeklyRecordsScreenState();
}

class _WeeklyRecordsScreenState extends State<WeeklyRecordsScreen> {
  List<Routine> _routines = [];
  Map<String, List<_DayRecord>> _weeklyData = {};
  bool _isLoading = true;

  // Helper to format time from either old format (hour) or new format (minutes from midnight)
  String _formatTime(int timeValue) {
    final int hour;
    final int minute;
    if (timeValue < 24) {
      hour = timeValue;
      minute = 0;
    } else {
      hour = timeValue ~/ 60;
      minute = timeValue % 60;
    }
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final appProvider = context.read<AppProvider>();
    final routines = await appProvider.routineRepository.getAllRoutines();

    // Build weekly data from routines
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final weeklyData = <String, List<_DayRecord>>{};

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayKey = DateFormat('EEEE, MMM d').format(day);
      final records = <_DayRecord>[];

      for (final routine in routines) {
        // Check if routine was completed on this day
        final wasCompleted = routine.completionHistory.any(
          (date) =>
              date.year == day.year &&
              date.month == day.month &&
              date.day == day.day,
        );

        // Check if routine should appear on this day based on frequency
        bool shouldAppear = false;
        switch (routine.frequency) {
          case RoutineFrequency.daily:
          case RoutineFrequency.twiceDaily:
            shouldAppear = true;
            break;
          case RoutineFrequency.weekly:
            if (routine.scheduledDate != null) {
              shouldAppear = routine.scheduledDate!.weekday == day.weekday;
            }
            break;
          case RoutineFrequency.once:
            if (routine.scheduledDate != null) {
              shouldAppear =
                  routine.scheduledDate!.year == day.year &&
                  routine.scheduledDate!.month == day.month &&
                  routine.scheduledDate!.day == day.day;
            }
            break;
          case RoutineFrequency.custom:
            shouldAppear = true;
            break;
        }

        if (shouldAppear && day.isBefore(now.add(const Duration(days: 1)))) {
          final timeStr =
              routine.timesOfDay.isNotEmpty
                  ? _formatTime(routine.timesOfDay.first)
                  : '';

          records.add(
            _DayRecord(
              time: timeStr,
              title: routine.title,
              tag: routine.frequencyText,
              isCompleted: wasCompleted,
              imagePath: routine.imagePath,
            ),
          );
        }
      }

      if (records.isNotEmpty) {
        weeklyData[dayKey] = records;
      }
    }

    if (mounted) {
      setState(() {
        _routines = routines;
        _weeklyData = weeklyData;
        _isLoading = false;
      });
    }
  }

  List<double> get _weeklyProgress {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final progress = <double>[];

    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));

      if (day.isAfter(now)) {
        progress.add(0.0);
        continue;
      }

      int total = 0;
      int completed = 0;

      for (final routine in _routines) {
        bool shouldAppear = false;
        switch (routine.frequency) {
          case RoutineFrequency.daily:
          case RoutineFrequency.twiceDaily:
            shouldAppear = true;
            break;
          case RoutineFrequency.weekly:
            if (routine.scheduledDate != null) {
              shouldAppear = routine.scheduledDate!.weekday == day.weekday;
            }
            break;
          case RoutineFrequency.once:
            if (routine.scheduledDate != null) {
              shouldAppear =
                  routine.scheduledDate!.year == day.year &&
                  routine.scheduledDate!.month == day.month &&
                  routine.scheduledDate!.day == day.day;
            }
            break;
          case RoutineFrequency.custom:
            shouldAppear = true;
            break;
        }

        if (shouldAppear) {
          total++;
          final wasCompleted = routine.completionHistory.any(
            (date) =>
                date.year == day.year &&
                date.month == day.month &&
                date.day == day.day,
          );
          if (wasCompleted) completed++;
        }
      }

      progress.add(total > 0 ? completed / total : 0.0);
    }

    return progress;
  }

  int get _incompleteCount {
    int count = 0;
    final progress = _weeklyProgress;
    for (var p in progress) {
      if (p < 1.0 && p > 0) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildWeeklyChart(),
                        const SizedBox(height: 24),
                        _buildTimeline(),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.softShadow,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week\'s Records',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _incompleteCount > 0
                    ? '$_incompleteCount days with incomplete routines'
                    : 'All routines completed! 🎉',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.tealGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Past Records',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final progress = _weeklyProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final isToday = DateTime.now().weekday == index + 1;
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 10,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTop,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 100 * progress[index],
                        decoration: BoxDecoration(
                          gradient:
                              progress[index] == 1.0
                                  ? AppColors.tealGradient
                                  : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ).animate().scaleY(
                        begin: 0,
                        end: 1,
                        alignment: Alignment.bottomCenter,
                        duration: (600 + index * 80).ms,
                        curve: Curves.easeOutQuart,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isToday ? AppColors.primaryBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildTimeline() {
    if (_weeklyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 48,
                color: AppColors.textLight,
              ),
              SizedBox(height: 12),
              Text(
                'No routines recorded yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final sortedDays =
        _weeklyData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Routine History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedDays.map((day) => _buildTimelineDay(day, _weeklyData[day]!)),
      ],
    );
  }

  Widget _buildTimelineDay(String date, List<_DayRecord> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        ...items.asMap().entries.map(
          (entry) => _buildTimelineCard(entry.value, entry.key),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTimelineCard(_DayRecord item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border:
            item.isCompleted
                ? Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1.5,
                )
                : null,
      ),
      child: Row(
        children: [
          // Image or icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient:
                  item.isCompleted
                      ? AppColors.tealGradient
                      : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              image:
                  item.imagePath != null
                      ? DecorationImage(
                        image: FileImage(File(item.imagePath!)),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                item.imagePath == null
                    ? Icon(
                      item.isCompleted
                          ? Icons.check_rounded
                          : Icons.task_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                    : null,
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.time,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundTop,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  item.isCompleted
                      ? AppColors.success
                      : AppColors.textLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isCompleted ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.1);
  }
}

class _DayRecord {
  final String time;
  final String title;
  final String tag;
  final bool isCompleted;
  final String? imagePath;

  _DayRecord({
    required this.time,
    required this.title,
    required this.tag,
    required this.isCompleted,
    this.imagePath,
  });
}
