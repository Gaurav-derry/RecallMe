import 'package:hive/hive.dart';
import '../models/memory.dart';

class MemoryRepository {
  static const String _boxName = 'memories';
  late Box<Memory> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Memory>(_boxName);
  }

  Future<List<Memory>> getAllMemories() async {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Memory?> getMemoryById(String id) async {
    return _box.values.where((m) => m.id == id).firstOrNull;
  }

  Future<void> addMemory(Memory memory) async {
    await _box.put(memory.id, memory);
  }

  Future<void> updateMemory(Memory memory) async {
    await _box.put(memory.id, memory);
  }

  Future<void> deleteMemory(String id) async {
    await _box.delete(id);
  }

  Future<List<Memory>> getMemoriesByCategory(String category) async {
    return _box.values.where((m) => m.category == category).toList();
  }

  Future<List<Memory>> getMemoriesByPerson(String personName) async {
    return _box.values
        .where((m) => m.personName.toLowerCase().contains(personName.toLowerCase()))
        .toList();
  }

  Future<List<Memory>> searchMemories(String query) async {
    final lowerQuery = query.toLowerCase();
    return _box.values.where((m) =>
        m.name.toLowerCase().contains(lowerQuery) ||
        m.personName.toLowerCase().contains(lowerQuery) ||
        m.memoryWord.toLowerCase().contains(lowerQuery) ||
        (m.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Future<void> recordRecall(String memoryId) async {
    final memory = await getMemoryById(memoryId);
    if (memory != null) {
      final updated = memory.copyWith(
        recallCount: memory.recallCount + 1,
        lastRecalledAt: DateTime.now(),
      );
      await updateMemory(updated);
    }
  }

  Future<int> getWeeklyRecallCount() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _box.values.where((m) =>
        m.lastRecalledAt != null &&
        m.lastRecalledAt!.isAfter(weekStart)
    ).length;
  }

  Future<List<Memory>> getRecentlyRecalled({int limit = 5}) async {
    final memories = _box.values
        .where((m) => m.lastRecalledAt != null)
        .toList()
      ..sort((a, b) => b.lastRecalledAt!.compareTo(a.lastRecalledAt!));
    return memories.take(limit).toList();
  }
}


