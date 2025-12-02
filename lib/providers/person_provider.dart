import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/person.dart';
import '../data/repositories/person_repository.dart';
import '../services/face_recognition_service.dart';

/// Provider for managing people
class PersonProvider extends ChangeNotifier {
  final PersonRepository _repository;
  final FaceRecognitionService _faceRecognitionService;
  final _uuid = const Uuid();
  
  List<Person> _persons = [];
  bool _isLoading = false;

  PersonProvider({
    required PersonRepository repository,
    required FaceRecognitionService faceRecognitionService,
  })  : _repository = repository,
        _faceRecognitionService = faceRecognitionService;

  List<Person> get persons => _persons;
  bool get isLoading => _isLoading;

  /// Load all persons
  Future<void> loadPersons() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _persons = await _repository.getAllPersons();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new person with images
  Future<Person?> addPerson({
    required String name,
    required String relation,
    String notes = '',
    required List<String> imagePaths,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Copy images to app directory
      final savedPaths = <String>[];
      final appDir = await getApplicationDocumentsDirectory();
      final personId = _uuid.v4();
      final personDir = Directory('${appDir.path}/persons/$personId');
      await personDir.create(recursive: true);
      
      for (int i = 0; i < imagePaths.length; i++) {
        final sourcePath = imagePaths[i];
        final file = File(sourcePath);
        if (await file.exists()) {
          final newPath = '${personDir.path}/photo_$i.jpg';
          await file.copy(newPath);
          savedPaths.add(newPath);
        }
      }
      
      // Generate face embedding from the first good image
      List<double>? embedding;
      for (final path in savedPaths) {
        embedding = await _faceRecognitionService.processImageFile(path);
        if (embedding != null && embedding.isNotEmpty) break;
      }
      
      final person = Person(
        id: personId,
        name: name,
        relation: relation,
        notes: notes,
        imagePaths: savedPaths,
        faceEmbedding: embedding,
      );
      
      await _repository.addPerson(person);
      await loadPersons();
      
      return person;
    } catch (e) {
      print('Error adding person: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing person
  Future<void> updatePerson(Person person) async {
    await _repository.updatePerson(person);
    await loadPersons();
  }

  /// Delete a person
  Future<void> deletePerson(String id) async {
    // Get person to delete their images
    final person = await _repository.getPersonById(id);
    if (person != null) {
      // Delete images
      for (final path in person.imagePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
      
      // Delete person directory
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final personDir = Directory('${appDir.path}/persons/${person.id}');
        if (await personDir.exists()) {
          await personDir.delete(recursive: true);
        }
      } catch (e) {
        print('Error deleting person directory: $e');
      }
    }
    
    await _repository.deletePerson(id);
    await loadPersons();
  }

  /// Find person by face embedding
  Future<Person?> identifyPerson(List<double> embedding) async {
    return await _repository.findPersonByEmbedding(embedding);
  }

  /// Get person by ID
  Future<Person?> getPersonById(String id) async {
    return await _repository.getPersonById(id);
  }

  /// Search persons by name
  List<Person> searchByName(String query) {
    if (query.isEmpty) return _persons;
    
    final lowerQuery = query.toLowerCase();
    return _persons.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) ||
      p.relation.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}


