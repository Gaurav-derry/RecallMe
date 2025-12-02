import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String relation;

  @HiveField(3)
  String notes;

  @HiveField(4)
  List<String> imagePaths;

  @HiveField(5)
  List<double>? faceEmbedding;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Person({
    required this.id,
    required this.name,
    required this.relation,
    this.notes = '',
    this.imagePaths = const [],
    this.faceEmbedding,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Person copyWith({
    String? id,
    String? name,
    String? relation,
    String? notes,
    List<String>? imagePaths,
    List<double>? faceEmbedding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get a friendly description for TTS
  String get ttsDescription {
    final buffer = StringBuffer();
    buffer.write('This is $name. ');
    
    if (relation.isNotEmpty) {
      buffer.write('$name is your $relation. ');
    }
    
    if (notes.isNotEmpty) {
      buffer.write(notes);
    }
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $name, relation: $relation)';
  }
}


