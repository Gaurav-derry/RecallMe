import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../services/azure_openai_service.dart';

class CaregiverChatScreen extends StatefulWidget {
  const CaregiverChatScreen({super.key});

  @override
  State<CaregiverChatScreen> createState() => _CaregiverChatScreenState();
}

class _CaregiverChatScreenState extends State<CaregiverChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      role: ChatRole.assistant,
      content: '''Hello! I'm here to help you as a caregiver.

I can help you with:
• Daily activity summaries
• Understanding your loved one's schedule
• Creating simple explanations
• Tips for communication

How can I help you today?''',
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, content: text));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final appProvider = context.read<AppProvider>();
      String response;

      // Check for special commands
      if (text.toLowerCase().contains('summary') ||
          text.toLowerCase().contains('today')) {
        // Generate daily summary
        final summary = await appProvider.conversationRepository.generateDailySummary();
        
        if (appProvider.azureOpenAiService.isConfigured) {
          response = await appProvider.azureOpenAiService.generateCaregiverSummary(summary);
        } else {
          response = summary;
        }
      } else if (appProvider.azureOpenAiService.isConfigured) {
        // Use Azure OpenAI for general chat
        response = await appProvider.azureOpenAiService.chat(
          text,
          history: _messages.where((m) => m != _messages.last).toList(),
        );
      } else {
        response = _getOfflineResponse(text);
      }

      setState(() {
        _messages.add(ChatMessage(role: ChatRole.assistant, content: response));
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: ChatRole.assistant,
          content: 'Sorry, I encountered an error. Please try again.',
        ));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getOfflineResponse(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('summary') || lower.contains('activity')) {
      return '''I can provide a summary when Azure OpenAI is configured.

In the meantime, you can:
• Check the Reminders screen for scheduled activities
• View the People section for saved contacts
• Review conversation logs in the app data''';
    }

    if (lower.contains('help') || lower.contains('tip')) {
      return '''Here are some helpful tips for dementia care:

**Communication:**
• Use simple, short sentences
• Speak slowly and clearly
• Give one instruction at a time
• Be patient and wait for responses

**Daily Routine:**
• Maintain consistent schedules
• Use visual reminders
• Create a calm environment
• Celebrate small successes

**Using RecallMe:**
• Add photos of family members
• Set regular reminders
• Let them use voice commands
• Review settings periodically''';
    }

    if (lower.contains('remind') || lower.contains('schedule')) {
      return '''To manage reminders:

1. Go to the Reminders screen
2. Tap "Add Reminder"
3. Set a clear, simple title
4. Choose date and time
5. Set repeat if needed

Tips:
• Keep reminder titles simple
• Add brief descriptions for context
• Use the "Important" flag for critical items''';
    }

    return '''I'm in offline mode. For enhanced AI assistance, enable Azure OpenAI in Settings.

I can still help with:
• Daily summaries (type "summary")
• Care tips (type "tips")
• Reminder management (type "reminders")

What would you like to know?''';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Caregiver Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, _) {
              final isConnected = appProvider.azureOpenAiService.isConfigured &&
                  appProvider.settings.llmModeEnabled;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.secondaryGreen.withOpacity(0.1)
                      : AppColors.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: isConnected
                          ? AppColors.secondaryGreen
                          : AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'AI' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isConnected
                            ? AppColors.secondaryGreen
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionChip(
                    label: "Today's Summary",
                    onTap: () {
                      _messageController.text = "Give me today's summary";
                      _sendMessage();
                    },
                  ),
                  _QuickActionChip(
                    label: 'Care Tips',
                    onTap: () {
                      _messageController.text = 'What are some helpful care tips?';
                      _sendMessage();
                    },
                  ),
                  _QuickActionChip(
                    label: 'Help with Message',
                    onTap: () {
                      _messageController.text =
                          'Help me write a simple message for my loved one';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return _buildLoadingBubble();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _isLoading ? Icons.hourglass_empty : Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: isUser ? 0.1 : -0.1,
          duration: 200.ms,
        );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .fadeIn(
                  delay: Duration(milliseconds: index * 150),
                  duration: 300.ms,
                )
                .fadeOut(
                  delay: Duration(milliseconds: 300 + index * 150),
                  duration: 300.ms,
                );
          }),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


