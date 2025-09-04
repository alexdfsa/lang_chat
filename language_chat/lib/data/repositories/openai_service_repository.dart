import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/ai_service_repository.dart';

class OpenAIServiceRepository implements AIServiceRepository {
  final Dio _dio;
  final String _apiKey;

  // SUBSTITUA por sua API key da OpenAI
  static const String _baseUrl = 'https://api.openai.com/v1';

  OpenAIServiceRepository({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  @override
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    try {
      // Buscar informações do contato através do histórico
      final contactLanguage =
          _extractLanguageFromHistory(conversationHistory) ?? 'Português';
      final contactPersonality =
          _extractPersonalityFromHistory(conversationHistory) ?? 'Amigável';

      // Criar prompt contextual
      final systemPrompt = _createSystemPrompt(
        contactLanguage,
        contactPersonality,
      );
      final messages = _buildConversationMessages(
        systemPrompt,
        conversationHistory,
        userMessage,
      );

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo', // ou 'gpt-4' se tiver acesso
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
          'presence_penalty': 0.6,
          'frequency_penalty': 0.3,
        },
      );

      final aiResponse = response.data['choices'][0]['message']['content'];

      return ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: contactId,
        content: aiResponse.trim(),
        type: MessageType.text,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
      );
    } catch (e) {
      print('❌ Erro na OpenAI: $e');

      // Fallback response
      return _createFallbackResponse(conversationId, contactId, userMessage);
    }
  }

  @override
  Future<ChatMessage?> generateModeratorTip({
    required String conversationId,
    required List<ChatMessage> recentMessages,
    required String targetLanguage,
  }) async {
    // Apenas 15% de chance de dica
    if (DateTime.now().millisecondsSinceEpoch % 7 != 0) {
      return null;
    }

    try {
      final prompt = _createModeratorPrompt(targetLanguage, recentMessages);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': prompt},
          ],
          'max_tokens': 100,
          'temperature': 0.5,
        },
      );

      final tip = response.data['choices'][0]['message']['content'];

      return ChatMessage(
        id: 'mod_tip_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: 'moderator',
        senderName: 'Moderador IA',
        content: '💡 $tip',
        type: MessageType.moderatorTip,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
        isModerator: true,
      );
    } catch (e) {
      print('❌ Erro ao gerar dica: $e');
      return null;
    }
  }

  @override
  Future<bool> checkMessageSafety({
    required String message,
    required String language,
  }) async {
    try {
      final response = await _dio.post(
        '/moderations',
        data: {'input': message},
      );

      final results = response.data['results'][0];
      return !results['flagged'];
    } catch (e) {
      print('❌ Erro na moderação: $e');
      // Se der erro, assumir que é seguro
      return true;
    }
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    try {
      // OpenAI Whisper API
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath),
        'model': 'whisper-1',
        'language': 'pt', // ou detectar automaticamente
      });

      final response = await _dio.post('/audio/transcriptions', data: formData);

      return response.data['text'];
    } catch (e) {
      print('❌ Erro na transcrição: $e');
      return 'Não foi possível transcrever o áudio.';
    }
  }

  @override
  Future<String> synthesizeSpeech({
    required String text,
    required String language,
    required String voice,
  }) async {
    try {
      // OpenAI TTS API
      final response = await _dio.post(
        '/audio/speech',
        data: {
          'model': 'tts-1',
          'input': text,
          'voice': _mapVoiceForLanguage(language, voice),
        },
        options: Options(responseType: ResponseType.bytes),
      );

      // Salvar áudio e retornar caminho
      final audioPath = '/tmp/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      // TODO: Implementar salvamento do arquivo

      return audioPath;
    } catch (e) {
      print('❌ Erro na síntese de fala: $e');
      return '';
    }
  }

  // Métodos auxiliares
  String _createSystemPrompt(String language, String personality) {
    final languageInstructions = {
      'Português': 'Responda sempre em português brasileiro.',
      'Inglês': 'Always respond in English.',
      'Espanhol': 'Responde siempre en español.',
      'Francês': 'Répondez toujours en français.',
      'Alemão': 'Antworten Sie immer auf Deutsch.',
      'Italiano': 'Rispondi sempre in italiano.',
    };

    final personalityTraits = {
      'Amigável': 'seja caloroso e acolhedor',
      'Paciente': 'seja calmo e compreensivo',
      'Enérgico': 'seja entusiasmado e motivacional',
      'Humorado': 'seja divertido e use humor apropriado',
      'Sério': 'seja formal e focado no aprendizado',
      'Carismático': 'seja cativante e inspirador',
    };

    return '''
Você é um parceiro de conversação para aprendizado de idiomas.

IDIOMA: ${languageInstructions[language] ?? 'Responda em português.'}

PERSONALIDADE: Seja ${personalityTraits[personality] ?? 'amigável'}.

INSTRUÇÕES:
- Mantenha conversas naturais e envolventes
- Corrija erros sutilmente sem interromper o fluxo
- Faça perguntas para manter o diálogo
- Use vocabulário apropriado para o nível do usuário
- Seja paciente com erros de gramática
- Responda em no máximo 2-3 frases
- Foque no aprendizado prático do idioma
''';
  }

  List<Map<String, String>> _buildConversationMessages(
    String systemPrompt,
    List<ChatMessage> history,
    String newMessage,
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Adicionar últimas 10 mensagens do histórico
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      if (!msg.isModerator) {
        messages.add({
          'role': msg.isFromUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    // Adicionar nova mensagem do usuário
    messages.add({'role': 'user', 'content': newMessage});

    return messages;
  }

  String _createModeratorPrompt(String language, List<ChatMessage> messages) {
    return '''
Você é um moderador educacional especializado em ensino de idiomas.

Analise esta conversa e forneça UMA dica curta e prática para melhorar o aprendizado de $language.

Foque em:
- Gramática
- Vocabulário
- Pronúncia
- Expressões idiomáticas
- Estrutura de frases

Responda apenas a dica, máximo 15 palavras, começando com uma ação (Ex: "Pratique", "Use", "Tente").
''';
  }

  String? _extractLanguageFromHistory(List<ChatMessage> history) {
    // Lógica para detectar idioma baseado no histórico
    // Por simplicidade, retorna null para usar detecção automática
    return null;
  }

  String? _extractPersonalityFromHistory(List<ChatMessage> history) {
    // Lógica para detectar personalidade baseado no histórico
    return null;
  }

  String _mapVoiceForLanguage(String language, String preferredVoice) {
    // Mapear vozes da OpenAI por idioma
    final voiceMap = {
      'Português': 'nova',
      'Inglês': 'alloy',
      'Espanhol': 'nova',
      'Francês': 'shimmer',
      'Alemão': 'onyx',
      'Italiano': 'fable',
    };

    return voiceMap[language] ?? 'alloy';
  }

  ChatMessage _createFallbackResponse(
    String conversationId,
    String contactId,
    String userMessage,
  ) {
    const fallbackResponses = [
      'Desculpe, tive um problema técnico. Pode repetir?',
      'Não consegui processar sua mensagem. Vamos tentar novamente?',
      'Houve um erro na conexão. Como posso ajudá-lo?',
    ];

    final randomResponse =
        fallbackResponses[DateTime.now().second % fallbackResponses.length];

    return ChatMessage(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      chatId: conversationId,
      senderId: contactId,
      content: randomResponse,
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
      isFromUser: false,
    );
  }
}
