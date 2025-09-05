import 'package:langchat/domain/entities/chat_message.dart';

abstract class AIServiceRepository {
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String language,
    required String userMessage,
  });

  Future<ChatMessage?> generateModeratorTip({
    required String conversationId,
    required List<ChatMessage> recentMessages,
    required String targetLanguage,
  });

  Future<bool> checkMessageSafety({
    required String message,
    required String language,
  });

  Future<String> transcribeAudio(String audioPath);
  Future<String> synthesizeSpeech({
    required String text,
    required String language,
    required String voice,
  });
}
