import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:langchat/core/environment_config.dart';
import 'package:langchat/domain/entities/chat_message.dart';
import 'package:langchat/domain/repositories/ai_service_repository.dart';

class GroqServiceRepository implements AIServiceRepository {
  final Dio _dio;
  final String _apiKey;

  // Groq API Configuration - MODELOS ATUALIZADOS
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _defaultModel = 'llama-3.1-8b-instant';

  GroqServiceRepository({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio() {
    print(
      '🔧 Inicializando GroqServiceRepository com API key: ${_apiKey.substring(0, 10)}...',
    ); // Debug
    print(
      '🦙 Modelo configurado no .env: ${EnvironmentConfig.groqModel}',
    ); // Debug

    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // Interceptor para debug melhorado
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) {
          print('🔍 DIO LOG: $obj');
        },
      ),
    );
  }

  @override
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
    required String language,
  }) async {
    try {
      print('🚀 [GROQ] Enviando mensagem: "$userMessage"'); // Debug

      // Validar API key
      if (_apiKey.isEmpty ||
          _apiKey.contains('SUA_CHAVE') ||
          _apiKey.contains('YOUR_')) {
        throw Exception('API Key do Groq não configurada corretamente');
      }

      // Usar o idioma fornecido e extrair a personalidade do histórico
      final contactPersonality =
          _extractPersonalityFromHistory(conversationHistory) ?? 'Amigável';

      print(
        '🌐 Idioma: $language, Personalidade: $contactPersonality',
      ); // Debug

      // Criar prompt otimizado
      final systemPrompt = _createSystemPrompt(language, contactPersonality);
      final messages = _buildConversationMessages(
        systemPrompt,
        conversationHistory,
        userMessage,
      );

      print('📝 Enviando ${messages.length} mensagens para a API'); // Debug

      final requestData = {
        'model': _defaultModel,
        'messages': messages,
        'max_tokens': 150,
        'temperature': 0.7,
        'top_p': 0.9,
        'frequency_penalty': 0.3,
        'presence_penalty': 0.6,
      };

      print('📦 Request data: ${jsonEncode(requestData)}'); // Debug

      final response = await _dio.post('/chat/completions', data: requestData);

      print('✅ Status da resposta: ${response.statusCode}'); // Debug
      print('📄 Resposta completa: ${response.data}'); // Debug

      if (response.statusCode == 200 && response.data != null) {
        final choices = response.data['choices'];
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'];
          if (content != null) {
            final cleanContent = _cleanResponse(content.toString().trim());
            print('🎯 Resposta limpa: "$cleanContent"'); // Debug

            return ChatMessage(
              id: 'groq_${DateTime.now().millisecondsSinceEpoch}',
              chatId: conversationId,
              senderId: contactId,
              content: cleanContent,
              type: MessageType.text,
              status: MessageStatus.delivered,
              timestamp: DateTime.now(),
              isFromUser: false,
            );
          }
        }
        throw Exception('Resposta da API inválida - sem conteúdo');
      } else {
        throw Exception('Status code inválido: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [GROQ] DioException capturada:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      print('   Error: ${e.error}');
      print('   RequestOptions: ${e.requestOptions.uri}');
      print('   Response StatusCode: ${e.response?.statusCode}');
      print('   Response Data: ${e.response?.data}');

      // Tratamento específico por tipo de erro
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Timeout na conexão com Groq. Verifique sua internet.';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            errorMessage =
                'API Key do Groq inválida. Verifique suas credenciais.';
          } else if (e.response?.statusCode == 429) {
            errorMessage =
                'Limite de requisições excedido. Tente novamente em alguns segundos.';
          } else {
            errorMessage = 'Erro do servidor Groq: ${e.response?.statusCode}';
          }
          break;
        case DioExceptionType.unknown:
          if (e.error.toString().contains('SocketException')) {
            errorMessage = 'Erro de conexão. Verifique sua internet.';
          } else {
            errorMessage = 'Erro de rede desconhecido: ${e.error}';
          }
          break;
        default:
          errorMessage = 'Erro de conexão com Groq: ${e.message}';
      }

      print('💬 Erro interpretado: $errorMessage'); // Debug
      return _createFallbackResponse(
        conversationId,
        contactId,
        userMessage,
        errorMessage,
      );
    } catch (e, stackTrace) {
      print('❌ [GROQ] Erro inesperado: $e');
      print('📍 StackTrace: $stackTrace');
      return _createFallbackResponse(
        conversationId,
        contactId,
        userMessage,
        'Erro inesperado: $e',
      );
    }
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

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': _defaultModel,
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
      print('❌ [GROQ] Erro ao gerar dica: $e');
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
        '/chat/completions',
        data: {
          'model': _defaultModel,
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
      print('❌ [GROQ] Erro na moderação: $e');
      // Se der erro, assumir que é seguro
      return true;
    }
  }

  // Métodos auxiliares

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
Você é um parceiro de conversação especializado em ensino de idiomas.

IDIOMA OBRIGATÓRIO: ${languageInstructions[language] ?? 'Responda em português brasileiro.'}

PERSONALIDADE: ${personalityTraits[personality] ?? 'Seja amigável e acolhedor'}.

INSTRUÇÕES:
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

    // Adicionar últimas 6 mensagens do histórico (para evitar contexto muito grande)
    final recentHistory = history.length > 6
        ? history.sublist(history.length - 6)
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
Você é um moderador educacional especializado em ensino de $language.

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

    for (final message in history.reversed.take(3)) {
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
        // Adicionar outros idiomas conforme necessário
      }
    }

    return null;
  }

  String? _extractPersonalityFromHistory(List<ChatMessage> history) {
    if (history.isEmpty) return null;

    final recentMessages = history
        .take(3)
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
    // Limpar possíveis artefatos de resposta do Llama
    return response
        .replaceAll('<|eot_id|>', '')
        .replaceAll('<|start_header_id|>', '')
        .replaceAll('<|end_header_id|>', '')
        .replaceAll('<|begin_of_text|>', '')
        .replaceAll('</s>', '')
        .replaceAll('<s>', '')
        .trim();
  }

  Future<ChatMessage> _createFallbackResponse(
    String conversationId,
    String contactId,
    String userMessage,
    String errorDetail,
  ) async {
    // Respostas de fallback melhoradas baseadas no idioma detectado
    Map<String, List<String>> fallbackResponses = {
      'pt': [
        'Desculpe, tive um problema técnico. Pode repetir sua mensagem?',
        'Não consegui processar sua mensagem. Vamos tentar novamente?',
        'Houve um erro na conexão. Como posso ajudá-lo?',
        'Problema temporário no servidor. Continue nossa conversa!',
      ],
      'en': [
        'Sorry, I had a technical problem. Could you repeat your message?',
        'I couldn\'t process your message. Shall we try again?',
        'There was a connection error. How can I help you?',
        'Temporary server issue. Let\'s continue our conversation!',
      ],
      'es': [
        'Disculpa, tuve un problema técnico. ¿Puedes repetir tu mensaje?',
        'No pude procesar tu mensaje. ¿Intentamos de nuevo?',
        'Hubo un error de conexión. ¿Cómo puedo ayudarte?',
        'Problema temporal del servidor. ¡Continuemos nuestra conversación!',
      ],
    };

    // Detectar idioma baseado na mensagem do usuário
    String lang = 'pt'; // padrão
    if (userMessage.toLowerCase().contains(
      RegExp(r'\b(hello|hi|how|what|the|and)\b'),
    )) {
      lang = 'en';
    } else if (userMessage.toLowerCase().contains(
      RegExp(r'\b(hola|cómo|qué|el|la|y)\b'),
    )) {
      lang = 'es';
    }

    final responses = fallbackResponses[lang] ?? fallbackResponses['pt']!;
    final randomResponse = responses[DateTime.now().second % responses.length];

    print(
      '🔄 Usando resposta de fallback: "$randomResponse" (Erro: $errorDetail)',
    ); // Debug

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
