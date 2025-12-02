import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/reminder.dart';
import '../../providers/app_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/recall_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late ReminderProvider _reminderProvider;

  @override
  void initState() {
    super.initState();
    _initProvider();
  }

  void _initProvider() {
    final appProvider = context.read<AppProvider>();
    _reminderProvider = ReminderProvider(
      repository: appProvider.reminderRepository,
      notificationService: appProvider.notificationService,
    );
    _reminderProvider.loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _reminderProvider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Reminders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<ReminderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.reminders.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: provider.loadReminders,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Overdue
                  if (provider.overdueReminders.isNotEmpty) ...[
                    _buildSectionHeader('Overdue', AppColors.error),
                    ...provider.overdueReminders.map((r) => _buildReminderCard(r)),
                  ],
                  
                  // Today
                  if (provider.todayReminders.isNotEmpty) ...[
                    _buildSectionHeader('Today', AppColors.primaryBlue),
                    ...provider.todayReminders.map((r) => _buildReminderCard(r)),
                  ],
                  
                  // Tomorrow
                  if (provider.tomorrowReminders.isNotEmpty) ...[
                    _buildSectionHeader('Tomorrow', AppColors.secondaryGreen),
                    ...provider.tomorrowReminders.map((r) => _buildReminderCard(r)),
                  ],
                  
                  // This Week
                  if (provider.thisWeekReminders.isNotEmpty) ...[
                    _buildSectionHeader('This Week', AppColors.textSecondary),
                    ...provider.thisWeekReminders.map((r) => _buildReminderCard(r)),
                  ],
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addReminder)
              .then((_) => _reminderProvider.loadReminders()),
          backgroundColor: AppColors.primaryBlue,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Reminder',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              size: 60,
              color: AppColors.primaryBlue,
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),
          const Text(
            'No Reminders Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          const Text(
            'Add your first reminder\nto stay on track',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final timeFormat = DateFormat('h:mm a');
    
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _reminderProvider.deleteReminder(reminder.id),
      child: ReminderCard(
        title: reminder.title,
        description: reminder.description,
        time: timeFormat.format(reminder.dateTime),
        isCompleted: reminder.status == ReminderStatus.completed,
        isImportant: reminder.isImportant,
        onTap: () => _showReminderDetails(reminder),
        onComplete: () => _reminderProvider.markCompleted(reminder.id),
      ),
    );
  }

  void _showReminderDetails(Reminder reminder) {
    final appProvider = context.read<AppProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              reminder.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (reminder.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reminder.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d • h:mm a').format(reminder.dateTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      appProvider.assistantService.speak(reminder.ttsDescription);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Read Aloud'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _reminderProvider.markCompleted(reminder.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


