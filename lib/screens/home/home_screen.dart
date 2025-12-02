import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';
import '../../data/models/person.dart';
import '../../data/models/routine.dart';
import '../../data/models/memory.dart';
import '../schedule/schedule_screen.dart';
import '../tasks/daily_tasks_screen.dart';
import '../recall/recall_screen.dart';
import '../memories/memories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Start at Home (Index 2)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_currentIndex == 2) _buildHomeHeader(),
              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            color: AppColors.accentPurple,
            onTap: () => _showNotificationsSheet(),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Text(
                'RecallMe',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            color: AppColors.accentTeal,
            onTap: () => Navigator.pushNamed(context, AppRoutes.pinEntry),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _NotificationsSheet(onRefresh: () => setState(() {})),
    );
  }

  Widget _buildMainContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getBodyForIndex(_currentIndex),
    );
  }

  Widget _getBodyForIndex(int index) {
    switch (index) {
      case 0:
        return const MemoriesScreen();
      case 1:
        return const RecallScreen();
      case 2:
        return _HomeView(onNavigate: (idx) => setState(() => _currentIndex = idx));
      case 3:
        return const DailyTasksScreen();
      case 4:
        return const ScheduleScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.photo_library_outlined,
                activeIcon: Icons.photo_library_rounded,
                label: 'Memories',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavBarItem(
                icon: Icons.psychology_outlined,
                activeIcon: Icons.psychology_rounded,
                label: 'Recall',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              // Center Home Button - Always Highlighted & Circular
              _CenterHomeButton(
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavBarItem(
                icon: Icons.check_circle_outline_rounded,
                activeIcon: Icons.check_circle_rounded,
                label: 'Tasks',
                isSelected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavBarItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                label: 'Schedule',
                isSelected: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterHomeButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterHomeButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NotificationsSheet({required this.onRefresh});

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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, appProvider, _) {
                return FutureBuilder<List<Routine>>(
                  future: appProvider.routineRepository.getTodayRoutines(),
                  builder: (context, snapshot) {
                    final routines = snapshot.data ?? [];
                    final pendingRoutines = routines.where((r) => !r.isCompletedToday).toList();
                    
                    if (pendingRoutines.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textLight.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending notifications',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'All routines completed! 🎉',
                              style: TextStyle(fontSize: 14, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: pendingRoutines.length,
                      itemBuilder: (context, index) {
                        final routine = pendingRoutines[index];
                        final timeStr = routine.timesOfDay.isNotEmpty
                            ? _formatTime(routine.timesOfDay.first)
                            : '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundTop,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.warmGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.alarm_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      routine.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Scheduled for $timeStr',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await appProvider.routineRepository.markCompleted(routine.id);
                                  Navigator.pop(context);
                                  onRefresh();
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  final Function(int) onNavigate;

  const _HomeView({required this.onNavigate});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
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
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildDateCard(context),
                const SizedBox(height: 20),
                _buildWelcomeCard(context),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildTodayRoutines(context, appProvider),
                const SizedBox(height: 28),
                _buildMemoryGlimpse(context, appProvider),
                const SizedBox(height: 28),
                _buildPeopleSection(context, appProvider),
                const SizedBox(height: 28),
                _buildSaveMemoryBanner(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateCard(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  now.day.toString(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  DateFormat('MMM').format(now).toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(now),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(now),
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 4),
                Text(
                  _getGreeting(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    IconData icon = Icons.wb_sunny_rounded;
    LinearGradient gradient = AppColors.warmGradient;

    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
      icon = Icons.wb_sunny_outlined;
      gradient = AppColors.tealGradient;
    } else if (hour >= 17) {
      greeting = 'Good evening';
      icon = Icons.nights_stay_rounded;
      gradient = AppColors.purpleGradient;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      greeting,
                      style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "How can I help\nyou today?",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1).shimmer(delay: 1000.ms, duration: 1500.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.face_retouching_natural,
            label: 'Who Is This?',
            gradient: AppColors.primaryGradient,
            onTap: () => Navigator.pushNamed(context, AppRoutes.whoIsThis).then((_) => setState(() {})),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_task_rounded,
            label: 'Add Routine',
            gradient: AppColors.tealGradient,
            onTap: () => Navigator.pushNamed(context, AppRoutes.addRoutine).then((_) => setState(() {})),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_photo_alternate_rounded,
            label: 'Add Memory',
            gradient: AppColors.purpleGradient,
            onTap: () => Navigator.pushNamed(context, AppRoutes.addMemory).then((_) => setState(() {})),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayRoutines(BuildContext context, AppProvider appProvider) {
    return FutureBuilder<List<Routine>>(
      future: appProvider.routineRepository.getTodayRoutines(),
      builder: (context, snapshot) {
        final routines = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "📋 Today's Routines",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => widget.onNavigate(3),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (routines.isEmpty)
              _buildEmptyRoutineCard(context)
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return _RoutineCardHorizontal(
                      routine: routine,
                      index: index,
                      onTap: () => _showRoutineDetail(context, appProvider, routine),
                      onToggle: () async {
                        if (routine.isCompletedToday) {
                          await appProvider.routineRepository.unmarkCompleted(routine.id);
                        } else {
                          await appProvider.routineRepository.markCompleted(routine.id);
                        }
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showRoutineDetail(BuildContext context, AppProvider appProvider, Routine routine) {
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                    Text(routine.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.backgroundTop, borderRadius: BorderRadius.circular(16)),
                        child: Text(routine.description!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, AppRoutes.addRoutine, arguments: routine).then((_) => setState(() {}));
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primaryBlue, width: 2)),
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
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                            icon: Icon(routine.isCompletedToday ? Icons.undo_rounded : Icons.check_rounded),
                            label: Text(routine.isCompletedToday ? 'Undo' : 'Complete'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteRoutine(ctx, appProvider, routine),
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

  void _confirmDeleteRoutine(BuildContext sheetContext, AppProvider appProvider, Routine routine) {
    showDialog(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Routine?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${routine.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cancel notifications
              for (int i = 0; i < 10; i++) {
                await appProvider.notificationService.cancelNotification(routine.notificationId + i);
              }
              await appProvider.routineRepository.deleteRoutine(routine.id);
              Navigator.pop(dialogContext);
              Navigator.pop(sheetContext);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Routine "${routine.title}" deleted'), backgroundColor: AppColors.textSecondary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoutineCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addRoutine).then((_) => setState(() {})),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3), width: 2),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(gradient: AppColors.tealGradient, shape: BoxShape.circle),
              child: const Icon(Icons.add_task, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create your first routine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Set up daily tasks with reminders', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildMemoryGlimpse(BuildContext context, AppProvider appProvider) {
    return FutureBuilder<List<Memory>>(
      future: appProvider.memoryRepository.getAllMemories(),
      builder: (context, snapshot) {
        final memories = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💭 Memory Glimpse',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => widget.onNavigate(0),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (memories.isEmpty)
              _buildEmptyMemoriesCard(context)
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: memories.length > 5 ? 5 : memories.length,
                  itemBuilder: (context, index) {
                    final memory = memories[index];
                    return _MemoryGlimpseCard(
                      memory: memory,
                      index: index,
                      onTap: () => _showMemoryDetail(context, appProvider, memory),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showMemoryDetail(BuildContext context, AppProvider appProvider, Memory memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.warmGradient,
                        borderRadius: BorderRadius.circular(24),
                        image: memory.imagePath != null
                            ? DecorationImage(image: FileImage(File(memory.imagePath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: memory.imagePath == null
                          ? const Center(child: Icon(Icons.photo_rounded, size: 64, color: Colors.white54))
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(memory.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoChip(icon: Icons.calendar_today, label: memory.year.toString(), gradient: AppColors.primaryGradient),
                        _InfoChip(icon: Icons.person, label: memory.personName, gradient: AppColors.purpleGradient),
                        if (memory.category.isNotEmpty)
                          _InfoChip(icon: Icons.category, label: memory.category, gradient: AppColors.tealGradient),
                      ],
                    ),
                    if (memory.memoryWord.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Memory Word', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.warmGradient.scale(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '"${memory.memoryWord}"',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.backgroundTop, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.replay_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: 12),
                          Text('Recalled ${memory.recallCount} times', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, AppRoutes.addMemory, arguments: memory).then((_) => setState(() {}));
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.onNavigate(1); // Go to Recall tab
                            },
                            icon: const Icon(Icons.psychology_rounded),
                            label: const Text('Recall'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          appProvider.ttsService.speak(
                            'This is ${memory.name} from ${memory.year}. It features ${memory.personName}. ${memory.memoryWord}',
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Tell me about this'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteMemory(ctx, appProvider, memory),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: const Text('Delete Memory', style: TextStyle(color: AppColors.error)),
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

  void _confirmDeleteMemory(BuildContext sheetContext, AppProvider appProvider, Memory memory) {
    showDialog(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Memory?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${memory.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.memoryRepository.deleteMemory(memory.id);
              Navigator.pop(dialogContext);
              Navigator.pop(sheetContext);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Memory "${memory.name}" deleted'), backgroundColor: AppColors.textSecondary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMemoriesCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addMemory).then((_) => setState(() {})),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3), width: 2),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(gradient: AppColors.warmGradient, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Save your first memory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Capture moments to remember', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildPeopleSection(BuildContext context, AppProvider appProvider) {
    return FutureBuilder<List<Person>>(
      future: appProvider.personRepository.getAllPersons(),
      builder: (context, snapshot) {
        final people = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '👨‍👩‍👧‍👦 Your People',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.people),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (people.isEmpty)
              _buildEmptyPeopleCard(context)
            else
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return _PersonCard(
                      person: person,
                      index: index,
                      onTap: () => _showPersonInfo(context, person),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyPeopleCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addPerson).then((_) => setState(() {})),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.3), width: 2),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(gradient: AppColors.purpleGradient, shape: BoxShape.circle),
              child: const Icon(Icons.person_add, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add your first person', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Help me remember your loved ones', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildSaveMemoryBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.addMemory).then((_) => setState(() {})),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.buttonShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Save today's memory!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Capture a special moment', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1);
  }

  void _showPersonInfo(BuildContext context, Person person) {
    final appProvider = context.read<AppProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PersonInfoSheet(
        person: person,
        appProvider: appProvider,
        onDelete: () => setState(() {}),
      ),
    );
  }
}

// Helper Widgets

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _RoutineCardHorizontal extends StatelessWidget {
  final Routine routine;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _RoutineCardHorizontal({required this.routine, required this.index, required this.onTap, required this.onToggle});

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
  Widget build(BuildContext context) {
    final timeStr = routine.timesOfDay.isNotEmpty
        ? _formatTime(routine.timesOfDay.first)
        : '';
    final colors = [AppColors.primaryGradient, AppColors.tealGradient, AppColors.purpleGradient, AppColors.warmGradient];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
          border: routine.isCompletedToday ? Border.all(color: AppColors.success.withOpacity(0.3), width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: routine.isCompletedToday ? AppColors.tealGradient : colors[index % colors.length],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    routine.isCompletedToday ? Icons.check_rounded : Icons.task_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    routine.isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: routine.isCompletedToday ? AppColors.success : AppColors.textLight,
                    size: 22,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              routine.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: routine.isCompletedToday ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: routine.isCompletedToday ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
  }
}

class _MemoryGlimpseCard extends StatelessWidget {
  final Memory memory;
  final int index;
  final VoidCallback onTap;

  const _MemoryGlimpseCard({required this.memory, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradients = [AppColors.warmGradient, AppColors.tealGradient, AppColors.purpleGradient, AppColors.primaryGradient];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradients[index % gradients.length],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: memory.imagePath != null
                      ? DecorationImage(image: FileImage(File(memory.imagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: memory.imagePath == null
                    ? const Center(child: Icon(Icons.photo_rounded, color: Colors.white54, size: 32))
                    : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      memory.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${memory.personName} • ${memory.year}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final int index;
  final VoidCallback onTap;

  const _PersonCard({required this.person, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primaryGradient, AppColors.purpleGradient, AppColors.tealGradient, AppColors.warmGradient];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: colors[index % colors.length],
                shape: BoxShape.circle,
                image: person.imagePaths.isNotEmpty
                    ? DecorationImage(image: FileImage(File(person.imagePaths.first)), fit: BoxFit.cover)
                    : null,
              ),
              child: person.imagePaths.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 32) : null,
            ),
            const SizedBox(height: 10),
            Text(person.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(person.relation, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.2);
  }
}

class _PersonInfoSheet extends StatelessWidget {
  final Person person;
  final AppProvider appProvider;
  final VoidCallback? onDelete;

  const _PersonInfoSheet({required this.person, required this.appProvider, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              image: person.imagePaths.isNotEmpty ? DecorationImage(image: FileImage(File(person.imagePaths.first)), fit: BoxFit.cover) : null,
            ),
            child: person.imagePaths.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 50) : null,
          ),
          const SizedBox(height: 16),
          Text(person.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(20)),
            child: Text(person.relation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          if (person.notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.backgroundTop, borderRadius: BorderRadius.circular(16)),
                child: Text(person.notes, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5)),
              ),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  appProvider.ttsService.speak('This is ${person.name}, your ${person.relation}. ${person.notes}');
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Tell me about them'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.editPerson, arguments: person).then((_) => onDelete?.call());
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
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.error, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Person?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${person.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await appProvider.personRepository.deletePerson(person.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              onDelete?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${person.name} deleted'), backgroundColor: AppColors.textSecondary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
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

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({required this.icon, required this.activeIcon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryBlue : AppColors.textLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
