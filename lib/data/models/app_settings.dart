import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  double speechRate;

  @HiveField(1)
  double speechPitch;

  @HiveField(2)
  double speechVolume;

  @HiveField(3)
  bool llmModeEnabled;

  @HiveField(4)
  bool onboardingComplete;

  @HiveField(5)
  String? azureEndpoint;

  @HiveField(6)
  DateTime? lastBackup;

  AppSettings({
    this.speechRate = 0.4,
    this.speechPitch = 1.0,
    this.speechVolume = 1.0,
    this.llmModeEnabled = false,
    this.onboardingComplete = false,
    this.azureEndpoint,
    this.lastBackup,
  });

  AppSettings copyWith({
    double? speechRate,
    double? speechPitch,
    double? speechVolume,
    bool? llmModeEnabled,
    bool? onboardingComplete,
    String? azureEndpoint,
    DateTime? lastBackup,
  }) {
    return AppSettings(
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechVolume: speechVolume ?? this.speechVolume,
      llmModeEnabled: llmModeEnabled ?? this.llmModeEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      azureEndpoint: azureEndpoint ?? this.azureEndpoint,
      lastBackup: lastBackup ?? this.lastBackup,
    );
  }
}


