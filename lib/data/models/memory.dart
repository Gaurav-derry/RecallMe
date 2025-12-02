import 'package:hive/hive.dart';

part 'memory.g.dart';

@HiveType(typeId: 10)
class Memory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // Memory title/name

  @HiveField(2)
  int year; // Year of the memory

  @HiveField(3)
  String personName; // Person associated with memory

  @HiveField(4)
  String memoryWord; // Key word to trigger recall

  @HiveField(5)
  String? imagePath; // Photo path

  @HiveField(6)
  String? description; // Optional description

  @HiveField(7)
  String category; // Routines, People, Places, Special

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  int recallCount; // How many times user recalled this

  @HiveField(10)
  DateTime? lastRecalledAt;

  Memory({
    required this.id,
    required this.name,
    required this.year,
    required this.personName,
    required this.memoryWord,
    this.imagePath,
    this.description,
    this.category = 'Special',
    DateTime? createdAt,
    this.recallCount = 0,
    this.lastRecalledAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Memory copyWith({
    String? id,
    String? name,
    int? year,
    String? personName,
    String? memoryWord,
    String? imagePath,
    String? description,
    String? category,
    DateTime? createdAt,
    int? recallCount,
    DateTime? lastRecalledAt,
  }) {
    return Memory(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      personName: personName ?? this.personName,
      memoryWord: memoryWord ?? this.memoryWord,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      recallCount: recallCount ?? this.recallCount,
      lastRecalledAt: lastRecalledAt ?? this.lastRecalledAt,
    );
  }
}

