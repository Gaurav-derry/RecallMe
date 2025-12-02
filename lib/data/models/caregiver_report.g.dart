// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caregiver_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CaregiverReportAdapter extends TypeAdapter<CaregiverReport> {
  @override
  final int typeId = 13;

  @override
  CaregiverReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaregiverReport(
      id: fields[0] as String,
      weekStartDate: fields[1] as DateTime,
      weekEndDate: fields[2] as DateTime,
      totalMemoriesRecalled: fields[3] as int,
      totalRoutinesCompleted: fields[4] as int,
      totalRoutinesMissed: fields[5] as int,
      memoriesRecalledIds: (fields[6] as List).cast<String>(),
      routinesCompletedIds: (fields[7] as List).cast<String>(),
      overallCompletionRate: fields[8] as double,
      notes: fields[9] as String?,
      generatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CaregiverReport obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekStartDate)
      ..writeByte(2)
      ..write(obj.weekEndDate)
      ..writeByte(3)
      ..write(obj.totalMemoriesRecalled)
      ..writeByte(4)
      ..write(obj.totalRoutinesCompleted)
      ..writeByte(5)
      ..write(obj.totalRoutinesMissed)
      ..writeByte(6)
      ..write(obj.memoriesRecalledIds)
      ..writeByte(7)
      ..write(obj.routinesCompletedIds)
      ..writeByte(8)
      ..write(obj.overallCompletionRate)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaregiverReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

