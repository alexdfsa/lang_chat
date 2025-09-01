import 'package:language_chat/core/dependency_injection.dart';
import 'package:language_chat/domain/entities/chat_message.dart';
import 'package:language_chat/domain/repositories/ai_service_repository.dart';
import 'package:language_chat/domain/repositories/contact_repository.dart';

class MockAIServiceRepository implements AIServiceRepository {
  // Respostas por idioma
  static const Map<String, List<String>> responsesByLanguage = {
    'Português': [
      'Olá! Como você está hoje?',
      'Isso é muito interessante! Pode me contar mais?',
      'Sua pronúncia está melhorando muito!',
      'Que tal praticarmos alguns verbos em português?',
      'Excelente! Vamos continuar nossa conversa.',
      'Como foi seu dia? Conte-me em português!',
      'Ótimo! Você está se expressando muito bem.',
      'Vamos praticar mais vocabulário?',
    ],
    'Inglês': [
      'Hello! How are you doing today?',
      'That sounds really interesting! Can you tell me more?',
      'Your English pronunciation is getting much better!',
      'How about we practice some English verbs?',
      'Excellent! Let\'s continue our conversation.',
      'How was your day? Tell me in English!',
      'Great! You\'re expressing yourself very well.',
      'Would you like to practice more vocabulary?',
    ],
    'Espanhol': [
      '¡Hola! ¿Cómo estás hoy?',
      '¡Eso suena muy interesante! ¿Puedes contarme más?',
      'Tu pronunciación en español está mejorando mucho.',
      '¿Qué tal si practicamos algunos verbos en español?',
      '¡Excelente! Sigamos con nuestra conversación.',
      '¿Cómo estuvo tu día? ¡Cuéntame en español!',
      '¡Genial! Te estás expresando muy bien.',
      '¿Te gustaría practicar más vocabulario?',
    ],
    'Francês': [
      'Bonjour! Comment allez-vous aujourd\'hui?',
      'C\'est très intéressant! Pouvez-vous me dire plus?',
      'Votre prononciation française s\'améliore beaucoup!',
      'Que diriez-vous de pratiquer quelques verbes français?',
      'Excellent! Continuons notre conversation.',
      'Comment était votre journée? Racontez-moi en français!',
      'Parfait! Vous vous exprimez très bien.',
      'Aimeriez-vous pratiquer plus de vocabulaire?',
    ],
    'Alemão': [
      'Hallo! Wie geht es Ihnen heute?',
      'Das klingt sehr interessant! Können Sie mir mehr erzählen?',
      'Ihre deutsche Aussprache wird viel besser!',
      'Wie wäre es, wenn wir einige deutsche Verben üben?',
      'Ausgezeichnet! Lassen Sie uns unser Gespräch fortsetzen.',
      'Wie war Ihr Tag? Erzählen Sie mir auf Deutsch!',
      'Großartig! Sie drücken sich sehr gut aus.',
      'Möchten Sie mehr Vokabeln üben?',
    ],
    'Italiano': [
      'Ciao! Come stai oggi?',
      'Questo è molto interessante! Puoi dirmi di più?',
      'La tua pronuncia italiana sta migliorando molto!',
      'Che ne dici di praticare alcuni verbi italiani?',
      'Eccellente! Continuiamo la nostra conversazione.',
      'Com\'è andata la giornata? Raccontami in italiano!',
      'Fantastico! Ti stai esprimendo molto bene.',
      'Vorresti praticare più vocabolario?',
    ],
    'Japonês': [
      'こんにちは！今日はいかがですか？',
      'とても面白いですね！もっと教えてください。',
      '日本語の発音がとても上達していますね！',
      '日本語の動詞を練習してみませんか？',
      '素晴らしい！会話を続けましょう。',
      '今日はどうでしたか？日本語で教えてください！',
      'すごい！とてもよく表現できています。',
      'もっと語彙を練習しますか？',
    ],
    'Chinês': [
      '你好！你今天怎么样？',
      '这很有趣！你能告诉我更多吗？',
      '你的中文发音进步了很多！',
      '我们练习一些中文动词怎么样？',
      '太好了！让我们继续对话。',
      '你今天过得怎么样？用中文告诉我！',
      '很棒！你表达得很好。',
      '你想练习更多词汇吗？',
    ],
    'Coreano': [
      '안녕하세요! 오늘 어떠세요?',
      '정말 흥미롭네요! 더 말씀해 주시겠어요?',
      '한국어 발음이 많이 늘었네요!',
      '한국어 동사를 연습해 볼까요?',
      '훌륭합니다! 대화를 계속해요.',
      '오늘 하루 어떠셨나요? 한국어로 말해보세요!',
      '대단해요! 아주 잘 표현하고 있어요.',
      '어휘를 더 연습해 볼까요?',
    ],
  };

  // Dicas por idioma
  static const Map<String, List<String>> tipsByLanguage = {
    'Português': [
      '💡 Dica: Pratique a conjugação dos verbos no passado para melhorar sua fluência.',
      '💡 Dica: Use mais conectivos como "além disso", "portanto", "entretanto".',
      '💡 Dica: Preste atenção à concordância entre substantivos e adjetivos.',
      '💡 Dica: Pratique a pronuncia do "ão" - é característico do português!',
    ],
    'Inglês': [
      '💡 Tip: Try using more phrasal verbs to sound more natural.',
      '💡 Tip: Practice the past continuous tense for better storytelling.',
      '💡 Tip: Pay attention to the pronunciation of "th" sounds.',
      '💡 Tip: Use contractions (I\'m, you\'re, it\'s) in informal conversations.',
    ],
    'Espanhol': [
      '💡 Consejo: Practica los tiempos subjuntivos para expresar emociones.',
      '💡 Consejo: Usa más expresiones idiomáticas para sonar más natural.',
      '💡 Consejo: Presta atención a la diferencia entre "ser" y "estar".',
      '💡 Consejo: Practica la pronunciación de la "rr" fuerte.',
    ],
    'Francês': [
      '💡 Conseil: Pratiquez la liaison entre les mots pour une meilleure fluidité.',
      '💡 Conseil: Utilisez plus d\'expressions avec le subjonctif.',
      '💡 Conseil: Attention à l\'accord des participes passés.',
      '💡 Conseil: Pratiquez la prononciation nasale (an, en, in, on).',
    ],
    'Alemão': [
      '💡 Tipp: Üben Sie die Deklination der Adjektive.',
      '💡 Tipp: Verwenden Sie mehr trennbare Verben im Gespräch.',
      '💡 Tipp: Achten Sie auf die Wortstellung in Nebensätzen.',
      '💡 Tipp: Üben Sie die Aussprache der Umlaute (ä, ö, ü).',
    ],
    'Italiano': [
      '💡 Suggerimento: Pratica l\'uso del congiuntivo per esprimere opinioni.',
      '💡 Suggerimento: Usa più gesti nelle conversazioni - è molto italiano!',
      '💡 Suggerimento: Attenzione alla pronuncia doppia (cc, ll, rr).',
      '💡 Suggerimento: Pratica le preposizioni articolate.',
    ],
    'Japonês': [
      '💡 ヒント: 敬語の使い分けを練習しましょう。',
      '💡 ヒント: もっと自然な助詞の使い方を練習してください。',
      '💡 ヒント: 長音（ー）の発音に注意してください。',
      '💡 ヒント: カタカナ語の発音を日本語らしくしてみましょう。',
    ],
    'Chinês': [
      '💡 提示: 练习声调的变化，这对中文很重要。',
      '💡 提示: 多使用一些成语来丰富表达。',
      '💡 提示: 注意"的"、"地"、"得"的区别。',
      '💡 提示: 练习卷舌音和平舌音的区别。',
    ],
    'Coreano': [
      '💡 팁: 높임말과 반말의 구분을 연습해보세요.',
      '💡 팁: 더 많은 의성어와 의태어를 사용해보세요.',
      '💡 팁: 받침 발음을 정확히 하는 것이 중요해요.',
      '💡 팁: 문장 끝에 감정을 표현하는 어미를 사용해보세요.',
    ],
  };

  @override
  Future<ChatMessage> generateContactResponse({
    required String contactId,
    required String conversationId,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Buscar o contato para pegar o idioma
      final contactRepository = getIt<ContactRepository>();
      final contact = await contactRepository.getContactById(contactId);

      if (contact == null) {
        throw Exception('Contato não encontrado');
      }

      final contactLanguage = contact.language;
      final responses =
          responsesByLanguage[contactLanguage] ??
          responsesByLanguage['Português']!;

      // Escolher resposta baseada no contexto da conversa
      String selectedResponse;

      if (conversationHistory.isEmpty) {
        // Primeira mensagem - cumprimento
        selectedResponse = responses[0];
      } else {
        // Resposta baseada na mensagem do usuário ou aleatória
        if (userMessage.toLowerCase().contains('hello') ||
            userMessage.toLowerCase().contains('oi') ||
            userMessage.toLowerCase().contains('hola')) {
          selectedResponse = responses[0];
        } else if (userMessage.toLowerCase().contains('como') ||
            userMessage.toLowerCase().contains('how') ||
            userMessage.toLowerCase().contains('cómo')) {
          selectedResponse = responses[5]; // "Como foi seu dia?"
        } else {
          // Resposta aleatória
          final randomIndex =
              DateTime.now().millisecondsSinceEpoch % responses.length;
          selectedResponse = responses[randomIndex];
        }
      }

      // Personalizar resposta com base no temperamento
      selectedResponse = _personalizeResponseByTemperament(
        selectedResponse,
        contact.temperament,
        contactLanguage,
      );

      return ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: contactId,
        senderName: contact.name,
        content: selectedResponse,
        type: MessageType.text,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
      );
    } catch (e) {
      // Fallback para português
      const fallbackResponse =
          'Desculpe, houve um erro. Vamos continuar nossa conversa!';
      return ChatMessage(
        id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
        chatId: conversationId,
        senderId: contactId,
        content: fallbackResponse,
        type: MessageType.text,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        isFromUser: false,
      );
    }
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

    final tips = tipsByLanguage[targetLanguage] ?? tipsByLanguage['Português']!;
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
    final unsafeWords = [
      'hate',
      'violence',
      'inappropriate',
      'ódio',
      'violência',
    ];
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

  String _personalizeResponseByTemperament(
    String response,
    String temperament,
    String language,
  ) {
    switch (temperament.toLowerCase()) {
      case 'enérgico':
        if (language == 'Inglês')
          return '$response Let\'s practice with energy!';
        if (language == 'Espanhol')
          return '$response ¡Practiquemos con energía!';
        return '$response Vamos praticar com energia!';

      case 'paciente':
        if (language == 'Inglês')
          return '$response Take your time, I\'m here to help.';
        if (language == 'Espanhol')
          return '$response Tómate tu tiempo, estoy aquí para ayudar.';
        return '$response Não tenha pressa, estou aqui para ajudar.';

      case 'humorado':
        if (language == 'Inglês') return '$response 😄 Learning should be fun!';
        if (language == 'Espanhol')
          return '$response 😄 ¡Aprender debe ser divertido!';
        return '$response 😄 Aprender deve ser divertido!';

      default:
        return response;
    }
  }
}
