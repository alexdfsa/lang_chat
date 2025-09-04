import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/ai_service_repository.dart';

class ClaudeServiceRepository implements AIServiceRepository {
  final Dio _dio;
  final String _apiKey;

  // SUBSTITUA por sua API key da Anthropic
  static const String _baseUrl = 'https://api.anthropic.com';

  ClaudeServiceRepository({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
      'anthropic-version': '2023-06-01',
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
      // Buscar informações do contato
      final contactLanguage =
          _extractLanguageFromHistory(conversationHistory) ?? 'Português';
      final contactPersonality =
          _extractPersonalityFromHistory(conversationHistory) ?? 'Amigável';

      // Criar prompt para Claude
      final systemPrompt = _createSystemPrompt(
        contactLanguage,
        contactPersonality,
      );
      final conversationText = _buildConversationText(
        conversationHistory,
        userMessage,
      );

      final response = await _dio.post(
        '/v1/messages',
        data: {
          'model': 'claude-3-haiku-20240307', // ou 'claude-3-sonnet-20240229'
          'max_tokens': 150,
          'temperature': 0.7,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': conversationText},
          ],
        },
      );

      final aiResponse = response.data['content'][0]['text'];

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
      print('❌ Erro no Claude: $e');
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
      final systemPrompt = _createModeratorSystemPrompt(targetLanguage);
      final conversationContext = _buildRecentMessagesContext(recentMessages);

      final response = await _dio.post(
        '/v1/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 80,
          'temperature': 0.3,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Baseado nesta conversa, que dica você daria?\n\n$conversationContext',
            },
          ],
        },
      );

      final tip = response.data['content'][0]['text'];

      return ChatMessage(
        id: 'mod_tip_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: 'moderator',
        senderName: 'Moderador IA',
        content: '💡 ${tip.trim()}',
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
        '/v1/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 10,
          'temperature': 0.1,
          'system': '''
Você é um moderador de segurança. Analise se a mensagem é apropriada para um contexto educacional de aprendizado de idiomas.

Responda apenas "SEGURA" se a mensagem for apropriada, ou "PERIGOSA" se contiver:
- Conteúdo ofensivo, ódio ou discriminação
- Conteúdo sexual explícito
- Violência ou ameaças
- Conteúdo prejudicial a menores

Seja rigoroso na moderação.
''',
          'messages': [
            {'role': 'user', 'content': 'Analise esta mensagem: "$message"'},
          ],
        },
      );

      final result = response.data['content'][0]['text'].trim().toUpperCase();
      return result.contains('SEGURA');
    } catch (e) {
      print('❌ Erro na moderação: $e');
      // Se der erro, assumir que é seguro
      return true;
    }
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    // Claude não tem API de transcrição de áudio
    // Você pode integrar com outros serviços como AssemblyAI ou Google Speech-to-Text
    print('⚠️ Claude não suporta transcrição de áudio');
    return 'Transcrição de áudio não disponível com Claude.';
  }

  @override
  Future<String> synthesizeSpeech({
    required String text,
    required String language,
    required String voice,
  }) async {
    // Claude não tem API de síntese de fala
    // Você pode integrar com outros serviços como ElevenLabs ou Google TTS
    print('⚠️ Claude não suporta síntese de fala');
    return '';
  }

  // Métodos auxiliares
  String _createSystemPrompt(String language, String personality) {
    final languageInstructions = {
      'Português': 'Responda sempre em português brasileiro natural.',
      'Inglês': 'Always respond in natural English.',
      'Espanhol': 'Responde siempre en español natural.',
      'Francês': 'Répondez toujours en français naturel.',
      'Alemão': 'Antworten Sie immer auf natürlichem Deutsch.',
      'Italiano': 'Rispondi sempre in italiano naturale.',
    };

    final personalityTraits = {
      'Amigável': 'seja caloroso, acolhedor e gentil',
      'Paciente': 'seja calmo, compreensivo e encorajador',
      'Enérgico': 'seja entusiasmado, motivacional e dinâmico',
      'Humorado': 'seja divertido, use humor leve e apropriado',
      'Sério': 'seja formal, focado e metodológico',
      'Carismático': 'seja cativante, inspirador e envolvente',
    };

    return '''
Você é um parceiro de conversação especializado em ensino de idiomas.

IDIOMA: ${languageInstructions[language] ?? 'Responda em português.'}

PERSONALIDADE: ${personalityTraits[personality] ?? 'Seja amigável e acolhedor'}.

DIRETRIZES:
- Mantenha conversas naturais e envolventes
- Corrija erros de forma sutil e educativa
- Faça perguntas abertas para estimular o diálogo
- Adapte o vocabulário ao nível percebido do usuário
- Seja encorajador com progresso e paciente com erros
- Mantenha respostas concisas (máximo 2-3 frases)
- Foque na comunicação prática e funcional
- Use contextos do dia a dia quando apropriado

Seu objetivo é ser um parceiro de conversação que torna o aprendizado natural e divertido.
''';
  }

  String _buildConversationText(List<ChatMessage> history, String newMessage) {
    final buffer = StringBuffer();

    // Adicionar contexto das últimas mensagens
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Contexto da conversa:');
      for (final msg in recentHistory) {
        if (!msg.isModerator) {
          final speaker = msg.isFromUser ? 'Usuário' : 'Assistente';
          buffer.writeln('$speaker: ${msg.content}');
        }
      }
      buffer.writeln('\n---\n');
    }

    buffer.writeln('Nova mensagem do usuário: $newMessage');
    buffer.writeln('\nResponda como o parceiro de conversação:');

    return buffer.toString();
  }

  String _createModeratorSystemPrompt(String targetLanguage) {
    return '''
Você é um moderador educacional especializado em ensino de $targetLanguage.

Analise a conversa e forneça uma dica educativa curta e prática.

Foque em aspectos como:
- Gramática e estrutura
- Vocabulário e expressões
- Pronúncia e fluência
- Contexto cultural
- Erros comuns

Responda apenas com a dica, máximo 12 palavras, seja direto e acionável.
Comece com um verbo de ação (Ex: "Pratique", "Use", "Experimente").
''';
  }

  String _buildRecentMessagesContext(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      if (!msg.isModerator) {
        final speaker = msg.isFromUser ? 'Usuário' : 'IA';
        buffer.writeln('$speaker: ${msg.content}');
      }
    }
    return buffer.toString();
  }

  String? _extractLanguageFromHistory(List<ChatMessage> history) {
    // Implementar lógica de detecção se necessário
    return null;
  }

  String? _extractPersonalityFromHistory(List<ChatMessage> history) {
    // Implementar lógica de detecção se necessário
    return null;
  }

  ChatMessage _createFallbackResponse(
    String conversationId,
    String contactId,
    String userMessage,
  ) {
    const fallbackResponses = [
      'Desculpe, tive um problema técnico. Pode repetir?',
      'Não consegui processar sua mensagem. Vamos continuar?',
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
