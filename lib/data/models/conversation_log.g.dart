// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageRoleAdapter extends TypeAdapter<MessageRole> {
  @override
  final int typeId = 4;

  @override
  MessageRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageRole.user;
      case 1:
        return MessageRole.assistant;
      case 2:
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  @override
  void write(BinaryWriter writer, MessageRole obj) {
    switch (obj) {
      case MessageRole.user:
        writer.writeByte(0);
        break;
      case MessageRole.assistant:
        writer.writeByte(1);
        break;
      case MessageRole.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationLogAdapter extends TypeAdapter<ConversationLog> {
  @override
  final int typeId = 5;

  @override
  ConversationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationLog(
      id: fields[0] as String,
      message: fields[1] as String,
      role: fields[2] as MessageRole,
      timestamp: fields[3] as DateTime?,
      isCloudResponse: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isCloudResponse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}


