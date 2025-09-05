class StringHelpers {
  /// Trunca uma string de forma segura, evitando RangeError
  static String safeTruncate(String input, int maxLength) {
    if (input.length <= maxLength) {
      return input;
    }
    return input.substring(0, maxLength);
  }

  /// Faz substring de forma segura, evitando RangeError
  static String safeSubstring(String input, int start, [int? end]) {
    if (start < 0) start = 0;
    if (start >= input.length) return '';

    if (end == null) return input.substring(start);
    if (end > input.length) end = input.length;
    if (end <= start) return '';

    return input.substring(start, end);
  }

  /// Limpa uma string removendo caracteres especiais e limitando tamanho
  static String cleanAndLimit(String input, {int maxLength = 100}) {
    if (input.isEmpty) return input;

    // Remove caracteres de controle e espaços extras
    String cleaned = input
        .replaceAll(
          RegExp(r'[\x00-\x1F\x7F]'),
          '',
        ) // Remove caracteres de controle
        .replaceAll(RegExp(r'\s+'), ' ') // Remove espaços múltiplos
        .trim();

    // Trunca com segurança
    return safeTruncate(cleaned, maxLength);
  }

  /// Extrai preview de mensagem de forma segura
  static String getMessagePreview(String content, {int maxLength = 50}) {
    if (content.isEmpty) return 'Mensagem vazia';

    // Limpa e limita o conteúdo
    String preview = cleanAndLimit(content, maxLength: maxLength);

    // Se foi truncado, adiciona reticências
    if (content.length > maxLength) {
      // Garante que temos espaço para as reticências
      int truncateAt = maxLength - 3;
      if (truncateAt > 0) {
        preview = safeTruncate(preview, truncateAt) + '...';
      }
    }

    return preview;
  }

  /// Verifica se uma string é válida para uso
  static bool isValidString(String? input) {
    return input != null && input.trim().isNotEmpty;
  }

  /// Normaliza uma string para uso em IDs
  static String normalizeForId(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Formata uma duração de forma legível
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Capitaliza a primeira letra de uma string
  static String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  /// Remove acentos de uma string
  static String removeAccents(String input) {
    const accents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const normal = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeÇcIIIIiiiiUUUUuuuuyNn';

    String result = input;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], normal[i]);
    }
    return result;
  }
}

/// Extension methods para String
extension StringExtensions on String {
  /// Trunca de forma segura
  String safeTruncate(int maxLength) =>
      StringHelpers.safeTruncate(this, maxLength);

  /// Substring segura
  String safeSubstring(int start, [int? end]) =>
      StringHelpers.safeSubstring(this, start, end);

  /// Limpa e limita
  String cleanAndLimit({int maxLength = 100}) =>
      StringHelpers.cleanAndLimit(this, maxLength: maxLength);

  /// Preview de mensagem
  String getPreview({int maxLength = 50}) =>
      StringHelpers.getMessagePreview(this, maxLength: maxLength);

  /// Verifica se é válida
  bool get isValid => StringHelpers.isValidString(this);

  /// Normaliza para ID
  String get normalized => StringHelpers.normalizeForId(this);

  /// Capitaliza
  String get capitalized => StringHelpers.capitalize(this);

  /// Remove acentos
  String get withoutAccents => StringHelpers.removeAccents(this);
}
