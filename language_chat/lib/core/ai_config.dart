class AIConfig {
  // Configurações gerais (não sensíveis)
  static const bool enableModeratorTips = true;
  static const bool enableSafetyCheck = true;
  static const bool enableDebugLogs = true;

  // ✅ MODELOS GROQ ATUALIZADOS (Janeiro 2025)
  static const String defaultOpenAIModel = 'gpt-3.5-turbo';
  static const String defaultClaudeModel = 'claude-3-haiku-20240307';
  static const String defaultGroqModel = 'llama-3.1-8b-instant'; // ATUALIZADO!

  // ✅ Modelos disponíveis no Groq (atualizados)
  static const Map<String, List<String>> availableModels = {
    'openai': ['gpt-3.5-turbo', 'gpt-4', 'gpt-4-turbo'],
    'claude': [
      'claude-3-haiku-20240307',
      'claude-3-sonnet-20240229',
      'claude-3-opus-20240229',
    ],
    'groq': [
      // ✅ MODELOS ATUAIS DO GROQ (Janeiro 2025)
      'llama-3.1-8b-instant', // Novo padrão - rápido e eficiente
      'llama-3.1-70b-versatile', // Mais inteligente
      'llama-3.2-1b-preview', // Muito rápido, menos recursos
      'llama-3.2-3b-preview', // Balanceado
      'llama-3.2-11b-vision-preview', // Com visão (experimental)
      'llama-3.2-90b-vision-preview', // Visão + inteligência
      'mixtral-8x7b-32768', // Ainda disponível
      'gemma2-9b-it', // Google Gemma 2
    ],
  };

  // Configurações de performance
  static const Map<String, dynamic> modelSettings = {
    'temperature': 0.7,
    'maxTokens': 150,
    'topP': 0.9,
    'frequencyPenalty': 0.3,
    'presencePenalty': 0.6,
  };

  // Provider padrão
  static const String defaultProvider = 'groq';

  // ✅ Informações dos novos modelos
  static const Map<String, Map<String, String>> modelInfo = {
    'llama-3.1-8b-instant': {
      'name': 'Llama 3.1 8B Instant',
      'speed': 'Muito Rápido',
      'quality': 'Excelente',
      'cost': 'Baixo',
      'context': '128k tokens',
      'recommended': 'Produção geral',
    },
    'llama-3.1-70b-versatile': {
      'name': 'Llama 3.1 70B Versatile',
      'speed': 'Rápido',
      'quality': 'Superior',
      'cost': 'Médio',
      'context': '128k tokens',
      'recommended': 'Qualidade máxima',
    },
    'llama-3.2-11b-vision-preview': {
      'name': 'Llama 3.2 11B Vision',
      'speed': 'Rápido',
      'quality': 'Excelente + Visão',
      'cost': 'Médio',
      'context': '128k tokens',
      'recommended': 'Futuro com imagens',
    },
    'mixtral-8x7b-32768': {
      'name': 'Mixtral 8x7B',
      'speed': 'Rápido',
      'quality': 'Excelente',
      'cost': 'Baixo',
      'context': '32k tokens',
      'recommended': 'Contexto grande',
    },
  };
}

enum AIProvider { openai, claude, groq, mock }
