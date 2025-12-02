import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_colors.dart';
import '../../data/models/routine.dart';
import '../../providers/app_provider.dart';

class AddRoutineScreen extends StatefulWidget {
  final Routine? existingRoutine;

  const AddRoutineScreen({super.key, this.existingRoutine});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();

  RoutineFrequency _selectedFrequency = RoutineFrequency.daily;
  List<int> _selectedTimes = [8 * 60]; // Default 8:00 AM stored as minutes from midnight
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _titleController.text = widget.existingRoutine!.title;
      _descriptionController.text = widget.existingRoutine!.description ?? '';
      _placeController.text = widget.existingRoutine!.place ?? '';
      _selectedFrequency = widget.existingRoutine!.frequency;
      // Convert existing times - if they're small values (< 24), they're hours, otherwise minutes
      _selectedTimes = widget.existingRoutine!.timesOfDay.map((t) {
        if (t < 24) {
          return t * 60; // Convert hour to minutes
        }
        return t; // Already in minutes
      }).toList();
      _selectedDate = widget.existingRoutine!.scheduledDate ?? DateTime.now();
      if (widget.existingRoutine!.imagePath != null) {
        _selectedImage = File(widget.existingRoutine!.imagePath!);
      }
    }
  }

  // Helper to get hour from minutes
  int _getHour(int minutes) => minutes ~/ 60;
  
  // Helper to get minute from minutes
  int _getMinute(int minutes) => minutes % 60;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    }
  }

  Future<void> _selectTime(int index) async {
    final currentMinutes = _selectedTimes[index];
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _getHour(currentMinutes), minute: _getMinute(currentMinutes)),
    );
    if (time != null) {
      setState(() {
        _selectedTimes[index] = time.hour * 60 + time.minute; // Store as minutes from midnight
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final appProvider = context.read<AppProvider>();
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      final routine = Routine(
        id: widget.existingRoutine?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        imagePath: _selectedImage?.path,
        frequency: _selectedFrequency,
        timesOfDay: _selectedTimes,
        place: _placeController.text.trim().isNotEmpty
            ? _placeController.text.trim()
            : null,
        scheduledDate: _selectedDate,
        isActive: true,
        createdAt: widget.existingRoutine?.createdAt ?? DateTime.now(),
        completionHistory: widget.existingRoutine?.completionHistory ?? [],
        notificationId: widget.existingRoutine?.notificationId ?? notificationId,
      );

      if (widget.existingRoutine != null) {
        await appProvider.routineRepository.updateRoutine(routine);
      } else {
        await appProvider.routineRepository.addRoutine(routine);
      }

      // Schedule notifications
      await _scheduleNotifications(routine, appProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRoutine != null
                ? 'Routine updated successfully!'
                : 'Routine created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving routine: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _scheduleNotifications(Routine routine, AppProvider appProvider) async {
    final notificationService = appProvider.notificationService;
    
    // Cancel existing notifications for all time slots
    for (int i = 0; i < 10; i++) {
      await notificationService.cancelNotification(routine.notificationId + i);
    }

    bool anyScheduled = false;

    // Schedule based on frequency
    for (int i = 0; i < routine.timesOfDay.length; i++) {
      final totalMinutes = routine.timesOfDay[i];
      // Handle both old format (hour only < 24) and new format (minutes from midnight)
      final hour = totalMinutes < 24 ? totalMinutes : totalMinutes ~/ 60;
      final minute = totalMinutes < 24 ? 0 : totalMinutes % 60;
      final notifId = routine.notificationId + i;
      bool scheduled = false;
      
      switch (routine.frequency) {
        case RoutineFrequency.once:
          final scheduledTime = DateTime(
            routine.scheduledDate!.year,
            routine.scheduledDate!.month,
            routine.scheduledDate!.day,
            hour,
            minute,
          );
          if (scheduledTime.isAfter(DateTime.now())) {
            scheduled = await notificationService.scheduleNotification(
              id: notifId,
              title: '⏰ ${routine.title}',
              body: routine.place != null
                  ? 'Time for your routine at ${routine.place}'
                  : 'Time for your routine',
              scheduledTime: scheduledTime,
            );
          }
          break;
        case RoutineFrequency.daily:
        case RoutineFrequency.twiceDaily:
          scheduled = await notificationService.scheduleDailyNotification(
            id: notifId,
            title: '⏰ ${routine.title}',
            body: routine.place != null
                ? 'Time for your routine at ${routine.place}'
                : 'Time for your daily routine',
            hour: hour,
            minute: minute,
          );
          break;
        case RoutineFrequency.weekly:
          scheduled = await notificationService.scheduleWeeklyNotification(
            id: notifId,
            title: '⏰ ${routine.title}',
            body: routine.place != null
                ? 'Time for your weekly routine at ${routine.place}'
                : 'Time for your weekly routine',
            weekday: routine.scheduledDate?.weekday ?? DateTime.now().weekday,
            hour: hour,
            minute: minute,
          );
          break;
        case RoutineFrequency.custom:
          break;
      }
      
      if (scheduled) anyScheduled = true;
    }

    // Show confirmation notification
    if (anyScheduled) {
      await notificationService.showNotification(
        title: '✅ Routine Saved',
        body: 'You will be reminded for "${routine.title}"',
      );
    }
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePicker(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Routine Title',
                          hint: 'e.g., Take Morning Medicine',
                          icon: Icons.title_rounded,
                          validator: (v) => v?.isEmpty ?? true ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFrequencyPicker(),
                        const SizedBox(height: 16),
                        _buildTimePicker(),
                        const SizedBox(height: 16),
                        if (_selectedFrequency == RoutineFrequency.once ||
                            _selectedFrequency == RoutineFrequency.weekly)
                          _buildDatePicker(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _placeController,
                          label: 'Place (Optional)',
                          hint: 'Where does this happen?',
                          icon: Icons.place_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description (Optional)',
                          hint: 'Any additional details...',
                          icon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.existingRoutine != null ? 'Edit Routine' : 'Create Routine',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _selectedImage == null ? AppColors.tealGradient : null,
          borderRadius: BorderRadius.circular(24),
          image: _selectedImage != null
              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
              : null,
          boxShadow: AppColors.cardShadow,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add routine photo',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildFrequencyPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.repeat_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text(
                'Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RoutineFrequency.values.map((freq) {
              final isSelected = _selectedFrequency == freq;
              final labels = {
                RoutineFrequency.once: 'Once',
                RoutineFrequency.daily: 'Daily',
                RoutineFrequency.twiceDaily: 'Twice Daily',
                RoutineFrequency.weekly: 'Weekly',
                RoutineFrequency.custom: 'Custom',
              };

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFrequency = freq;
                    if (freq == RoutineFrequency.twiceDaily) {
                      _selectedTimes = [8, 20];
                    } else {
                      _selectedTimes = [8];
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.purpleGradient : null,
                    color: isSelected ? null : AppColors.backgroundTop,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    labels[freq]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  gradient: AppColors.warmGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Text(
                'Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_selectedTimes.length, (index) {
              final totalMinutes = _selectedTimes[index];
              final hour = _getHour(totalMinutes);
              final minute = _getMinute(totalMinutes);
              final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              final timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
              
              return GestureDetector(
                onTap: () => _selectTime(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            const Text(
              'Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveRoutine,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                widget.existingRoutine != null ? 'Update Routine' : 'Save Routine',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}

