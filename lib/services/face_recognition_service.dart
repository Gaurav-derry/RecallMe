import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../core/constants.dart';

/// Face Recognition Service using TFLite
class FaceRecognitionService {
  static const MethodChannel _channel = MethodChannel('com.recallme/face');
  
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;
    } catch (e) {
      print('Face Recognition initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Detect faces in an image and return bounding boxes
  Future<List<FaceDetection>> detectFaces(Uint8List imageBytes) async {
    if (!_isInitialized) return [];
    
    try {
      final result = await _channel.invokeMethod('detectFaces', {
        'imageBytes': imageBytes,
      });
      
      if (result is List) {
        return result.map((face) => FaceDetection.fromMap(face as Map)).toList();
      }
    } catch (e) {
      print('Face detection error: $e');
    }
    
    return [];
  }

  /// Generate face embedding from a cropped face image
  Future<List<double>?> generateEmbedding(Uint8List faceImageBytes) async {
    if (!_isInitialized) return null;
    
    try {
      final result = await _channel.invokeMethod('generateEmbedding', {
        'faceImageBytes': faceImageBytes,
      });
      
      if (result is List) {
        return result.cast<double>();
      }
    } catch (e) {
      print('Embedding generation error: $e');
    }
    
    return null;
  }

  /// Process an image file and get face embedding
  Future<List<double>?> processImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      final faces = await detectFaces(bytes);
      
      if (faces.isEmpty) return null;
      
      // Get the largest face
      final largestFace = faces.reduce((a, b) => 
        (a.width * a.height) > (b.width * b.height) ? a : b);
      
      // Crop and preprocess the face
      final croppedFace = await _cropFace(bytes, largestFace);
      if (croppedFace == null) return null;
      
      return await generateEmbedding(croppedFace);
    } catch (e) {
      print('Process image error: $e');
      return null;
    }
  }

  /// Crop face from image based on detection
  Future<Uint8List?> _cropFace(Uint8List imageBytes, FaceDetection face) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      // Add padding around the face
      final padding = 20;
      final x = (face.x - padding).clamp(0, image.width - 1).toInt();
      final y = (face.y - padding).clamp(0, image.height - 1).toInt();
      final width = (face.width + padding * 2).clamp(1, image.width - x).toInt();
      final height = (face.height + padding * 2).clamp(1, image.height - y).toInt();
      
      // Crop the face
      final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
      
      // Resize to model input size
      final resized = img.copyResize(
        cropped,
        width: AppConstants.faceInputSize,
        height: AppConstants.faceInputSize,
      );
      
      return Uint8List.fromList(img.encodeJpg(resized));
    } catch (e) {
      print('Crop face error: $e');
      return null;
    }
  }

  /// Calculate cosine similarity between two embeddings
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0;
    
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    if (norm1 == 0 || norm2 == 0) return 0;
    
    return dotProduct / (_sqrt(norm1) * _sqrt(norm2));
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('shutdown');
    } catch (e) {
      print('Face Recognition shutdown error: $e');
    }
  }
}

class FaceDetection {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  FaceDetection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 0.0,
  });

  factory FaceDetection.fromMap(Map map) {
    return FaceDetection(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

