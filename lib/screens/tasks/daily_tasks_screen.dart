import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/routine.dart';
import '../../providers/app_provider.dart';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  List<Routine> _routines = [];
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
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final appProvider = context.read<AppProvider>();
    final routines = await appProvider.routineRepository.getTodayRoutines();
    if (mounted) {
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    }
  }

  double get _progress {
    if (_routines.isEmpty) return 0;
    return _routines.where((r) => r.isCompletedToday).length / _routines.length;
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _routines.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRoutines,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _routines.length,
                              itemBuilder: (context, index) {
                                final routine = _routines[index];
                                return _buildTaskCard(routine, index);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addRoutine).then((_) => _loadRoutines()),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Routine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Daily Routines',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _routines.isEmpty
                ? 'No routines for today'
                : 'You have completed ${(_progress * 100).toInt()}% of your routines',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundTop,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                widthFactor: _progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_task_rounded, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'No routines yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first daily routine',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Routine routine, int index) {
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : '';
    final colors = [AppColors.primaryGradient, AppColors.tealGradient, AppColors.purpleGradient, AppColors.warmGradient];

    return Dismissible(
      key: Key(routine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(routine);
      },
      onDismissed: (direction) async {
        final appProvider = context.read<AppProvider>();
        // Cancel notifications
        for (int i = 0; i < 10; i++) {
          await appProvider.notificationService.cancelNotification(routine.notificationId + i);
        }
        await appProvider.routineRepository.deleteRoutine(routine.id);
        _loadRoutines();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Routine "${routine.title}" deleted'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => _showRoutineDetail(routine),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
            border: routine.isCompletedToday ? Border.all(color: AppColors.success.withOpacity(0.3), width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(16),
                  image: routine.imagePath != null
                      ? DecorationImage(image: FileImage(File(routine.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: routine.imagePath == null
                    ? const Icon(Icons.task_alt_rounded, color: Colors.white, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routine.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: routine.isCompletedToday ? AppColors.textLight : AppColors.textPrimary,
                        decoration: routine.isCompletedToday ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (routine.place != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(routine.place!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final appProvider = context.read<AppProvider>();
                  if (routine.isCompletedToday) {
                    await appProvider.routineRepository.unmarkCompleted(routine.id);
                  } else {
                    await appProvider.routineRepository.markCompleted(routine.id);
                  }
                  _loadRoutines();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: routine.isCompletedToday ? AppColors.tealGradient : null,
                    color: routine.isCompletedToday ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: routine.isCompletedToday ? Colors.transparent : AppColors.textLight,
                      width: 2,
                    ),
                  ),
                  child: routine.isCompletedToday
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1),
    );
  }

  Future<bool> _showDeleteConfirmDialog(Routine routine) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Routine?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${routine.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showRoutineDetail(Routine routine) {
    final appProvider = context.read<AppProvider>();
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        image: routine.imagePath != null
                            ? DecorationImage(image: FileImage(File(routine.imagePath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: routine.imagePath == null
                          ? const Center(child: Icon(Icons.task_alt_rounded, size: 64, color: Colors.white54))
                          : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(routine.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    
                    // Info chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoChip(icon: Icons.access_time, label: timeStr, gradient: AppColors.primaryGradient),
                        _InfoChip(icon: Icons.repeat, label: routine.frequencyText, gradient: AppColors.tealGradient),
                        if (routine.place != null)
                          _InfoChip(icon: Icons.place, label: routine.place!, gradient: AppColors.purpleGradient),
                      ],
                    ),
                    
                    if (routine.description != null && routine.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTop,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(routine.description!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Completion status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: routine.isCompletedToday ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            routine.isCompletedToday ? Icons.check_circle_rounded : Icons.pending_rounded,
                            color: routine.isCompletedToday ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            routine.isCompletedToday ? 'Completed today!' : 'Not completed yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: routine.isCompletedToday ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primaryBlue, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (routine.isCompletedToday) {
                                await appProvider.routineRepository.unmarkCompleted(routine.id);
                              } else {
                                await appProvider.routineRepository.markCompleted(routine.id);
                              }
                              Navigator.pop(context);
                              _loadRoutines();
                            },
                            icon: Icon(routine.isCompletedToday ? Icons.undo_rounded : Icons.check_rounded),
                            label: Text(routine.isCompletedToday ? 'Undo' : 'Complete'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteRoutine(context, routine, appProvider),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: const Text('Delete Routine', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.error, width: 2),
                        ),
                      ),
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

  void _confirmDeleteRoutine(BuildContext context, Routine routine, AppProvider appProvider) {
    showDialog(
      context: context,
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
                Navigator.pop(context); // Close bottom sheet
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
