import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/ai_service_repository.dart';

class GroqServiceRepository implements AIServiceRepository {
  final Dio _dio;
  final String _apiKey;

  // Groq API Configuration - MODELOS ATUALIZADOS
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _defaultModel =
      'llama-3.1-8b-instant'; // ✅ NOVO MODELO PADRÃO

  // ✅ Modelos disponíveis atualizados (Janeiro 2025)
  static const Map<String, String> availableModels = {
    'fast': 'llama-3.1-8b-instant', // Rápido para produção
    'smart': 'llama-3.1-70b-versatile', // Mais inteligente
    'vision': 'llama-3.2-11b-vision-preview', // Com visão (futuro)
    'context': 'mixtral-8x7b-32768', // Contexto grande
    'tiny': 'llama-3.2-3b-preview', // Muito rápido
  };

  GroqServiceRepository({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Interceptor para debug
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Menos verbose
        responseBody: false,
        logPrint: (obj) =>
            print('🦙 Groq: ${obj.toString().substring(0, 100)}...'),
      ),
    );
  }

  @override
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    try {
      print('🚀 Enviando para Groq Llama 3.1: "$userMessage"'); // Debug

      // Extrair informações do contato
      final contactLanguage =
          _extractLanguageFromHistory(conversationHistory) ?? 'Português';
      final contactPersonality =
          _extractPersonalityFromHistory(conversationHistory) ?? 'Amigável';

      // Usar modelo da configuração ou padrão
      final model = _getModelFromConfig();
      print('🦙 Usando modelo: $model'); // Debug

      // Criar prompt otimizado para Llama 3.1
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
          'model': model,
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
          'top_p': 0.9,
          'frequency_penalty': 0.3,
          'presence_penalty': 0.6,
          // Remover stop tokens específicos - usar padrão do modelo
        },
      );

      final aiResponse = response.data['choices'][0]['message']['content'];

      print(
        '✅ Resposta do Groq recebida: "${aiResponse.toString().substring(0, 50)}..."',
      ); // Debug

      return ChatMessage(
        id: 'groq_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: contactId,
        content: _cleanResponse(aiResponse.trim()),
        type: MessageType.text,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
      );
    } catch (e) {
      print('❌ Erro no Groq: $e');

      if (e is DioException) {
        print('❌ Detalhes do erro Groq: ${e.response?.data}');

        // Verificar se é erro de modelo descontinuado
        final errorMessage =
            e.response?.data?['error']?['message']?.toString() ?? '';
        if (errorMessage.contains('decommissioned') ||
            errorMessage.contains('deprecated')) {
          print(
            '⚠️ Modelo descontinuado detectado, tentando modelo alternativo...',
          );
          return await _retryWithFallbackModel(
            contactId,
            conversationId,
            conversationHistory,
            userMessage,
          );
        }
      }

      return _createFallbackResponse(conversationId, contactId, userMessage);
    }
  }

  // ✅ Método para tentar modelo alternativo se o atual falhar
  Future<ChatMessage> _retryWithFallbackModel(
    String contactId,
    String conversationId,
    List<ChatMessage> conversationHistory,
    String userMessage,
  ) async {
    final fallbackModels = [
      'llama-3.1-8b-instant',
      'llama-3.1-70b-versatile',
      'mixtral-8x7b-32768',
      'llama-3.2-3b-preview',
    ];

    for (final model in fallbackModels) {
      try {
        print('🔄 Tentando modelo alternativo: $model');

        final contactLanguage =
            _extractLanguageFromHistory(conversationHistory) ?? 'Português';
        final contactPersonality =
            _extractPersonalityFromHistory(conversationHistory) ?? 'Amigável';
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
            'model': model,
            'messages': messages,
            'max_tokens': 150,
            'temperature': 0.7,
          },
        );

        final aiResponse = response.data['choices'][0]['message']['content'];
        print('✅ Sucesso com modelo alternativo: $model');

        return ChatMessage(
          id: 'groq_fallback_${DateTime.now().millisecondsSinceEpoch}',
          chatId: conversationId,
          senderId: contactId,
          content: _cleanResponse(aiResponse.trim()),
          type: MessageType.text,
          status: MessageStatus.delivered,
          timestamp: DateTime.now(),
          isFromUser: false,
        );
      } catch (e) {
        print('❌ Modelo $model também falhou: $e');
        continue;
      }
    }

    // Se todos os modelos falharam
    return _createFallbackResponse(conversationId, contactId, userMessage);
  }

  @override
  Future<ChatMessage?> generateModeratorTip({
    required String conversationId,
    required List<ChatMessage> recentMessages,
    required String targetLanguage,
  }) async {
    // Apenas 15% de chance de dica
    if (DateTime.now().millisecondsSinceEpoch % 6 != 0) {
      return null;
    }

    try {
      final prompt = _createModeratorPrompt(targetLanguage, recentMessages);
      final model = _getModelFromConfig(
        'fast',
      ); // Usar modelo rápido para dicas

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': prompt},
            {
              'role': 'user',
              'content': 'Gere uma dica educativa baseada na conversa.',
            },
          ],
          'max_tokens': 80,
          'temperature': 0.5,
        },
      );

      final tip = response.data['choices'][0]['message']['content'];

      return ChatMessage(
        id: 'groq_tip_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: 'moderator',
        senderName: 'Moderador IA',
        content: '💡 ${_cleanResponse(tip.trim())}',
        type: MessageType.moderatorTip,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
        isModerator: true,
      );
    } catch (e) {
      print('❌ Erro ao gerar dica no Groq: $e');
      return null;
    }
  }

  @override
  Future<bool> checkMessageSafety({
    required String message,
    required String language,
  }) async {
    try {
      final model = _getModelFromConfig('fast'); // Modelo rápido para moderação

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''
Você é um moderador de segurança para um app educacional de idiomas.

Analise se a mensagem é apropriada. Responda apenas:
- "SEGURA" se for apropriada para educação
- "PERIGOSA" se contiver: ódio, violência, conteúdo sexual, discriminação, ameaças

Seja rigoroso na moderação. Foque na segurança de menores.''',
            },
            {'role': 'user', 'content': 'Analise esta mensagem: "$message"'},
          ],
          'max_tokens': 10,
          'temperature': 0.1,
        },
      );

      final result = response.data['choices'][0]['message']['content']
          .trim()
          .toUpperCase();
      return result.contains('SEGURA');
    } catch (e) {
      print('❌ Erro na moderação Groq: $e');
      // Se der erro, assumir que é seguro
      return true;
    }
  }

  // Métodos auxiliares atualizados

  String _getModelFromConfig([String? preference]) {
    // Tentar pegar do environment config primeiro
    try {
      // Importar EnvironmentConfig se disponível
      // Por simplicidade, usar modelo padrão
      return preference != null
          ? (availableModels[preference] ?? _defaultModel)
          : _defaultModel;
    } catch (e) {
      return _defaultModel;
    }
  }

  String _createSystemPrompt(String language, String personality) {
    final languageInstructions = {
      'Português': 'Responda SEMPRE em português brasileiro natural e fluente.',
      'Inglês': 'Always respond in natural, fluent English.',
      'Espanhol': 'Responde SIEMPRE en español natural y fluido.',
      'Francês': 'Répondez TOUJOURS en français naturel et fluide.',
      'Alemão': 'Antworten Sie IMMER auf natürlichem, fließendem Deutsch.',
      'Italiano': 'Rispondi SEMPRE in italiano naturale e fluente.',
      'Japonês': '常に自然で流暢な日本語で応答してください。',
      'Chinês': '请始终用自然流利的中文回应。',
      'Coreano': '항상 자연스럽고 유창한 한국어로 응답하세요.',
    };

    final personalityTraits = {
      'Amigável': 'seja caloroso, acolhedor e muito amigável',
      'Paciente': 'seja extremamente calmo, compreensivo e encorajador',
      'Enérgico': 'seja muito entusiasmado, motivacional e energético',
      'Humorado': 'seja divertido, use humor leve e seja bem-humorado',
      'Sério': 'seja formal, focado no aprendizado e metodológico',
      'Carismático': 'seja muito cativante, inspirador e envolvente',
      'Calmo': 'seja tranquilo, sereno e relaxante',
      'Encorajador': 'seja muito positivo, motivador e inspirador',
    };

    return '''
Você é um parceiro de conversação especializado em ensino de idiomas usando Llama 3.1.

IDIOMA OBRIGATÓRIO: ${languageInstructions[language] ?? 'Responda em português brasileiro.'}

PERSONALIDADE: ${personalityTraits[personality] ?? 'Seja amigável e acolhedor'}.

INSTRUÇÕES PARA LLAMA 3.1:
- Mantenha conversas MUITO naturais e fluentes
- Corrija erros de forma sutil, sem interromper
- Faça perguntas engajadoras para manter o diálogo
- Use vocabulário apropriado ao nível do usuário
- Seja paciente e encorajador com erros
- Mantenha respostas concisas (1-3 frases máximo)
- Use contextos do cotidiano quando possível
- Seja conversacional, não formal demais

OBJETIVO: Ser o melhor parceiro de conversação para aprendizado natural de idiomas.''';
  }

  List<Map<String, String>> _buildConversationMessages(
    String systemPrompt,
    List<ChatMessage> history,
    String newMessage,
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Adicionar últimas 8 mensagens do histórico
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
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
Você é um moderador educacional especializado em ensino de $language usando Llama 3.1.

Analise a conversa e forneça UMA dica educativa curta e muito prática.

FOQUE EM:
- Gramática específica do idioma
- Vocabulário útil e expressões
- Pronúncia e entonação
- Estruturas de frases importantes
- Erros comuns a evitar
- Dicas culturais relevantes

FORMATO: Máximo 12 palavras, seja direto e acionável.
COMECE: Com verbo de ação (Pratique, Use, Experimente, Tente, Foque).''';
  }

  String? _extractLanguageFromHistory(List<ChatMessage> history) {
    if (history.isEmpty) return null;

    for (final message in history.reversed) {
      if (!message.isFromUser && !message.isModerator) {
        final content = message.content.toLowerCase();

        // Detectar idioma por padrões
        if (content.contains('hello') ||
            content.contains('how are you') ||
            content.contains('what') ||
            content.contains('english')) {
          return 'Inglês';
        } else if (content.contains('hola') ||
            content.contains('cómo') ||
            content.contains('qué') ||
            content.contains('español')) {
          return 'Espanhol';
        }
        // ... outros idiomas
      }
    }

    return null;
  }

  String? _extractPersonalityFromHistory(List<ChatMessage> history) {
    if (history.isEmpty) return null;

    final recentMessages = history
        .take(5)
        .map((m) => m.content.toLowerCase())
        .join(' ');

    if (recentMessages.contains('😄') ||
        recentMessages.contains('haha') ||
        recentMessages.contains('funny') ||
        recentMessages.contains('divertido')) {
      return 'Humorado';
    } else if (recentMessages.contains('energy') ||
        recentMessages.contains('excited') ||
        recentMessages.contains('energia') ||
        recentMessages.contains('vamos')) {
      return 'Enérgico';
    }

    return null;
  }

  String _cleanResponse(String response) {
    // Limpar possíveis artefatos de resposta
    return response
        .replaceAll('<|eot_id|>', '')
        .replaceAll('<|start_header_id|>', '')
        .replaceAll('<|end_header_id|>', '')
        .replaceAll('<|begin_of_text|>', '')
        .trim();
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
      'Problema temporário no servidor. Continue nossa conversa!',
    ];

    final randomResponse =
        fallbackResponses[DateTime.now().second % fallbackResponses.length];

    return ChatMessage(
      id: 'groq_fallback_${DateTime.now().millisecondsSinceEpoch}',
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
  Future<String> transcribeAudio(String audioPath) async {
    print('⚠️ Groq não suporta transcrição de áudio ainda');
    return 'Transcrição de áudio não disponível com Groq. Use OpenAI Whisper.';
  }

  @override
  Future<String> synthesizeSpeech({
    required String text,
    required String language,
    required String voice,
  }) async {
    print('⚠️ Groq não suporta síntese de fala');
    return '';
  }
}
