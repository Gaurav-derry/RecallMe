/// App Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'RecallMe';
  static const String tagline = 'Helping you remember what matters.';

  // TTS Settings
  static const double defaultSpeechRate = 0.4; // Slower for dementia patients
  static const double defaultPitch = 1.0;
  static const double defaultVolume = 1.0;

  // Face Recognition
  static const double faceMatchThreshold = 0.4; // Cosine similarity threshold (lowered for histogram-based)
  static const int embeddingSize = 256; // Histogram-based embedding size
  static const int faceInputSize = 112; // Model input size

  // Secure Storage Keys
  static const String caregiverPinKey = 'caregiver_pin';
  static const String azureApiKeyKey = 'azure_api_key';
  static const String azureEndpointKey = 'azure_endpoint';
  static const String llmModeEnabledKey = 'llm_mode_enabled';
  static const String speechRateKey = 'speech_rate';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Hive Box Names
  static const String personsBox = 'persons';
  static const String remindersBox = 'reminders';
  static const String settingsBox = 'settings';
  static const String conversationLogsBox = 'conversation_logs';
  static const String memoriesBox = 'memories';
  static const String routinesBox = 'routines';
  static const String reportsBox = 'caregiver_reports';

  // Azure OpenAI
  static const String azureSystemPrompt = '''
You are a gentle, supportive memory assistant for someone with mild dementia.

STRICT RULES:
- Give SHORT responses (2-3 sentences maximum)
- NEVER use asterisks, bold, or markdown formatting
- NEVER use em dashes or special characters
- Use simple, plain text only
- Only describe the memory being discussed
- Be warm and reassuring
- Use short, simple sentences
- One piece of information at a time
- Do not give medical advice
- Be friendly like a trusted friend

RESPONSE FORMAT:
- Plain text only, no formatting
- Keep responses brief and focused
- Describe only what is asked about
''';

  // Intent Keywords for offline assistant
  static const List<String> reminderKeywords = [
    'remind',
    'reminder',
    'schedule',
    'appointment',
    'today',
    'tomorrow',
    'what do i have',
    'what\'s next',
    'next',
    'upcoming',
    'plans',
  ];

  static const List<String> peopleKeywords = [
    'who is',
    'who\'s',
    'tell me about',
    'remember',
    'person',
    'family',
    'friend',
    'relative',
    'daughter',
    'son',
    'wife',
    'husband',
  ];

  static const List<String> greetingKeywords = [
    'hello',
    'hi',
    'hey',
    'good morning',
    'good afternoon',
    'good evening',
    'how are you',
    'good night',
  ];

  static const List<String> timeKeywords = [
    'what time',
    'time is it',
    'what day',
    'what date',
    'today\'s date',
  ];

  static const List<String> helpKeywords = [
    'help',
    'confused',
    'lost',
    'don\'t know',
    'scared',
    'worried',
  ];
}

/// App Routes
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String reminders = '/reminders';
  static const String addReminder = '/add-reminder';
  static const String editReminder = '/edit-reminder';
  static const String people = '/people';
  static const String addPerson = '/add-person';
  static const String editPerson = '/edit-person';
  static const String personDetails = '/person-details';
  static const String whoIsThis = '/who-is-this';
  static const String settings = '/settings';
  static const String caregiverChat = '/caregiver-chat';
  static const String pinEntry = '/pin-entry';

  // New routes
  static const String memories = '/memories';
  static const String addMemory = '/add-memory';
  static const String editMemory = '/edit-memory';
  static const String recall = '/recall';
  static const String routines = '/routines';
  static const String addRoutine = '/add-routine';
  static const String editRoutine = '/edit-routine';
  static const String dailyTasks = '/daily-tasks';
  static const String schedule = '/schedule';
  static const String caregiverReports = '/caregiver-reports';
  static const String weeklyRecords = '/weekly-records';
}
