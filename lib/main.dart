import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'providers/app_provider.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/reminders/add_reminder_screen.dart';
import 'screens/people/people_screen.dart';
import 'screens/people/add_person_screen.dart';
import 'screens/face_recognition/who_is_this_screen.dart';
import 'screens/settings/pin_entry_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/caregiver_chat/caregiver_chat_screen.dart';
import 'screens/memories/add_memory_screen.dart';
import 'screens/routines/add_routine_screen.dart';
import 'screens/caregiver/caregiver_reports_screen.dart';
import 'screens/records/weekly_records_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const RecallMeApp());
}

class RecallMeApp extends StatelessWidget {
  const RecallMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      
      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);
      
      case AppRoutes.reminders:
        return _buildRoute(const RemindersScreen(), settings);
      
      case AppRoutes.addReminder:
        return _buildRoute(const AddReminderScreen(), settings);
      
      case AppRoutes.people:
        return _buildRoute(const PeopleScreen(), settings);
      
      case AppRoutes.addPerson:
        return _buildRoute(const AddPersonScreen(), settings);
      
      case AppRoutes.whoIsThis:
        return _buildRoute(const WhoIsThisScreen(), settings);
      
      case AppRoutes.pinEntry:
        return _buildRoute(const PinEntryScreen(), settings);
      
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      
      case AppRoutes.caregiverChat:
        return _buildRoute(const CaregiverChatScreen(), settings);
      
      // New routes
      case AppRoutes.addMemory:
        return _buildRoute(const AddMemoryScreen(), settings);
      
      case AppRoutes.addRoutine:
        return _buildRoute(const AddRoutineScreen(), settings);
      
      case AppRoutes.caregiverReports:
        return _buildRoute(const CaregiverReportsScreen(), settings);
      
      case AppRoutes.weeklyRecords:
        return _buildRoute(const WeeklyRecordsScreen(), settings);
      
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
