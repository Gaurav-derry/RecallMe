import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/env_config.dart';
import '../data/models/person.dart';
import '../data/models/reminder.dart';
import '../data/models/conversation_log.dart';
import '../data/models/app_settings.dart';
import '../data/models/memory.dart';
import '../data/models/routine.dart';
import '../data/models/caregiver_report.dart';
import '../data/repositories/person_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/memory_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/repositories/report_repository.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import '../services/face_recognition_service.dart';
import '../services/azure_openai_service.dart';
import '../services/assistant_service.dart';
import '../services/notification_service.dart';

/// Main Application Provider - manages all services and state
class AppProvider extends ChangeNotifier {
  // Repositories
  late final PersonRepository _personRepository;
  late final ReminderRepository _reminderRepository;
  late final SettingsRepository _settingsRepository;
  late final ConversationRepository _conversationRepository;
  late final MemoryRepository _memoryRepository;
  late final RoutineRepository _routineRepository;
  late final ReportRepository _reportRepository;

  // Services
  late final TtsService _ttsService;
  late final SttService _sttService;
  late final FaceRecognitionService _faceRecognitionService;
  late final AzureOpenAiService _azureOpenAiService;
  late final AssistantService _assistantService;
  late final NotificationService _notificationService;

  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PersonRepository get personRepository => _personRepository;
  ReminderRepository get reminderRepository => _reminderRepository;
  SettingsRepository get settingsRepository => _settingsRepository;
  ConversationRepository get conversationRepository => _conversationRepository;
  MemoryRepository get memoryRepository => _memoryRepository;
  RoutineRepository get routineRepository => _routineRepository;
  ReportRepository get reportRepository => _reportRepository;

  TtsService get ttsService => _ttsService;
  SttService get sttService => _sttService;
  FaceRecognitionService get faceRecognitionService => _faceRecognitionService;
  AzureOpenAiService get azureOpenAiService => _azureOpenAiService;
  AssistantService get assistantService => _assistantService;
  NotificationService get notificationService => _notificationService;

  AppSettings get settings => _settingsRepository.settings;
  bool get isOnboardingComplete => settings.onboardingComplete;
  bool get isLlmModeEnabled => settings.llmModeEnabled;

  /// Initialize all services and repositories
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PersonAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(RepeatTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ReminderStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ReminderAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(MessageRoleAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(ConversationLogAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }
      // New adapters for Memory and Routine
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(MemoryAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(RoutineFrequencyAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(RoutineAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(CaregiverReportAdapter());
      }

      // Initialize repositories
      _personRepository = PersonRepository();
      _reminderRepository = ReminderRepository();
      _settingsRepository = SettingsRepository();
      _conversationRepository = ConversationRepository();
      _memoryRepository = MemoryRepository();
      _routineRepository = RoutineRepository();

      await Future.wait([
        _personRepository.init(),
        _reminderRepository.init(),
        _settingsRepository.init(),
        _conversationRepository.init(),
        _memoryRepository.init(),
        _routineRepository.init(),
      ]);

      // Initialize report repository (depends on memory and routine repos)
      _reportRepository = ReportRepository(
        memoryRepository: _memoryRepository,
        routineRepository: _routineRepository,
      );
      await _reportRepository.init();

      // Initialize services
      _ttsService = TtsService();
      _sttService = SttService();
      _faceRecognitionService = FaceRecognitionService();
      _azureOpenAiService = AzureOpenAiService();
      _notificationService = NotificationService();

      // Initialize services in parallel where safe
      await Future.wait([
        _ttsService.init(),
        _sttService.init(),
        _faceRecognitionService.init(),
        _notificationService.init(),
      ]);

      // Configure Azure - first try .env, then stored settings
      String? apiKey;
      String? endpoint;
      String deploymentName = 'gpt-4';

      // Check .env file first (for development)
      if (EnvConfig.isAzureConfigured) {
        apiKey = EnvConfig.azureApiKey;
        endpoint = EnvConfig.azureEndpoint;
        deploymentName = EnvConfig.azureDeploymentName;
        // Also enable LLM mode automatically if .env is configured
        await _settingsRepository.setLlmModeEnabled(true);
        EnvConfig.printConfig(); // Debug output
      } else {
        // Fall back to stored settings
        apiKey = await _settingsRepository.getAzureApiKey();
        endpoint = await _settingsRepository.getAzureEndpoint();
      }

      if (apiKey != null &&
          apiKey.isNotEmpty &&
          endpoint != null &&
          endpoint.isNotEmpty) {
        await _azureOpenAiService.configure(
          apiKey: apiKey,
          endpoint: endpoint,
          deploymentName: deploymentName,
        );
      }

      // Initialize assistant service
      _assistantService = AssistantService(
        ttsService: _ttsService,
        azureService: _azureOpenAiService,
        personRepository: _personRepository,
        reminderRepository: _reminderRepository,
        settingsRepository: _settingsRepository,
        conversationRepository: _conversationRepository,
      );

      // Apply TTS settings
      await _ttsService.setSpeechRate(settings.speechRate);
      await _ttsService.setPitch(settings.speechPitch);

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize app: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Only notify once at the end
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _settingsRepository.setOnboardingComplete(true);
    notifyListeners();
  }

  /// Set caregiver PIN
  Future<void> setCaregiverPin(String pin) async {
    await _settingsRepository.setCaregiverPin(pin);
    notifyListeners();
  }

  /// Verify caregiver PIN
  Future<bool> verifyCaregiverPin(String pin) async {
    return await _settingsRepository.verifyCaregiverPin(pin);
  }

  /// Check if PIN is set
  Future<bool> hasSetPin() async {
    return await _settingsRepository.hasSetPin();
  }

  /// Update speech rate
  Future<void> updateSpeechRate(double rate) async {
    await _settingsRepository.setSpeechRate(rate);
    await _ttsService.setSpeechRate(rate);
    notifyListeners();
  }

  /// Toggle LLM mode
  Future<void> toggleLlmMode(bool enabled) async {
    await _settingsRepository.setLlmModeEnabled(enabled);
    notifyListeners();
  }

  /// Configure Azure OpenAI
  Future<void> configureAzure(String apiKey, String endpoint) async {
    await _settingsRepository.setAzureApiKey(apiKey);
    await _settingsRepository.setAzureEndpoint(endpoint);
    await _azureOpenAiService.configure(apiKey: apiKey, endpoint: endpoint);
    notifyListeners();
  }

  /// Dispose all services
  @override
  void dispose() {
    _ttsService.dispose();
    _sttService.dispose();
    _faceRecognitionService.dispose();
    _personRepository.close();
    _reminderRepository.close();
    _settingsRepository.close();
    _conversationRepository.close();
    super.dispose();
  }
}
