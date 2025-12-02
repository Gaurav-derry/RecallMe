import 'package:hive/hive.dart';

part 'conversation_log.g.dart';

@HiveType(typeId: 4)
enum MessageRole {
  @HiveField(0)
  user,
  
  @HiveField(1)
  assistant,
  
  @HiveField(2)
  system,
}

@HiveType(typeId: 5)
class ConversationLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  MessageRole role;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  bool isCloudResponse;

  ConversationLog({
    required this.id,
    required this.message,
    required this.role,
    DateTime? timestamp,
    this.isCloudResponse = false,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ConversationLog(role: $role, message: $message)';
  }
}


