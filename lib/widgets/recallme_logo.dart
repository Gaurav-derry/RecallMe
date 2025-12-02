import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

/// RecallMe Logo Widget
/// A memory bubble with "R" and a soft checkmark
class RecallMeLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool animated;

  const RecallMeLogo({
    super.key,
    this.size = 48,
    this.showTagline = false,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.bluePillGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Memory bubble shape
          Icon(
            Icons.chat_bubble_rounded,
            size: size * 0.7,
            color: Colors.white.withOpacity(0.3),
          ),
          // R letter
          Text(
            'R',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          // Checkmark indicator
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.check,
                size: size * 0.12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (animated) {
      logo = logo.animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        duration: 400.ms,
        curve: Curves.easeOutBack,
      );
    }

    if (showTagline) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          SizedBox(height: size * 0.3),
          Text(
            'RecallMe',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: size * 0.1),
          Text(
            'Helping you remember what matters',
            style: TextStyle(
              fontSize: size * 0.2,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return logo;
  }
}


