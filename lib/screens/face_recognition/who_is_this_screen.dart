import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/person.dart';
import '../../providers/app_provider.dart';

class WhoIsThisScreen extends StatefulWidget {
  const WhoIsThisScreen({super.key});

  @override
  State<WhoIsThisScreen> createState() => _WhoIsThisScreenState();
}

class _WhoIsThisScreenState extends State<WhoIsThisScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera found');
        return;
      }

      // Prefer front camera, but allow switching
      _currentCameraIndex = _cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0;
      }

      await _initializeCamera(_currentCameraIndex);
    } catch (e) {
      setState(() => _error = 'Failed to initialize camera: $e');
    }
  }

  Future<void> _initializeCamera(int index) async {
    if (index < 0 || index >= _cameras.length) return;

    try {
      // Dispose previous controller
      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentCameraIndex = index;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;
    
    setState(() => _isInitialized = false);
    
    // Switch to next camera
    final nextIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera(nextIndex);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _identifyPerson() async {
    if (_cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take a picture
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      final appProvider = context.read<AppProvider>();
      final faceService = appProvider.faceRecognitionService;
      final personRepo = appProvider.personRepository;

      // Detect faces
      final faces = await faceService.detectFaces(bytes);

      if (faces.isEmpty) {
        _showResult(null, 'No face detected. Please try again.');
        return;
      }

      // Get embedding for the detected face
      final embedding = await faceService.processImageFile(image.path);

      if (embedding == null) {
        _showResult(null, 'Could not process the face. Please try again.');
        return;
      }

      // Find the best matching person with similarity score
      final matches = await personRepo.findAllMatchingPersons(embedding);

      if (matches.isNotEmpty) {
        final bestMatch = matches.first;
        final person = bestMatch.key;
        final similarity = bestMatch.value;
        
        _showResultWithConfidence(person, similarity);
        // Speak the result
        appProvider.assistantService.speak(person.ttsDescription);
      } else {
        // No matches found - show all people as suggestions
        final allPeople = await personRepo.getAllPersons();
        if (allPeople.isNotEmpty) {
          _showSuggestionsSheet(allPeople);
        } else {
          _showResult(null, "I'm not sure who this is. Would you like to add them?");
          appProvider.assistantService.speak(
            "I'm not sure who this is. Would you like to add them as a new person?",
          );
        }
      }
    } catch (e) {
      _showResult(null, 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuggestionsSheet(List<Person> people) {
    final appProvider = context.read<AppProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Is this one of these people?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showResult(person, null);
                      appProvider.assistantService.speak(person.ttsDescription);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            image: person.imagePaths.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(File(person.imagePaths.first)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: person.imagePaths.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 35)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          person.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          person.relation,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/add-person');
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add New'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResultWithConfidence(Person person, double confidence) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Person found with confidence
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                border: Border.all(color: AppColors.secondaryGreen, width: 4),
                image: person.imagePaths.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(person.imagePaths.first)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: person.imagePaths.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 50)
                  : null,
            ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
            const SizedBox(height: 16),
            
            // Confidence indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(confidence * 100).toStringAsFixed(0)}% match',
                style: const TextStyle(
                  color: AppColors.secondaryGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              person.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                person.relation,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (person.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  person.notes,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Not Right?'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AppProvider>().ttsService.speak(person.ttsDescription);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Tell Me'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResult(Person? person, String? message) {
    if (person != null || message != null) {
      _showResultSheet(person, message);
    }
  }

  void _showResultSheet(Person? person, String? message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (person != null) ...[
              // Person found
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryGreen.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.secondaryGreen,
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  person.relation,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (person.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    person.notes,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Unknown person
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentYellow.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.help_outline,
                  size: 60,
                  color: AppColors.warning,
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                message ?? "I don't recognize this person",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/add-person');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add This Person'),
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

          // Error state
          if (_error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Loading state
          if (!_isInitialized && _error == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Who Is This?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Camera switch button (only show if multiple cameras available)
                    if (_cameras.length > 1)
                      IconButton(
                        onPressed: _isProcessing ? null : _switchCamera,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front
                                ? Icons.camera_rear
                                : Icons.camera_front,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        tooltip: _cameras[_currentCameraIndex].lensDirection == CameraLensDirection.front
                            ? 'Switch to back camera'
                            : 'Switch to front camera',
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Face guide overlay
          if (_isInitialized)
            Center(
              child: Container(
                width: 280,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isProcessing
                        ? AppColors.accentYellow
                        : Colors.white.withOpacity(0.7),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(140),
                ),
              ).animate(
                target: _isProcessing ? 1 : 0,
                onPlay: (controller) {
                  if (_isProcessing) {
                    controller.repeat();
                  }
                },
              ).shimmer(
                duration: 1000.ms,
                color: AppColors.primaryBlue.withOpacity(0.3),
              ),
            ),

          // Instructions
          if (_isInitialized && !_isProcessing)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Position face in the oval',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Capture button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isInitialized && !_isProcessing ? _identifyPerson : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isProcessing
                        ? AppColors.textLight
                        : AppColors.primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.search,
                          size: 36,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

