import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/routine.dart';
import '../../providers/app_provider.dart';
import '../records/weekly_records_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  // Helper to format time from either old format (hour) or new format (minutes from midnight)
  String _formatTime(int timeValue) {
    final int hour;
    final int minute;
    if (timeValue < 24) {
      // Old format: just hour
      hour = timeValue;
      minute = 0;
    } else {
      // New format: minutes from midnight
      hour = timeValue ~/ 60;
      minute = timeValue % 60;
    }
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  List<Routine> _allRoutines = [];
  List<Routine> _filteredRoutines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final appProvider = context.read<AppProvider>();
    final routines = await appProvider.routineRepository.getAllRoutines();
    if (mounted) {
      setState(() {
        _allRoutines = routines;
        _isLoading = false;
      });
      _filterRoutinesForDate(_selectedDate);
    }
  }

  void _filterRoutinesForDate(DateTime date) {
    final filtered = _allRoutines.where((routine) {
      // Check if routine applies to this date based on frequency
      switch (routine.frequency) {
        case RoutineFrequency.once:
          if (routine.scheduledDate == null) return false;
          return _isSameDay(routine.scheduledDate!, date);
        case RoutineFrequency.daily:
        case RoutineFrequency.twiceDaily:
          // Daily routines apply every day after creation
          return !date.isBefore(DateTime(routine.createdAt.year, routine.createdAt.month, routine.createdAt.day));
        case RoutineFrequency.weekly:
          if (routine.scheduledDate == null) return false;
          return routine.scheduledDate!.weekday == date.weekday &&
              !date.isBefore(DateTime(routine.createdAt.year, routine.createdAt.month, routine.createdAt.day));
        case RoutineFrequency.custom:
          return true;
      }
    }).toList();

    setState(() => _filteredRoutines = filtered);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isRoutineCompletedOnDate(Routine routine, DateTime date) {
    return routine.completionHistory.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
  }

  bool _isDatePassed(DateTime date) {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildCalendarStrip(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTaskList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addRoutine).then((_) => _loadRoutines()),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _isSameDay(_selectedDate, DateTime.now())
                    ? 'Today\'s Schedule'
                    : DateFormat('EEEE').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeeklyRecordsScreen()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryOrange.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              'View Report',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 7)); // Start from 7 days ago
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final isPast = _isDatePassed(date) && !isToday;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _filterRoutinesForDate(date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : (isPast ? AppColors.lightSand : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primaryOrange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    : AppColors.softShadow,
                border: isToday && !isSelected ? Border.all(color: AppColors.primaryOrange, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white.withOpacity(0.8) : (isPast ? AppColors.textLight : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : (isPast ? AppColors.textLight : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    if (_filteredRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.creamGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_available, size: 40, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a routine to get started',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Sort by time
    _filteredRoutines.sort((a, b) {
      final aTime = a.timesOfDay.isNotEmpty ? a.timesOfDay.first : 0;
      final bTime = b.timesOfDay.isNotEmpty ? b.timesOfDay.first : 0;
      return aTime.compareTo(bTime);
    });

    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_filteredRoutines.where((r) => _isRoutineCompletedOnDate(r, _selectedDate)).length}/${_filteredRoutines.length} done',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._filteredRoutines.asMap().entries.map((entry) {
            final index = entry.key;
            final routine = entry.value;
            return _buildTaskItem(routine, index);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Routine routine, int index) {
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : 'Any time';

    final isCompleted = _isRoutineCompletedOnDate(routine, _selectedDate);
    final isPastDate = _isDatePassed(_selectedDate);
    final isMissed = isPastDate && !isCompleted;

    return GestureDetector(
      onTap: () => _showRoutineDetail(routine),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
          border: isCompleted
              ? Border.all(color: AppColors.success.withOpacity(0.4), width: 2)
              : isMissed
                  ? Border.all(color: AppColors.missed.withOpacity(0.4), width: 2)
                  : null,
        ),
        child: Row(
          children: [
            // Image/Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? AppColors.tealGradient
                    : isMissed
                        ? AppColors.missedGradient
                        : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                image: routine.imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(routine.imagePath!)),
                        fit: BoxFit.cover,
                        colorFilter: isMissed ? ColorFilter.mode(Colors.grey.withOpacity(0.5), BlendMode.saturation) : null,
                      )
                    : null,
              ),
              child: routine.imagePath == null
                  ? Icon(
                      isCompleted ? Icons.check_rounded : (isMissed ? Icons.close_rounded : Icons.task_alt_rounded),
                      color: Colors.white,
                      size: 26,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Time
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    timeStr.split(' ')[0],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isMissed ? AppColors.textLight : AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    timeStr.split(' ')[1],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: isMissed ? AppColors.textLight : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isMissed ? AppColors.textLight : (isCompleted ? AppColors.textSecondary : AppColors.textPrimary),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.1)
                              : isMissed
                                  ? AppColors.missed.withOpacity(0.1)
                                  : AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompleted ? '✓ Completed' : (isMissed ? '✗ Missed' : 'Pending'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? AppColors.success : (isMissed ? AppColors.missed : AppColors.primaryOrange),
                          ),
                        ),
                      ),
                      if (routine.place != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.place_outlined, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text(
                          routine.place!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status indicator
            if (!isPastDate)
              GestureDetector(
                onTap: () async {
                  final appProvider = context.read<AppProvider>();
                  if (isCompleted) {
                    await appProvider.routineRepository.unmarkCompleted(routine.id);
                  } else {
                    await appProvider.routineRepository.markCompleted(routine.id);
                  }
                  _loadRoutines();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isCompleted ? AppColors.tealGradient : null,
                    border: isCompleted ? null : Border.all(color: AppColors.textLight, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1),
    );
  }

  void _showRoutineDetail(Routine routine) {
    final isCompleted = _isRoutineCompletedOnDate(routine, _selectedDate);
    final isPastDate = _isDatePassed(_selectedDate);
    final isMissed = isPastDate && !isCompleted;
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isCompleted ? AppColors.tealGradient : (isMissed ? AppColors.missedGradient : AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(24),
                        image: routine.imagePath != null
                            ? DecorationImage(image: FileImage(File(routine.imagePath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: routine.imagePath == null
                          ? Center(child: Icon(Icons.task_alt_rounded, size: 64, color: Colors.white54))
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(routine.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withOpacity(0.15)
                            : isMissed
                                ? AppColors.missed.withOpacity(0.15)
                                : AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : (isMissed ? Icons.cancel : Icons.pending),
                            size: 18,
                            color: isCompleted ? AppColors.success : (isMissed ? AppColors.missed : AppColors.warning),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleted ? 'Completed' : (isMissed ? 'Missed' : 'Pending'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCompleted ? AppColors.success : (isMissed ? AppColors.missed : AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info row
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(icon: Icons.access_time, label: timeStr, gradient: AppColors.primaryGradient),
                        _InfoChip(icon: Icons.repeat, label: routine.frequencyText, gradient: AppColors.purpleGradient),
                        if (routine.place != null)
                          _InfoChip(icon: Icons.place, label: routine.place!, gradient: AppColors.tealGradient),
                      ],
                    ),

                    if (routine.description != null && routine.description!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTop,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(routine.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
                      ),
                    ],

                    const SizedBox(height: 20),

                    if (!isPastDate)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final appProvider = context.read<AppProvider>();
                            if (isCompleted) {
                              await appProvider.routineRepository.unmarkCompleted(routine.id);
                            } else {
                              await appProvider.routineRepository.markCompleted(routine.id);
                            }
                            Navigator.pop(context);
                            _loadRoutines();
                          },
                          icon: Icon(isCompleted ? Icons.undo_rounded : Icons.check_rounded),
                          label: Text(isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: isCompleted ? AppColors.textSecondary : AppColors.success,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Edit and Delete buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, AppRoutes.addRoutine, arguments: routine).then((_) => _loadRoutines());
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primaryOrange, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDeleteRoutine(context, routine),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.error, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRoutine(BuildContext sheetContext, Routine routine) {
    final appProvider = context.read<AppProvider>();
    
    showDialog(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Delete Routine?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${routine.title}"?',
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All completion history will be lost.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cancel notifications for this routine
              for (int i = 0; i < 10; i++) {
                await appProvider.notificationService.cancelNotification(routine.notificationId + i);
              }
              
              // Delete the routine
              await appProvider.routineRepository.deleteRoutine(routine.id);
              
              if (mounted) {
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(sheetContext); // Close bottom sheet
                _loadRoutines();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Routine "${routine.title}" deleted'),
                    backgroundColor: AppColors.textSecondary,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;

  const _InfoChip({required this.icon, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
