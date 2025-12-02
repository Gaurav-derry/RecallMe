import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      setState(() => _error = 'Please enter your PIN');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final isValid = await appProvider.verifyCaregiverPin(_pinController.text);

      if (isValid) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.settings);
        }
      } else {
        setState(() => _error = 'Incorrect PIN. Please try again.');
        _pinController.clear();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Caregiver Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: AppColors.primaryBlue,
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
              
              const SizedBox(height: 32),
              
              const Text(
                'Enter Caregiver PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ).animate(delay: 100.ms).fadeIn(),
              
              const SizedBox(height: 8),
              
              const Text(
                'This area is protected for caregivers',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ).animate(delay: 200.ms).fadeIn(),
              
              const SizedBox(height: 40),
              
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _error,
                  hintText: '••••',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    letterSpacing: 16,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                ),
                onSubmitted: (_) => _verifyPin(),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}


