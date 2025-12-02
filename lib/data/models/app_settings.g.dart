// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      speechRate: fields[0] as double,
      speechPitch: fields[1] as double,
      speechVolume: fields[2] as double,
      llmModeEnabled: fields[3] as bool,
      onboardingComplete: fields[4] as bool,
      azureEndpoint: fields[5] as String?,
      lastBackup: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.speechRate)
      ..writeByte(1)
      ..write(obj.speechPitch)
      ..writeByte(2)
      ..write(obj.speechVolume)
      ..writeByte(3)
      ..write(obj.llmModeEnabled)
      ..writeByte(4)
      ..write(obj.onboardingComplete)
      ..writeByte(5)
      ..write(obj.azureEndpoint)
      ..writeByte(6)
      ..write(obj.lastBackup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


