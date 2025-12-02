import 'package:hive/hive.dart';
import '../models/conversation_log.dart';
import '../../core/constants.dart';

class ConversationRepository {
  late Box<ConversationLog> _box;

  Future<void> init() async {
    _box = await Hive.openBox<ConversationLog>(AppConstants.conversationLogsBox);
  }

  Box<ConversationLog> get box => _box;

  Future<List<ConversationLog>> getAllLogs() async {
    final logs = _box.values.toList();
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  Future<List<ConversationLog>> getRecentLogs({int limit = 50}) async {
    final logs = _box.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList().reversed.toList();
  }

  Future<List<ConversationLog>> getTodayLogs() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final logs = _box.values
        .where((log) => log.timestamp.isAfter(today))
        .toList();
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  Future<void> addLog(ConversationLog log) async {
    await _box.put(log.id, log);
  }

  Future<void> clearOldLogs({int keepDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final toDelete = _box.values
        .where((log) => log.timestamp.isBefore(cutoff))
        .map((log) => log.id)
        .toList();

    for (final id in toDelete) {
      await _box.delete(id);
    }
  }

  Future<void> clearAllLogs() async {
    await _box.clear();
  }

  /// Generate a summary of today's conversations for caregiver
  Future<String> generateDailySummary() async {
    final logs = await getTodayLogs();
    
    if (logs.isEmpty) {
      return 'No conversations recorded today.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Today\'s Activity Summary:');
    buffer.writeln('------------------------');
    buffer.writeln('Total interactions: ${logs.length}');
    
    final userMessages = logs.where((l) => l.role == MessageRole.user).length;
    buffer.writeln('User messages: $userMessages');
    
    // Find topics discussed
    final topics = <String>[];
    for (final log in logs) {
      if (log.role == MessageRole.user) {
        final message = log.message.toLowerCase();
        if (message.contains('remind') || message.contains('schedule')) {
          if (!topics.contains('Reminders')) topics.add('Reminders');
        }
        if (message.contains('who') || message.contains('person')) {
          if (!topics.contains('People')) topics.add('People');
        }
        if (message.contains('time') || message.contains('date')) {
          if (!topics.contains('Time/Date')) topics.add('Time/Date');
        }
        if (message.contains('help') || message.contains('confused')) {
          if (!topics.contains('Help requests')) topics.add('Help requests');
        }
      }
    }
    
    if (topics.isNotEmpty) {
      buffer.writeln('Topics discussed: ${topics.join(', ')}');
    }
    
    return buffer.toString();
  }

  Future<void> close() async {
    await _box.close();
  }
}


