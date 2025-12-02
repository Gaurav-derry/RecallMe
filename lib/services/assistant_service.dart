import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../data/models/conversation_log.dart';
import '../data/models/person.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/person_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'azure_openai_service.dart';
import 'tts_service.dart';

/// Main Assistant Service - handles both offline and cloud modes
class AssistantService {
  final TtsService _ttsService;
  final AzureOpenAiService _azureService;
  final PersonRepository _personRepository;
  final ReminderRepository _reminderRepository;
  final SettingsRepository _settingsRepository;
  final ConversationRepository _conversationRepository;
  
  final _uuid = const Uuid();

  AssistantService({
    required TtsService ttsService,
    required AzureOpenAiService azureService,
    required PersonRepository personRepository,
    required ReminderRepository reminderRepository,
    required SettingsRepository settingsRepository,
    required ConversationRepository conversationRepository,
  })  : _ttsService = ttsService,
        _azureService = azureService,
        _personRepository = personRepository,
        _reminderRepository = reminderRepository,
        _settingsRepository = settingsRepository,
        _conversationRepository = conversationRepository;

  /// Process user input and generate response
  Future<AssistantResponse> processInput(String input) async {
    // Log user message
    await _logMessage(input, MessageRole.user);
    
    // Determine intent
    final intent = _parseIntent(input);
    
    String response;
    bool usedCloud = false;
    
    // Check if cloud mode is enabled
    final settings = _settingsRepository.settings;
    final useCloud = settings.llmModeEnabled && _azureService.isConfigured;
    
    // Handle based on intent
    switch (intent) {
      case AssistantIntent.greeting:
        response = _handleGreeting();
        break;
      case AssistantIntent.reminder:
        response = await _handleReminderQuery(input);
        break;
      case AssistantIntent.person:
        response = await _handlePersonQuery(input);
        break;
      case AssistantIntent.time:
        response = _handleTimeQuery();
        break;
      case AssistantIntent.help:
        response = _handleHelpRequest();
        break;
      case AssistantIntent.unknown:
        if (useCloud) {
          response = await _handleCloudConversation(input);
          usedCloud = true;
        } else {
          response = _handleUnknownIntent();
        }
    }
    
    // Log assistant response
    await _logMessage(response, MessageRole.assistant, isCloud: usedCloud);
    
    // Speak the response
    await _ttsService.speak(response);
    
    return AssistantResponse(
      text: response,
      intent: intent,
      usedCloud: usedCloud,
    );
  }

  /// Parse user intent from input
  AssistantIntent _parseIntent(String input) {
    final lowerInput = input.toLowerCase();
    
    // Check for greetings
    for (final keyword in AppConstants.greetingKeywords) {
      if (lowerInput.contains(keyword)) {
        return AssistantIntent.greeting;
      }
    }
    
    // Check for reminders
    for (final keyword in AppConstants.reminderKeywords) {
      if (lowerInput.contains(keyword)) {
        return AssistantIntent.reminder;
      }
    }
    
    // Check for people
    for (final keyword in AppConstants.peopleKeywords) {
      if (lowerInput.contains(keyword)) {
        return AssistantIntent.person;
      }
    }
    
    // Check for time
    for (final keyword in AppConstants.timeKeywords) {
      if (lowerInput.contains(keyword)) {
        return AssistantIntent.time;
      }
    }
    
    // Check for help
    for (final keyword in AppConstants.helpKeywords) {
      if (lowerInput.contains(keyword)) {
        return AssistantIntent.help;
      }
    }
    
    return AssistantIntent.unknown;
  }

  String _handleGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    
    return '$greeting! I\'m here to help you. You can ask me about your reminders, who someone is, or just chat.';
  }

  Future<String> _handleReminderQuery(String input) async {
    final lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('next') || lowerInput.contains('what\'s next')) {
      final next = await _reminderRepository.getNextReminder();
      if (next != null) {
        return 'Your next reminder is: ${next.ttsDescription}';
      } else {
        return 'You don\'t have any upcoming reminders. Would you like to add one?';
      }
    }
    
    if (lowerInput.contains('today')) {
      final today = await _reminderRepository.getTodayReminders();
      if (today.isEmpty) {
        return 'You don\'t have any reminders for today. It\'s a free day!';
      } else if (today.length == 1) {
        return 'You have one reminder today: ${today.first.ttsDescription}';
      } else {
        final buffer = StringBuffer('You have ${today.length} reminders today. ');
        for (int i = 0; i < today.length && i < 3; i++) {
          buffer.write('${i + 1}. ${today[i].title}. ');
        }
        if (today.length > 3) {
          buffer.write('And ${today.length - 3} more.');
        }
        return buffer.toString();
      }
    }
    
    if (lowerInput.contains('tomorrow')) {
      final tomorrow = await _reminderRepository.getTomorrowReminders();
      if (tomorrow.isEmpty) {
        return 'You don\'t have any reminders for tomorrow.';
      } else if (tomorrow.length == 1) {
        return 'You have one reminder tomorrow: ${tomorrow.first.ttsDescription}';
      } else {
        return 'You have ${tomorrow.length} reminders tomorrow. The first one is ${tomorrow.first.title}.';
      }
    }
    
    // Default: show today's schedule
    final today = await _reminderRepository.getTodayReminders();
    if (today.isEmpty) {
      return 'You don\'t have any reminders for today.';
    } else {
      return 'Today you have ${today.length} reminder${today.length > 1 ? 's' : ''}. Your first one is ${today.first.title}.';
    }
  }

  Future<String> _handlePersonQuery(String input) async {
    final lowerInput = input.toLowerCase();
    
    // Try to extract a name from the query
    final persons = await _personRepository.getAllPersons();
    
    for (final person in persons) {
      if (lowerInput.contains(person.name.toLowerCase())) {
        return person.ttsDescription;
      }
    }
    
    // Check for relation keywords
    final relations = ['wife', 'husband', 'daughter', 'son', 'mother', 'father', 'sister', 'brother'];
    for (final relation in relations) {
      if (lowerInput.contains(relation)) {
        final match = persons.firstWhere(
          (p) => p.relation.toLowerCase().contains(relation),
          orElse: () => Person(id: '', name: '', relation: ''),
        );
        if (match.id.isNotEmpty) {
          return match.ttsDescription;
        }
      }
    }
    
    return 'I can help you remember people. Would you like to see your saved people, or use the camera to identify someone?';
  }

  String _handleTimeQuery() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    
    return 'It\'s $displayHour:${minute.toString().padLeft(2, '0')} $period on $weekday, $month ${now.day}.';
  }

  String _handleHelpRequest() {
    return 'Don\'t worry, I\'m here to help you. You\'re safe. '
           'You can ask me what time it is, what you have to do today, '
           'or about the people in your life. Would you like to call your caregiver?';
  }

  String _handleUnknownIntent() {
    return 'I\'m here to help you. You can ask me about your reminders, '
           'who someone is, what time it is, or just say hello.';
  }

  Future<String> _handleCloudConversation(String input) async {
    // Get recent conversation history for context
    final recentLogs = await _conversationRepository.getRecentLogs(limit: 10);
    
    final history = recentLogs.map((log) => ChatMessage(
      role: log.role == MessageRole.user ? ChatRole.user : ChatRole.assistant,
      content: log.message,
      timestamp: log.timestamp,
    )).toList();
    
    return await _azureService.chat(input, history: history);
  }

  Future<void> _logMessage(String message, MessageRole role, {bool isCloud = false}) async {
    await _conversationRepository.addLog(ConversationLog(
      id: _uuid.v4(),
      message: message,
      role: role,
      isCloudResponse: isCloud,
    ));
  }

  /// Speak a message directly
  Future<void> speak(String message) async {
    await _ttsService.speak(message);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }
}

class AssistantResponse {
  final String text;
  final AssistantIntent intent;
  final bool usedCloud;

  AssistantResponse({
    required this.text,
    required this.intent,
    this.usedCloud = false,
  });
}

enum AssistantIntent {
  greeting,
  reminder,
  person,
  time,
  help,
  unknown,
}

