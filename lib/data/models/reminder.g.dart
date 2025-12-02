// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 1;

  @override
  RepeatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatType.none;
      case 1:
        return RepeatType.daily;
      case 2:
        return RepeatType.weekly;
      case 3:
        return RepeatType.monthly;
      default:
        return RepeatType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatType obj) {
    switch (obj) {
      case RepeatType.none:
        writer.writeByte(0);
        break;
      case RepeatType.daily:
        writer.writeByte(1);
        break;
      case RepeatType.weekly:
        writer.writeByte(2);
        break;
      case RepeatType.monthly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderStatusAdapter extends TypeAdapter<ReminderStatus> {
  @override
  final int typeId = 2;

  @override
  ReminderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderStatus.pending;
      case 1:
        return ReminderStatus.completed;
      case 2:
        return ReminderStatus.missed;
      case 3:
        return ReminderStatus.snoozed;
      default:
        return ReminderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderStatus obj) {
    switch (obj) {
      case ReminderStatus.pending:
        writer.writeByte(0);
        break;
      case ReminderStatus.completed:
        writer.writeByte(1);
        break;
      case ReminderStatus.missed:
        writer.writeByte(2);
        break;
      case ReminderStatus.snoozed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 3;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateTime: fields[3] as DateTime,
      repeatType: fields[4] as RepeatType,
      status: fields[5] as ReminderStatus,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      isImportant: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.repeatType)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.isImportant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


