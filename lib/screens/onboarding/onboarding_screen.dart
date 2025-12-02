import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/recallme_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _pinError;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_pinController.text.length < 4) {
      setState(() => _pinError = 'PIN must be at least 4 digits');
      return;
    }
    
    if (_pinController.text != _confirmPinController.text) {
      setState(() => _pinError = 'PINs do not match');
      return;
    }
    
    setState(() {
      _pinError = null;
      _isLoading = true;
    });
    
    try {
      final appProvider = context.read<AppProvider>();
      await appProvider.setCaregiverPin(_pinController.text);
      await appProvider.completeOnboarding();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? AppColors.primaryBlue
                              : AppColors.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomePage(),
                    _buildPinPage(),
                    _buildCompletedPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const RecallMeLogo(size: 140, showTagline: false),
          
          const SizedBox(height: 48),
          
          Text(
            'Welcome to RecallMe',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'I\'m here to help you remember your day, your loved ones, and what matters most.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Get Started', style: TextStyle(fontSize: 18)),
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.5),
        ],
      ),
    );
  }

  Widget _buildPinPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.success),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Create Caregiver PIN',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'This protects sensitive settings like adding people or changing configurations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Enter 4-6 digit PIN',
              counterText: '',
              errorText: _pinError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                if (_pinController.text.length >= 4 &&
                    _pinController.text == _confirmPinController.text) {
                  _nextPage();
                } else if (_pinController.text.length < 4) {
                  setState(() => _pinError = 'PIN must be at least 4 digits');
                } else {
                  setState(() => _pinError = 'PINs do not match');
                }
              },
              child: const Text('Save PIN', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success),
          ).animate().fadeIn().scale(curve: Curves.elasticOut),
          
          const SizedBox(height: 48),
          
          Text(
            'You\'re All Set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'RecallMe is ready to start helping you remember what matters.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Go to Home', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
