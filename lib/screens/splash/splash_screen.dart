import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/doodle_mascot.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _sparkleController;
  
  String? _initError;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _playAnimationSequence();
  }

  Future<void> _playAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showContent = true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appProvider = context.read<AppProvider>();
    try {
      await appProvider.initialize();
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1200));
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    if (appProvider.isOnboardingComplete) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF6E8), // Warm cream top
              Color(0xFFF9EDC7), // Soft yellow middle
              Color(0xFFFAF7F2), // Light sand bottom
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft background doodle blobs
            ..._buildBackgroundBlobs(),

            // Floating sparkles
            ..._buildSparkles(),

            // Main content
            if (_showContent) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Doodle Mascot with floating animation
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final float = Tween<double>(begin: 0, end: 8).animate(
                        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut)
                      ).value;
                      return Transform.translate(
                        offset: Offset(0, -float),
                        child: child,
                      );
                    },
                    child: const DoodleMascot(size: 140, animate: true, showSparkles: true),
                  ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App Name with hand-drawn style
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryOrange.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline in warm container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryOrange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      AppConstants.tagline,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.3),
                  
                  const Spacer(flex: 2),
                  
                  // Loading indicator
                  if (_initError == null)
                    _buildLoadingIndicator()
                  else
                    _buildRetryButton(),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundBlobs() {
    return [
      // Top left blob
      Positioned(
        top: -50,
        left: -30,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryYellow.withOpacity(0.5),
          ),
        ).animate().fadeIn(duration: 1000.ms),
      ),
      // Bottom right blob
      Positioned(
        bottom: -60,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentPeach.withOpacity(0.4),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 1000.ms),
      ),
      // Center left blob
      Positioned(
        left: -60,
        top: MediaQuery.of(context).size.height * 0.4,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentCoral.withOpacity(0.2),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),
      ),
    ];
  }

  List<Widget> _buildSparkles() {
    final random = math.Random(42);
    return List.generate(8, (index) {
      final x = random.nextDouble() * MediaQuery.of(context).size.width;
      final y = random.nextDouble() * MediaQuery.of(context).size.height;
      final size = 6.0 + random.nextDouble() * 6;
      
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            final opacity = (math.sin(_sparkleController.value * math.pi * 2 + index) + 1) / 2;
            return Opacity(opacity: opacity * 0.7, child: child);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.doodleSparkle,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.doodleSparkle.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: (index * 200).ms)
                .then()
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.3, 1.3),
                  duration: 400.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.3, 1.3),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading your memories...',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildRetryButton() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 32),
              const SizedBox(height: 8),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _initError = null;
            });
            _initializeApp();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
