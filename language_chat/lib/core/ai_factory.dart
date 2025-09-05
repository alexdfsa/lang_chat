import 'package:langchat/core/environment_config.dart';
import 'package:langchat/data/repositories/claude_service_repository.dart';
import 'package:langchat/data/repositories/groq_service_repository.dart';
import 'package:langchat/data/repositories/mock_ai_service_repository.dart';
import 'package:langchat/data/repositories/openai_service_repository.dart';
import 'package:langchat/domain/repositories/ai_service_repository.dart';

import 'ai_config.dart';

class AIFactory {
  static AIServiceRepository createAIService() {
    final provider = EnvironmentConfig.getAIProvider();

    print('🤖 Inicializando AI Provider: ${provider.name}'); // Debug

    switch (provider) {
      case AIProvider.openai:
        final apiKey = EnvironmentConfig.getApiKey('OPENAI_API_KEY');
        if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
          print('⚠️ API Key da OpenAI não configurada, usando Mock'); // Debug
          return MockAIServiceRepository();
        }
        print('✅ OpenAI configurada'); // Debug
        return OpenAIServiceRepository(apiKey: apiKey);

      case AIProvider.claude:
        final apiKey = EnvironmentConfig.getApiKey('CLAUDE_API_KEY');
        if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
          print('⚠️ API Key do Claude não configurada, usando Mock'); // Debug
          return MockAIServiceRepository();
        }
        print('✅ Claude configurado'); // Debug
        return ClaudeServiceRepository(apiKey: apiKey);

      case AIProvider.groq:
        final apiKey = EnvironmentConfig.getApiKey('GROQ_API_KEY');
        if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
          print('⚠️ API Key do Groq não configurada, usando Mock'); // Debug
          return MockAIServiceRepository();
        }
        print('✅ Groq + Llama 3 configurado'); // Debug
        print('🦙 Modelo: ${EnvironmentConfig.groqModel}'); // Debug
        return GroqServiceRepository(apiKey: apiKey);

      case AIProvider.mock:
        print('🎭 Usando Mock AI Service'); // Debug
        return MockAIServiceRepository();
    }
  }

  // Método para obter informações sobre o provider atual
  static Map<String, dynamic> getCurrentProviderInfo() {
    final provider = EnvironmentConfig.getAIProvider();
    final modelInfo = EnvironmentConfig.getCurrentModelInfo();

    return {
      'provider': provider.name,
      'configured': EnvironmentConfig.isProviderConfigured(provider),
      'info': modelInfo,
    };
  }

  // Método para verificar se o provider está funcionando
  static Future<bool> testCurrentProvider() async {
    try {
      final aiService = createAIService();

      // Teste simples de segurança (mais rápido)
      final isSafe = await aiService.checkMessageSafety(
        message: 'Hello, how are you?',
        language: 'English',
      );

      return isSafe;
    } catch (e) {
      print('❌ Erro no teste do provider: $e'); // Debug
      return false;
    }
  }

  // Método para listar todos os providers disponíveis
  static List<Map<String, dynamic>> getAvailableProviders() {
    return [
      {
        'provider': AIProvider.groq,
        'name': 'Groq + Llama 3',
        'configured': EnvironmentConfig.isProviderConfigured(AIProvider.groq),
        'benefits': [
          '⚡ Velocidade extrema (até 500 tokens/s)',
          '💰 Muito mais barato que GPT-4',
          '🔓 Open-source (Llama 3)',
          '🎯 Qualidade competitiva',
          '🚀 Baixa latência',
        ],
        'models': [
          'llama3-8b-8192 (Rápido)',
          'llama3-70b-8192 (Inteligente)',
          'mixtral-8x7b-32768 (Contexto grande)',
        ],
      },
      {
        'provider': AIProvider.openai,
        'name': 'OpenAI GPT',
        'configured': EnvironmentConfig.isProviderConfigured(AIProvider.openai),
        'benefits': [
          '🧠 GPT-4 muito inteligente',
          '🎵 Whisper para áudio',
          '🔊 Text-to-Speech',
          '📚 Bem documentado',
          '🌐 Amplamente usado',
        ],
        'models': [
          'gpt-3.5-turbo (Rápido e barato)',
          'gpt-4 (Mais inteligente)',
          'gpt-4-turbo (Contexto maior)',
        ],
      },
      {
        'provider': AIProvider.claude,
        'name': 'Anthropic Claude',
        'configured': EnvironmentConfig.isProviderConfigured(AIProvider.claude),
        'benefits': [
          '📖 Contexto muito grande (200k tokens)',
          '🎭 Conversas mais naturais',
          '🛡️ Muito seguro',
          '📝 Excelente para texto',
          '🎯 Focado em helpfulness',
        ],
        'models': [
          'claude-3-haiku (Rápido)',
          'claude-3-sonnet (Balanceado)',
          'claude-3-opus (Mais inteligente)',
        ],
      },
      {
        'provider': AIProvider.mock,
        'name': 'Mock (Simulação)',
        'configured': true,
        'benefits': [
          '🆓 Totalmente gratuito',
          '⚡ Instantâneo',
          '🔧 Perfeito para desenvolvimento',
          '🎯 Sem limites de uso',
          '📱 Funciona offline',
        ],
        'models': ['Respostas pré-definidas'],
      },
    ];
  }
}
