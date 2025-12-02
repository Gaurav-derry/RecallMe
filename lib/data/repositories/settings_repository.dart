import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../models/app_settings.dart';
import '../../core/constants.dart';

class SettingsRepository {
  late Box<AppSettings> _box;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _settingsKey = 'app_settings';

  Future<void> init() async {
    _box = await Hive.openBox<AppSettings>(AppConstants.settingsBox);
    
    // Initialize settings if not exists
    if (!_box.containsKey(_settingsKey)) {
      await _box.put(_settingsKey, AppSettings());
    }
  }

  AppSettings get settings => _box.get(_settingsKey) ?? AppSettings();

  Future<void> updateSettings(AppSettings settings) async {
    await _box.put(_settingsKey, settings);
  }

  // Speech settings
  Future<void> setSpeechRate(double rate) async {
    final current = settings;
    await updateSettings(current.copyWith(speechRate: rate));
  }

  Future<void> setSpeechPitch(double pitch) async {
    final current = settings;
    await updateSettings(current.copyWith(speechPitch: pitch));
  }

  Future<void> setSpeechVolume(double volume) async {
    final current = settings;
    await updateSettings(current.copyWith(speechVolume: volume));
  }

  // LLM Mode
  Future<void> setLlmModeEnabled(bool enabled) async {
    final current = settings;
    await updateSettings(current.copyWith(llmModeEnabled: enabled));
  }

  // Onboarding
  Future<void> setOnboardingComplete(bool complete) async {
    final current = settings;
    await updateSettings(current.copyWith(onboardingComplete: complete));
  }

  // Secure storage for sensitive data
  Future<void> setCaregiverPin(String pin) async {
    await _secureStorage.write(key: AppConstants.caregiverPinKey, value: pin);
  }

  Future<String?> getCaregiverPin() async {
    return await _secureStorage.read(key: AppConstants.caregiverPinKey);
  }

  Future<bool> verifyCaregiverPin(String pin) async {
    final storedPin = await getCaregiverPin();
    return storedPin == pin;
  }

  Future<bool> hasSetPin() async {
    final pin = await getCaregiverPin();
    return pin != null && pin.isNotEmpty;
  }

  // Azure API Key
  Future<void> setAzureApiKey(String apiKey) async {
    await _secureStorage.write(key: AppConstants.azureApiKeyKey, value: apiKey);
  }

  Future<String?> getAzureApiKey() async {
    return await _secureStorage.read(key: AppConstants.azureApiKeyKey);
  }

  // Azure Endpoint
  Future<void> setAzureEndpoint(String endpoint) async {
    final current = settings;
    await updateSettings(current.copyWith(azureEndpoint: endpoint));
  }

  Future<String?> getAzureEndpoint() async {
    return settings.azureEndpoint;
  }

  Future<void> close() async {
    await _box.close();
  }
}


