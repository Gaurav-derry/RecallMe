import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../data/models/memory.dart';
import '../../data/models/person.dart';
import '../../providers/app_provider.dart';
import '../../services/azure_openai_service.dart';
import '../../services/stt_service.dart';
import '../../widgets/doodle_mascot.dart';

// Chat history item for context tracking
class _ChatHistoryItem {
  final bool isUser;
  final String content;

  _ChatHistoryItem({required this.isUser, required this.content});
}

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<_ChatHistoryItem> _chatHistory = []; // For context tracking
  bool _isAnalyzing = false;
  bool _isTyping = false;
  bool _isListening = false;
  Memory? _selectedMemory;
  List<Memory> _memories = [];
  List<Person> _people = [];
  bool _isLoading = true;
  bool _hasStartedChat = false;

  StreamSubscription? _sttStateSubscription;
  StreamSubscription? _sttResultSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupVoiceListeners();
  }

  Future<void> _loadData() async {
    final appProvider = context.read<AppProvider>();
    final memories = await appProvider.memoryRepository.getAllMemories();
    final people = await appProvider.personRepository.getAllPersons();
    if (mounted) {
      setState(() {
        _memories = memories;
        _people = people;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _setupVoiceListeners() {
    final appProvider = context.read<AppProvider>();
    final sttService = appProvider.sttService;

    _sttStateSubscription = sttService.stateChanges.listen((state) {
      if (mounted) {
        setState(() {
          _isListening = state == SttState.listening;
        });
      }
    });

    _sttResultSubscription = sttService.finalResults.listen((text) {
      if (text.isNotEmpty && mounted) {
        _startChatIfNeeded();
        _messageController.text = text;
        _sendMessage();
      }
    });
  }

  @override
  void dispose() {
    _sttStateSubscription?.cancel();
    _sttResultSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startChatIfNeeded() {
    if (!_hasStartedChat) {
      setState(() {
        _hasStartedChat = true;
      });
      _addAssistantMessage("Hi! Ask me about your memories. 💙");
    }
  }

  void _addAssistantMessage(String text) {
    // Clean output - remove asterisks, bold, markdown
    final cleanText = _cleanOutput(text);

    setState(() {
      _messages.add({'text': cleanText, 'isUser': false});
    });
    _scrollToBottom();

    // Add to chat history for context (keep last 5)
    _chatHistory.add(_ChatHistoryItem(isUser: false, content: cleanText));
    if (_chatHistory.length > 10) {
      _chatHistory.removeAt(0);
    }

    // Speak the message using TTS - remove emojis and keep short
    final appProvider = context.read<AppProvider>();
    final speechText =
        cleanText
            .replaceAll(RegExp(r'[💙🎤📸👥⏰🌟🤔✨💕🌸]'), '')
            .replaceAll(RegExp(r'\n+'), ' ')
            .trim();

    // Only speak first 2 sentences to keep it short
    final sentences = speechText.split(RegExp(r'[.!?]'));
    final shortSpeech = sentences.take(2).join('. ').trim();
    if (shortSpeech.isNotEmpty) {
      appProvider.ttsService.speak(
        shortSpeech.endsWith('.') ? shortSpeech : '$shortSpeech.',
      );
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true});
    });
    _scrollToBottom();

    // Add to chat history for context
    _chatHistory.add(_ChatHistoryItem(isUser: true, content: text));
    if (_chatHistory.length > 10) {
      _chatHistory.removeAt(0);
    }
  }

  String _cleanOutput(String text) {
    // Remove markdown formatting
    return text
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // Bold **text**
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // Italic *text*
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1') // Bold __text__
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1') // Italic _text_
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'$1') // Strikethrough
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Inline code
        .replaceAll('—', '-') // Em dash
        .replaceAll('–', '-') // En dash
        .replaceAll('•', '-') // Bullet
        .replaceAll(RegExp(r'#+\s'), '') // Headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1') // Links
        .trim();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoiceInput() async {
    final appProvider = context.read<AppProvider>();
    final sttService = appProvider.sttService;

    if (_isListening) {
      await sttService.stopListening();
      setState(() => _isListening = false);
    } else {
      // Stop TTS first
      await appProvider.ttsService.stop();

      // Start listening
      setState(() => _isListening = true);
      await sttService.startListening();

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 12),
                Text('Listening... Speak now'),
              ],
            ),
            backgroundColor: AppColors.primaryOrange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _startChatIfNeeded();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isAnalyzing = true;
      });

      _addUserMessage("I'd like to understand this photo.");

      await _analyzeWithLLM(
        "Please describe what you see in this photo and help me understand this memory.",
      );
    }
  }

  Future<void> _analyzeWithLLM(String prompt) async {
    setState(() => _isTyping = true);

    try {
      final appProvider = context.read<AppProvider>();
      final azureService = appProvider.azureOpenAiService;

      if (azureService.isConfigured) {
        final response = await azureService.chat(prompt);

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _isTyping = false;
          });
          _addAssistantMessage(response);
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _isTyping = false;
          });
          _addAssistantMessage(
            "I see this is a beautiful moment! 📸\n\n"
            "This appears to be a meaningful memory. Would you like me to:\n\n"
            "• Help you recall when this was taken?\n"
            "• Identify the people in this photo?\n"
            "• Add notes about how it makes you feel?",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isTyping = false;
        });
        _addAssistantMessage(
          "I had trouble analyzing this photo. Could you tell me more about it?",
        );
      }
    }
  }

  void _selectMemory(Memory memory) {
    _startChatIfNeeded();
    setState(() {
      _selectedMemory = memory;
      if (memory.imagePath != null) {
        _selectedImage = File(memory.imagePath!);
      }
    });

    _addUserMessage("Tell me about ${memory.name}.");
    _respondToMemory(memory);
  }

  Future<void> _respondToMemory(Memory memory) async {
    setState(() => _isTyping = true);

    // Record the recall
    final appProvider = context.read<AppProvider>();
    await appProvider.memoryRepository.recordRecall(memory.id);

    final azureService = appProvider.azureOpenAiService;

    if (azureService.isConfigured) {
      try {
        final prompt =
            'Describe this memory in 2-3 simple sentences:\n'
            'Name: ${memory.name}\n'
            'Year: ${memory.year}\n'
            'Person: ${memory.personName}\n'
            'Memory word: ${memory.memoryWord}\n'
            'Category: ${memory.category}\n\n'
            'Keep the response warm and short. No formatting or asterisks.';

        final response = await azureService.chat(prompt);

        if (mounted) {
          setState(() => _isTyping = false);
          _addAssistantMessage(response);
        }
      } catch (e) {
        _fallbackMemoryResponse(memory);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      _fallbackMemoryResponse(memory);
    }
  }

  void _fallbackMemoryResponse(Memory memory) {
    setState(() => _isTyping = false);
    _addAssistantMessage(
      "📸 ${memory.name}\n\n"
      "This memory is from ${memory.year} and features ${memory.personName}.\n\n"
      "Memory word: \"${memory.memoryWord}\"\n\n"
      "Would you like to:\n"
      "• Tell me how this makes you feel?\n"
      "• Add more details about this moment?\n"
      "• See similar memories?",
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    _startChatIfNeeded();
    final text = _messageController.text.trim();
    _addUserMessage(text);
    _messageController.clear();

    setState(() => _isTyping = true);

    final appProvider = context.read<AppProvider>();
    final azureService = appProvider.azureOpenAiService;

    if (azureService.isConfigured) {
      try {
        // Build context with memory info and last 5 chats
        String contextPrompt = text;

        // Add memory context if available
        if (_selectedMemory != null) {
          contextPrompt =
              'Context: The user is looking at a memory called "${_selectedMemory!.name}" from ${_selectedMemory!.year}. '
              'It features ${_selectedMemory!.personName}. Memory word: "${_selectedMemory!.memoryWord}". '
              'Category: ${_selectedMemory!.category}.\n\n'
              'User question: $text\n\n'
              'Give a SHORT response (2-3 sentences max) about this specific memory. No formatting.';
        }

        // Build chat history for context
        final history =
            _chatHistory
                .take(10)
                .map(
                  (h) => ChatMessage(
                    role: h.isUser ? ChatRole.user : ChatRole.assistant,
                    content: h.content,
                  ),
                )
                .toList();

        final response = await azureService.chat(
          contextPrompt,
          history: history,
        );

        if (mounted) {
          setState(() => _isTyping = false);
          _addAssistantMessage(response);
        }
      } catch (e) {
        _fallbackResponse(text);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      _fallbackResponse(text);
    }
  }

  void _fallbackResponse(String text) {
    setState(() => _isTyping = false);

    final lowerText = text.toLowerCase();

    if (lowerText.contains('who')) {
      _addAssistantMessage(
        "I'd love to help identify people in your memories! 👥\n\n"
        "Try using the 'Who Is This?' feature from the home screen to identify faces.",
      );
    } else if (lowerText.contains('when') || lowerText.contains('time')) {
      _addAssistantMessage(
        "⏰ Based on your memories, this appears to be from earlier today.\n\n"
        "Your daily routine helps keep you connected to each moment.",
      );
    } else if (lowerText.contains('why') || lowerText.contains('important')) {
      _addAssistantMessage(
        "💙 Every memory is precious!\n\n"
        "This moment is important because it's part of your story. "
        "Would you like to add some notes about why this memory matters to you?",
      );
    } else if (lowerText.contains('feel') || lowerText.contains('emotion')) {
      _addAssistantMessage(
        "It's wonderful that you're connecting with your feelings! 🌟\n\n"
        "Memories often bring up emotions. Take your time to reflect on how this moment makes you feel.",
      );
    } else {
      _addAssistantMessage(
        "I understand you want to know more. 🤔\n\n"
        "This memory represents a special moment from your day. "
        "Is there something specific you'd like me to help you remember?",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              if (_hasStartedChat) ...[
                _buildHeader(),
                if (_selectedImage != null || _selectedMemory != null)
                  _buildSelectedMemory(),
                Expanded(child: _buildChatArea()),
                _buildInputArea(),
              ] else ...[
                Expanded(child: _buildWelcomeView()),
                _buildInputArea(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Doodle Mascot
          const DoodleMascot(size: 120, animate: true, showSparkles: true),
          const SizedBox(height: 20),
          Text(
            'RecallMe',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              shadows: [
                Shadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Hi! Ask me about your memories.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),

          // Memory selector
          if (_memories.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  '📸 Your Memories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_memories.length} saved',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addPerson,
                    ).then((_) => _refreshData());
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text(
                    'Add Person',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _memories.length,
                        itemBuilder: (context, index) {
                          final memory = _memories[index];
                          final gradients = [
                            AppColors.primaryGradient,
                            AppColors.tealGradient,
                            AppColors.purpleGradient,
                            AppColors.warmGradient,
                          ];

                          return GestureDetector(
                                onTap: () => _selectMemory(memory),
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient:
                                                gradients[index %
                                                    gradients.length],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                            image:
                                                memory.imagePath != null
                                                    ? DecorationImage(
                                                      image: FileImage(
                                                        File(memory.imagePath!),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                    : null,
                                          ),
                                          child:
                                              memory.imagePath == null
                                                  ? const Center(
                                                    child: Icon(
                                                      Icons.photo_rounded,
                                                      color: Colors.white54,
                                                      size: 28,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                memory.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                memory.personName,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate(delay: (400 + index * 80).ms)
                              .fadeIn()
                              .slideX(begin: 0.2);
                        },
                      ),
            ),
          ] else if (!_isLoading) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No memories yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add memories to recall them here',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],

          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _WelcomeActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  gradient: AppColors.primaryGradient,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WelcomeActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  gradient: AppColors.purpleGradient,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  void _selectPerson(Person person) {
    // Show person detail sheet with all images
    _showPersonDetailSheet(person);
  }

  void _showPersonDetailSheet(Person person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with name and relation
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.purpleGradient,
                                image:
                                    person.imagePaths.isNotEmpty
                                        ? DecorationImage(
                                          image: FileImage(
                                            File(person.imagePaths.first),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                              ),
                              child:
                                  person.imagePaths.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 35,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.purpleGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      person.relation,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Photo Gallery Section
                        if (person.imagePaths.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library_rounded,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Photos (${person.imagePaths.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: person.imagePaths.length,
                              itemBuilder: (context, index) {
                                final imagePath = person.imagePaths[index];
                                return GestureDetector(
                                  onTap:
                                      () => _showFullScreenImage(
                                        imagePath,
                                        person.name,
                                        index + 1,
                                        person.imagePaths.length,
                                      ),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: AppColors.softShadow,
                                      image: DecorationImage(
                                        image: FileImage(File(imagePath)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${index + 1}/${person.imagePaths.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // Notes section
                        if (person.notes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Icon(
                                Icons.notes_rounded,
                                size: 20,
                                color: AppColors.primaryOrange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundTop,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              person.notes,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final appProvider =
                                      context.read<AppProvider>();
                                  appProvider.ttsService.speak(
                                    'This is ${person.name}, your ${person.relation}. ${person.notes}',
                                  );
                                },
                                icon: const Icon(Icons.volume_up_rounded),
                                label: const Text('Tell Me'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: AppColors.primaryOrange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _startChatWithPerson(person);
                                },
                                icon: const Icon(Icons.chat_rounded),
                                label: const Text('Ask About'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFullScreenImage(
    String imagePath,
    String personName,
    int currentIndex,
    int totalImages,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _FullScreenImageView(
              imagePath: imagePath,
              title: personName,
              subtitle: 'Photo $currentIndex of $totalImages',
            ),
      ),
    );
  }

  void _startChatWithPerson(Person person) {
    _startChatIfNeeded();

    // Set person image if available
    if (person.imagePaths.isNotEmpty) {
      setState(() {
        _selectedImage = File(person.imagePaths.first);
      });
    }

    _addUserMessage("Tell me about ${person.name}.");
    _respondToPerson(person);
  }

  Future<void> _respondToPerson(Person person) async {
    setState(() => _isTyping = true);

    final appProvider = context.read<AppProvider>();
    final azureService = appProvider.azureOpenAiService;

    if (azureService.isConfigured) {
      try {
        final prompt =
            'Describe this person in 2-3 simple sentences:\n'
            'Name: ${person.name}\n'
            'Relation: ${person.relation}\n'
            'Notes: ${person.notes}\n\n'
            'Keep the response warm and short. No formatting or asterisks.';

        final response = await azureService.chat(prompt);

        if (mounted) {
          setState(() => _isTyping = false);
          _addAssistantMessage(response);
        }
      } catch (e) {
        _fallbackPersonResponse(person);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      _fallbackPersonResponse(person);
    }
  }

  void _fallbackPersonResponse(Person person) {
    setState(() => _isTyping = false);
    _addAssistantMessage(
      "This is ${person.name}, your ${person.relation}.\n\n"
      "${person.notes.isNotEmpty ? person.notes : 'They are someone special to you.'}\n\n"
      "Would you like to know more about them?",
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recall Assistant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Ask me about your memories',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasStartedChat = false;
                _selectedImage = null;
                _selectedMemory = null;
                _messages.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSelectedMemory() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        image:
            _selectedImage != null
                ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
                : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        children: [
          if (_selectedImage == null && _selectedMemory != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_rounded,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedMemory!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = null;
                  _selectedMemory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          if (_isAnalyzing)
            Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Analyzing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return _TypingIndicator();
        }

        final msg = _messages[index];
        return _ChatBubble(
          text: msg['text'],
          isUser: msg['isUser'],
        ).animate().fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showQuickQuestions,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.backgroundTop,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask about your memories...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
                onTap: _toggleVoiceInput,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _isListening ? null : AppColors.primaryGradient,
                    color: _isListening ? AppColors.error : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                                ? AppColors.error
                                : AppColors.primaryBlue)
                            .withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              )
              .animate(target: _isListening ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickQuestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Quick Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickQuestionButton(
                  text: 'What happened in this memory?',
                  onTap: () {
                    Navigator.pop(context);
                    _startChatIfNeeded();
                    _messageController.text = 'What happened in this memory?';
                    _sendMessage();
                  },
                ),
                _QuickQuestionButton(
                  text: 'Who is in this photo?',
                  onTap: () {
                    Navigator.pop(context);
                    _startChatIfNeeded();
                    _messageController.text = 'Who is in this photo?';
                    _sendMessage();
                  },
                ),
                _QuickQuestionButton(
                  text: 'Why is this memory important?',
                  onTap: () {
                    Navigator.pop(context);
                    _startChatIfNeeded();
                    _messageController.text = 'Why is this memory important?';
                    _sendMessage();
                  },
                ),
                _QuickQuestionButton(
                  text: 'How does this make me feel?',
                  onTap: () {
                    Navigator.pop(context);
                    _startChatIfNeeded();
                    _messageController.text = 'How does this make me feel?';
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Capture a new memory'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _WelcomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _WelcomeActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: (index * 200).ms)
                .then()
                .fadeOut(delay: 400.ms);
          }),
        ),
      ),
    );
  }
}

class _QuickQuestionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickQuestionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundTop,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Full screen image viewer
class _FullScreenImageView extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _FullScreenImageView({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
