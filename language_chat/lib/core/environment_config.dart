import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:language_chat/core/ai_config.dart';

class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDevelopment = !isProduction;

  // ✅ ÚNICA FONTE: Todas as API keys vêm do .env
  static String getApiKey(String keyName) {
    try {
      final key = dotenv.env[keyName];
      if (key == null || key.isEmpty) {
        print('⚠️ $keyName não encontrada no arquivo .env'); // Debug
        return '';
      }

      // Verificar se ainda tem placeholder
      if (key.contains('SUA_CHAVE') ||
          key.contains('YOUR_') ||
          key.contains('sua-chave')) {
        print(
          '⚠️ $keyName ainda não foi configurada (contém placeholder)',
        ); // Debug
        return '';
      }

      // Verificar formato básico das chaves
      if (keyName == 'OPENAI_API_KEY' && !key.startsWith('sk-')) {
        print(
          '⚠️ $keyName parece ter formato inválido (deve começar com sk-)',
        ); // Debug
        return '';
      }

      if (keyName == 'GROQ_API_KEY' && !key.startsWith('gsk_')) {
        print(
          '⚠️ $keyName parece ter formato inválido (deve começar com gsk_)',
        ); // Debug
        return '';
      }

      if (keyName == 'CLAUDE_API_KEY' && !key.startsWith('sk-ant-')) {
        print(
          '⚠️ $keyName parece ter formato inválido (deve começar com sk-ant-)',
        ); // Debug
        return '';
      }

      print('✅ $keyName carregada do .env'); // Debug
      return key;
    } catch (e) {
      print('❌ Erro ao carregar $keyName: $e'); // Debug
      return '';
    }
  }

  static AIProvider getAIProvider() {
    try {
      // Verificar se deve usar mock no desenvolvimento
      final useMockInDev =
          dotenv.env['USE_MOCK_IN_DEV']?.toLowerCase() == 'true';
      if (isDevelopment && useMockInDev) {
        print('🎭 Usando Mock AI (desenvolvimento)'); // Debug
        return AIProvider.mock;
      }

      // Verificar provider configurado no .env (padrão: groq)
      final providerName =
          dotenv.env['AI_PROVIDER']?.toLowerCase() ?? AIConfig.defaultProvider;

      switch (providerName) {
        case 'openai':
          final hasKey = getApiKey('OPENAI_API_KEY').isNotEmpty;
          return hasKey ? AIProvider.openai : _fallbackProvider();

        case 'claude':
          final hasKey = getApiKey('CLAUDE_API_KEY').isNotEmpty;
          return hasKey ? AIProvider.claude : _fallbackProvider();

        case 'groq':
          final hasKey = getApiKey('GROQ_API_KEY').isNotEmpty;
          return hasKey ? AIProvider.groq : _fallbackProvider();

        case 'mock':
          return AIProvider.mock;

        default:
          print(
            '⚠️ AI_PROVIDER desconhecido: $providerName, tentando Groq',
          ); // Debug
          final hasGroqKey = getApiKey('GROQ_API_KEY').isNotEmpty;
          return hasGroqKey ? AIProvider.groq : _fallbackProvider();
      }
    } catch (e) {
      print('❌ Erro ao determinar AI Provider: $e'); // Debug
      return AIProvider.mock;
    }
  }

  // Tentativa de fallback inteligente
  static AIProvider _fallbackProvider() {
    print('🔍 Tentando encontrar provider alternativo...'); // Debug

    // Tentar Groq primeiro (mais barato)
    if (getApiKey('GROQ_API_KEY').isNotEmpty) {
      print('✅ Usando Groq como fallback'); // Debug
      return AIProvider.groq;
    }

    // Tentar OpenAI
    if (getApiKey('OPENAI_API_KEY').isNotEmpty) {
      print('✅ Usando OpenAI como fallback'); // Debug
      return AIProvider.openai;
    }

    // Tentar Claude
    if (getApiKey('CLAUDE_API_KEY').isNotEmpty) {
      print('✅ Usando Claude como fallback'); // Debug
      return AIProvider.claude;
    }

    // Último recurso: Mock
    print('⚠️ Nenhuma API key encontrada, usando Mock'); // Debug
    return AIProvider.mock;
  }

  // Configurações de modelo (com fallbacks do ai_config.dart)
  static String get groqModel {
    return dotenv.env['GROQ_MODEL'] ?? AIConfig.defaultGroqModel;
  }

  static String get openAIModel {
    return dotenv.env['OPENAI_MODEL'] ?? AIConfig.defaultOpenAIModel;
  }

  static String get claudeModel {
    return dotenv.env['CLAUDE_MODEL'] ?? AIConfig.defaultClaudeModel;
  }

  // Configurações gerais
  static bool get enableDebugLogs {
    return dotenv.env['ENABLE_DEBUG_LOGS']?.toLowerCase() == 'true';
  }

  // Verificações de configuração
  static bool isProviderConfigured(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return getApiKey('OPENAI_API_KEY').isNotEmpty;
      case AIProvider.claude:
        return getApiKey('CLAUDE_API_KEY').isNotEmpty;
      case AIProvider.groq:
        return getApiKey('GROQ_API_KEY').isNotEmpty;
      case AIProvider.mock:
        return true;
    }
  }

  static bool isConfiguredCorrectly() {
    final provider = getAIProvider();
    return isProviderConfigured(provider);
  }

  // Debug melhorado
  static void printConfiguration() {
    final currentProvider = getAIProvider();

    print('🔧 Configuração atual:');
    print('  - Provider: ${currentProvider.name}');
    print('  - Ambiente: ${isDevelopment ? "Desenvolvimento" : "Produção"}');

    // Status de cada provider
    final providers = [
      ('Groq', AIProvider.groq, groqModel),
      ('OpenAI', AIProvider.openai, openAIModel),
      ('Claude', AIProvider.claude, claudeModel),
    ];

    for (final (name, provider, model) in providers) {
      final configured = isProviderConfigured(provider);
      final status = configured ? '✅' : '❌';
      print('  - $name configurado: $status ${configured ? "($model)" : ""}');
    }

    print('  - Debug logs: $enableDebugLogs');
    print('  - Configuração válida: ${isConfiguredCorrectly()}');

    // Mostrar benefícios do provider atual
    if (currentProvider == AIProvider.groq) {
      print('🦙 Usando Groq + Llama 3:');
      print('  ⚡ Velocidade: Até 10x mais rápido');
      print('  💰 Custo: Muito mais barato');
      print('  🔓 Open-source: Modelo Llama 3');
      print('  🎯 Qualidade: Compete com GPT-4');
    }
  }

  // Informações do modelo atual
  static Map<String, dynamic> getCurrentModelInfo() {
    final provider = getAIProvider();

    switch (provider) {
      case AIProvider.groq:
        return {
          'provider': 'Groq',
          'model': groqModel,
          'speed': 'Muito Rápida (até 500 tokens/s)',
          'cost': 'Muito Baixo',
          'context': '8k tokens',
          'source': 'Open-source (Llama 3)',
        };
      case AIProvider.openai:
        return {
          'provider': 'OpenAI',
          'model': openAIModel,
          'speed': 'Moderada (40 tokens/s)',
          'cost': 'Médio-Alto',
          'context': '4k-16k tokens',
          'source': 'Proprietário',
        };
      case AIProvider.claude:
        return {
          'provider': 'Claude',
          'model': claudeModel,
          'speed': 'Moderada (60 tokens/s)',
          'cost': 'Alto',
          'context': '200k tokens',
          'source': 'Proprietário',
        };
      case AIProvider.mock:
        return {
          'provider': 'Mock',
          'model': 'Simulação',
          'speed': 'Instantânea',
          'cost': 'Gratuito',
          'context': 'Limitado',
          'source': 'Local',
        };
    }
  }
}
