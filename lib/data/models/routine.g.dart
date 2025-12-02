// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineFrequencyAdapter extends TypeAdapter<RoutineFrequency> {
  @override
  final int typeId = 11;

  @override
  RoutineFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RoutineFrequency.once;
      case 1:
        return RoutineFrequency.daily;
      case 2:
        return RoutineFrequency.twiceDaily;
      case 3:
        return RoutineFrequency.weekly;
      case 4:
        return RoutineFrequency.custom;
      default:
        return RoutineFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RoutineFrequency obj) {
    switch (obj) {
      case RoutineFrequency.once:
        writer.writeByte(0);
        break;
      case RoutineFrequency.daily:
        writer.writeByte(1);
        break;
      case RoutineFrequency.twiceDaily:
        writer.writeByte(2);
        break;
      case RoutineFrequency.weekly:
        writer.writeByte(3);
        break;
      case RoutineFrequency.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 12;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      imagePath: fields[3] as String?,
      frequency: fields[4] as RoutineFrequency,
      timesOfDay: (fields[5] as List).cast<int>(),
      place: fields[6] as String?,
      scheduledDate: fields[7] as DateTime?,
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      completionHistory: (fields[10] as List).cast<DateTime>(),
      notificationId: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.timesOfDay)
      ..writeByte(6)
      ..write(obj.place)
      ..writeByte(7)
      ..write(obj.scheduledDate)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completionHistory)
      ..writeByte(11)
      ..write(obj.notificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

