import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

/// Card widget with RecallMe styling
class RecallCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;

  const RecallCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }
}

/// Reminder card widget
class ReminderCard extends StatelessWidget {
  final String title;
  final String? description;
  final String time;
  final bool isCompleted;
  final bool isImportant;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const ReminderCard({
    super.key,
    required this.title,
    this.description,
    required this.time,
    this.isCompleted = false,
    this.isImportant = false,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return RecallCard(
      onTap: onTap,
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isImportant
                  ? AppColors.accentYellow.withOpacity(0.15)
                  : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time_filled,
                  size: 20,
                  color: isImportant ? AppColors.warning : AppColors.primaryBlue,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isImportant ? AppColors.warning : AppColors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
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
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Complete button
          if (onComplete != null && !isCompleted)
            IconButton(
              onPressed: onComplete,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(
                    color: AppColors.secondaryGreen,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 20,
                  color: AppColors.secondaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Person card widget
class PersonCard extends StatelessWidget {
  final String name;
  final String relation;
  final String? imagePath;
  final VoidCallback? onTap;

  const PersonCard({
    super.key,
    required this.name,
    required this.relation,
    this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RecallCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withOpacity(0.1),
              image: imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null
                ? const Icon(
                    Icons.person,
                    size: 30,
                    color: AppColors.primaryBlue,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relation,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Next reminder card for home screen
class NextReminderCard extends StatelessWidget {
  final String? title;
  final String? time;
  final VoidCallback? onTap;

  const NextReminderCard({
    super.key,
    this.title,
    this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasReminder = title != null && time != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'UP NEXT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (hasReminder) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else
                  const Text(
                    'No upcoming reminders\nYou\'re all caught up!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
