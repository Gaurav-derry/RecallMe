// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoryAdapter extends TypeAdapter<Memory> {
  @override
  final int typeId = 10;

  @override
  Memory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Memory(
      id: fields[0] as String,
      name: fields[1] as String,
      year: fields[2] as int,
      personName: fields[3] as String,
      memoryWord: fields[4] as String,
      imagePath: fields[5] as String?,
      description: fields[6] as String?,
      category: fields[7] as String,
      createdAt: fields[8] as DateTime,
      recallCount: fields[9] as int,
      lastRecalledAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Memory obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.personName)
      ..writeByte(4)
      ..write(obj.memoryWord)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.recallCount)
      ..writeByte(10)
      ..write(obj.lastRecalledAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

