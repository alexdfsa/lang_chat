import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/ai_service_repository.dart';

class MockAIServiceRepository implements AIServiceRepository {
  @override
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock response based on last message
    final responses = [
      "¡Hola! ¿Cómo estás hoy?",
      "Eso suena muy interesante. ¿Puedes contarme más?",
      "Me gusta tu pronunciación. Estás mejorando mucho.",
      "¿Te gustaría practicar algunos verbos en español?",
      "Excelente. Sigamos con la conversación.",
    ];

    final randomResponse =
        responses[DateTime.now().millisecondsSinceEpoch % responses.length];

    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: contactId,
      content: randomResponse,
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
    );
  }

  @override
  Future<ChatMessage?> generateModeratorTip({
    required String conversationId,
    required List<ChatMessage> recentMessages,
    required String targetLanguage,
  }) async {
    // Only generate tips occasionally (20% chance)
    if (DateTime.now().millisecondsSinceEpoch % 5 != 0) {
      return null;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final tips = [
      "💡 Dica: Tente usar mais verbos no passado para praticar os tempos verbais.",
      "💡 Dica: Que tal perguntar sobre a cultura local? É uma ótima forma de praticar!",
      "💡 Dica: Preste atenção na entonação das perguntas em espanhol.",
      "💡 Dica: Use conectores como 'además', 'sin embargo', 'por eso' para tornar sua fala mais fluida.",
    ];

    final randomTip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];

    return ChatMessage(
      id: 'mod_tip_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: 'moderator',
      senderName: 'Moderador IA',
      content: randomTip,
      type: MessageType.moderatorTip,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
      isModerator: true,
    );
  }

  @override
  Future<bool> checkMessageSafety({
    required String message,
    required String language,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Simple mock safety check - block messages with certain keywords
    final unsafeWords = ['hate', 'violence', 'inappropriate'];
    final messageLower = message.toLowerCase();

    return !unsafeWords.any((word) => messageLower.contains(word));
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    await Future.delayed(const Duration(seconds: 2));

    // Mock transcription
    return "Esta é uma transcrição simulada do áudio gravado.";
  }

  @override
  Future<String> synthesizeSpeech({
    required String text,
    required String language,
    required String voice,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Return mock audio file path
    return "/mock/audio/path/speech_${DateTime.now().millisecondsSinceEpoch}.wav";
  }
}
