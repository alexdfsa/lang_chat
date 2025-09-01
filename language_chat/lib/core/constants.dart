// lib/core/constants.dart
import 'dart:ui';

class AppConstants {
  static const String appName = 'Language Chat';
  static const String appVersion = '1.0.0';

  // Colors
  static const whatsappGreen = Color(0xFF128C7E);
  static const whatsappLightGreen = Color(0xFF25D366);
  static const whatsappDarkGreen = Color(0xFF075E54);

  // Audio constants
  static const int maxRecordingDuration = 300; // 5 minutes
  static const int minRecordingDuration = 1; // 1 second

  // Message limits
  static const int maxMessageLength = 2000;
  static const int maxMessagesPerConversation = 1000;

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'Português': 'pt',
    'Inglês': 'en',
    'Espanhol': 'es',
    'Francês': 'fr',
    'Alemão': 'de',
    'Italiano': 'it',
    'Japonês': 'ja',
    'Chinês': 'zh',
    'Coreano': 'ko',
  };

  // Contact temperaments
  static const List<String> temperaments = [
    'Amigável',
    'Paciente',
    'Enérgico',
    'Calmo',
    'Encorajador',
    'Humorado',
    'Sério',
    'Carismático',
  ];

  // Genders
  static const List<String> genders = ['Masculino', 'Feminino', 'Outro'];
}
