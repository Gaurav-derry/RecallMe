import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Azure OpenAI Service for enhanced conversations
class AzureOpenAiService {
  String? _apiKey;
  String? _endpoint;
  String? _deploymentName;
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;

  Future<void> configure({
    required String apiKey,
    required String endpoint,
    String deploymentName = 'gpt-4',
  }) async {
    _apiKey = apiKey;
    _endpoint = endpoint;
    _deploymentName = deploymentName;
    _isConfigured = apiKey.isNotEmpty && endpoint.isNotEmpty;
  }

  void reset() {
    _apiKey = null;
    _endpoint = null;
    _deploymentName = null;
    _isConfigured = false;
  }

  /// Send a message and get a response
  Future<String> chat(String userMessage, {List<ChatMessage>? history}) async {
    if (!_isConfigured) {
      return 'Cloud assistant is not configured. Please ask your caregiver to set it up.';
    }

    try {
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': AppConstants.azureSystemPrompt},
      ];

      // Add conversation history (last 5 messages for context)
      if (history != null && history.isNotEmpty) {
        final recentHistory = history.length > 10 
            ? history.sublist(history.length - 10) 
            : history;
        
        for (final msg in recentHistory) {
          messages.add({
            'role': msg.role == ChatRole.user ? 'user' : 'assistant',
            'content': msg.content,
          });
        }
      }

      // Add current message
      messages.add({'role': 'user', 'content': userMessage});

      final response = await http.post(
        Uri.parse('$_endpoint/openai/deployments/$_deploymentName/chat/completions?api-version=2024-02-15-preview'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey!,
        },
        body: jsonEncode({
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
          'presence_penalty': 0.6,
          'frequency_penalty': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content ?? 'I understand. How can I help you?';
      } else {
        print('Azure OpenAI error: ${response.statusCode} - ${response.body}');
        return 'I\'m having trouble connecting right now. Let me try to help you another way.';
      }
    } catch (e) {
      print('Azure OpenAI exception: $e');
      return 'I\'m having trouble connecting right now. Let me try to help you another way.';
    }
  }

  /// Generate a simple explanation for a complex topic
  Future<String> simplifyText(String complexText) async {
    if (!_isConfigured) return complexText;

    final prompt = '''
Please simplify the following text for someone with mild dementia. 
Use very short sentences. Be clear and calm.

Text: $complexText

Simplified version:''';

    return await chat(prompt);
  }

  /// Generate a daily summary for caregivers
  Future<String> generateCaregiverSummary(String activityLog) async {
    if (!_isConfigured) return activityLog;

    final prompt = '''
You are helping a caregiver understand their loved one's day.
Based on the following activity log, provide a brief, helpful summary.
Highlight any concerns or positive moments.

Activity Log:
$activityLog

Summary:''';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint/openai/deployments/$_deploymentName/chat/completions?api-version=2024-02-15-preview'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': _apiKey!,
        },
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant for caregivers of dementia patients.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content'] ?? activityLog;
      }
    } catch (e) {
      print('Summary generation error: $e');
    }

    return activityLog;
  }
}

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum ChatRole {
  user,
  assistant,
}


