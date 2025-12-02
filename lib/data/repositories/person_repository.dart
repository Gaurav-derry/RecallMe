import 'package:hive/hive.dart';
import '../models/person.dart';
import '../../core/constants.dart';

class PersonRepository {
  late Box<Person> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Person>(AppConstants.personsBox);
  }

  Box<Person> get box => _box;

  Future<List<Person>> getAllPersons() async {
    return _box.values.toList();
  }

  Future<Person?> getPersonById(String id) async {
    try {
      return _box.values.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Person?> getPersonByName(String name) async {
    try {
      return _box.values.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> addPerson(Person person) async {
    await _box.put(person.id, person);
  }

  Future<void> updatePerson(Person person) async {
    await _box.put(person.id, person);
  }

  Future<void> deletePerson(String id) async {
    await _box.delete(id);
  }

  /// Find a person by matching face embedding
  Future<Person?> findPersonByEmbedding(
    List<double> embedding, {
    double threshold = 0.45, // Threshold for improved histogram+LBP-based embedding
  }) async {
    Person? bestMatch;
    double bestSimilarity = 0;

    for (final person in _box.values) {
      if (person.faceEmbedding != null && person.faceEmbedding!.isNotEmpty) {
        final similarity = _cosineSimilarity(embedding, person.faceEmbedding!);
        print('Comparing with ${person.name}: similarity = $similarity');
        if (similarity > threshold && similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestMatch = person;
        }
      }
    }

    if (bestMatch != null) {
      print('Best match: ${bestMatch.name} with similarity $bestSimilarity');
    }

    return bestMatch;
  }

  /// Find all persons with their similarity scores
  Future<List<MapEntry<Person, double>>> findAllMatchingPersons(
    List<double> embedding, {
    double threshold = 0.3,
  }) async {
    final matches = <MapEntry<Person, double>>[];

    for (final person in _box.values) {
      if (person.faceEmbedding != null && person.faceEmbedding!.isNotEmpty) {
        final similarity = _cosineSimilarity(embedding, person.faceEmbedding!);
        if (similarity > threshold) {
          matches.add(MapEntry(person, similarity));
        }
      }
    }

    // Sort by similarity descending
    matches.sort((a, b) => b.value.compareTo(a.value));
    return matches;
  }

  /// Calculate cosine similarity between two embedding vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  double sqrt(double value) {
    return value <= 0 ? 0 : _sqrt(value);
  }

  double _sqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  Future<void> close() async {
    await _box.close();
  }
}


