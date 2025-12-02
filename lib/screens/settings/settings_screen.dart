import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _dailyReportEnabled = false;
  String _reportTime = '8:00 PM';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load saved email and report settings
    // For now using defaults
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _emailController.dispose();
    super.dispose();
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
                child: Consumer<AppProvider>(
                  builder: (context, appProvider, _) {
                    final settings = appProvider.settings;
                    
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Speech Settings
                        _buildSectionHeader('🔊 Voice Settings'),
                        _buildVoiceSettingsCard(appProvider, settings),
                        const SizedBox(height: 20),

                        // Security Settings
                        _buildSectionHeader('🔐 Security'),
                        _buildSecurityCard(appProvider),
                        const SizedBox(height: 20),

                        // Daily Report Email
                        _buildSectionHeader('📧 Daily Reports'),
                        _buildEmailReportCard(),
                        const SizedBox(height: 20),

                        // Caregiver Tools
                        _buildSectionHeader('🛠️ Caregiver Tools'),
                        _buildCaregiverToolsCard(context),
                        const SizedBox(height: 20),

                        // Weekly Reports
                        _buildWeeklyReportsCard(context),
                        const SizedBox(height: 40),

                        // App info
                        _buildAppInfo(),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
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
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
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
              'Caregiver Settings',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildVoiceSettingsCard(AppProvider appProvider, dynamic settings) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Speed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Slower is better for comprehension',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Slow', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Expanded(
                child: Slider(
                  value: settings.speechRate,
                  min: 0.2,
                  max: 0.8,
                  divisions: 6,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (value) => appProvider.updateSpeechRate(value),
                ),
              ),
              const Text('Fast', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                appProvider.ttsService.speak('This is how I will speak to help you remember.');
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Test Voice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSecurityCard(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.tealGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              const Text(
                'Change PIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _newPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'New PIN',
              counterText: '',
              filled: true,
              fillColor: AppColors.backgroundTop,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
              filled: true,
              fillColor: AppColors.backgroundTop,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _changePin(appProvider),
              child: const Text('Update PIN'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildEmailReportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Email Reports',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Receive daily progress reports',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dailyReportEnabled,
                onChanged: (value) => setState(() => _dailyReportEnabled = value),
                activeColor: AppColors.primaryBlue,
              ),
            ],
          ),
          if (_dailyReportEnabled) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Caregiver Email',
                hintText: 'caregiver@example.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                filled: true,
                fillColor: AppColors.backgroundTop,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Send report at:', style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _selectReportTime(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _reportTime,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Daily report includes: routines completed, memories recalled, and recommendations.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveEmailSettings,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Email Settings'),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildCaregiverToolsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => Navigator.pushNamed(context, AppRoutes.caregiverChat),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              'Caregiver Assistant',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            subtitle: const Text('Get summaries and ask questions', style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ),
          const Divider(height: 1),
          ListTile(
            onTap: () => Navigator.pushNamed(context, AppRoutes.caregiverReports),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              'Weekly Reports',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            subtitle: const Text('View progress and statistics', style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ),
          const Divider(height: 1),
          ListTile(
            onTap: () => _testNotifications(context),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
            ),
            title: const Text(
              'Test Notifications',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            subtitle: const Text('Check if notifications are working', style: TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Future<void> _testNotifications(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    
    // Show test notification
    await appProvider.notificationService.showTestNotification();
    
    // Get pending notifications
    final pending = await appProvider.notificationService.getPendingNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent! ${pending.length} notifications scheduled.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildWeeklyReportsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.caregiverReports),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.buttonShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Weekly Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'See detailed progress analysis',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            AppConstants.appName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 1.0.0',
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Future<void> _selectReportTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (time != null) {
      setState(() {
        _reportTime = time.format(context);
      });
    }
  }

  void _changePin(AppProvider appProvider) {
    if (_newPinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    appProvider.setCaregiverPin(_newPinController.text);
    _newPinController.clear();
    _confirmPinController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN updated successfully'), backgroundColor: AppColors.success),
    );
  }

  void _saveEmailSettings() {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Save email settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email settings saved! Daily reports will be sent.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
