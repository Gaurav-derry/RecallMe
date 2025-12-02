import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class RecallLogo extends StatelessWidget {
  final double size;
  final bool showCheck;

  const RecallLogo({
    super.key,
    this.size = 48,
    this.showCheck = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble_rounded,
            size: size * 0.66,
            color: AppColors.primaryBlue,
          ),
          Text(
            'R',
            style: TextStyle(
              fontSize: size * 0.33,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (showCheck)
            Positioned(
              right: size * 0.2,
              bottom: size * 0.2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: size * 0.2,
                  color: AppColors.secondaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


