import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

/// Speech bubble for displaying conversation
class SpeechBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isLoading;

  const SpeechBubble({
    super.key,
    required this.text,
    this.isUser = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 16,
          right: isUser ? 16 : 48,
          top: 8,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? _buildLoadingIndicator()
            : Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(
      begin: isUser ? 0.2 : -0.2,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
          decoration: const BoxDecoration(
            color: AppColors.textLight,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .fadeIn(
              delay: Duration(milliseconds: index * 200),
              duration: 400.ms,
            )
            .fadeOut(
              delay: Duration(milliseconds: 400 + index * 200),
              duration: 400.ms,
            );
      }),
    );
  }
}

/// Listening indicator
class ListeningIndicator extends StatelessWidget {
  const ListeningIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mic,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          const Text(
            'Listening...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .scaleXY(
                  begin: 0.5,
                  end: 1.0,
                  delay: Duration(milliseconds: index * 200),
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scaleXY(
                  begin: 1.0,
                  end: 0.5,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                );
          }),
        ],
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.8, 0.8),
      duration: 300.ms,
    );
  }
}


