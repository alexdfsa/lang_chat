import 'package:hive/hive.dart';

class HiveCleanupHelper {
  static Future<void> cleanupCorruptedData() async {
    print('🧹 Iniciando limpeza de dados corrompidos do Hive...'); // Debug

    try {
      // Clean contacts
      await _cleanupBox('contacts', 'contatos');

      // Clean conversations
      await _cleanupBox('conversations', 'conversas');

      // Clean messages
      await _cleanupBox('messages', 'mensagens');

      print('✅ Limpeza do Hive concluída'); // Debug
    } catch (e) {
      print('❌ Erro durante limpeza: $e'); // Debug
    }
  }

  static Future<void> _cleanupBox(String boxName, String displayName) async {
    try {
      final box = await Hive.openBox(boxName);
      final keys = box.keys.toList();
      int removedCount = 0;

      for (final key in keys) {
        try {
          final data = box.get(key);
          if (data == null) continue;

          // Try to convert to proper Map
          if (data is Map) {
            Map<String, dynamic>.from(data);
          } else {
            // Invalid data type - remove it
            await box.delete(key);
            removedCount++;
          }
        } catch (e) {
          // Corrupted data - remove it
          await box.delete(key);
          removedCount++;
          print('🗑️ Removido item corrompido: $key'); // Debug
        }
      }

      if (removedCount > 0) {
        print(
          '🧹 $displayName: $removedCount itens corrompidos removidos',
        ); // Debug
      }
    } catch (e) {
      print('❌ Erro ao limpar $displayName: $e'); // Debug
    }
  }

  static Future<void> clearAllData() async {
    print('🗑️ Limpando TODOS os dados do Hive...'); // Debug

    try {
      await Hive.deleteBoxFromDisk('contacts');
      await Hive.deleteBoxFromDisk('conversations');
      await Hive.deleteBoxFromDisk('messages');

      print('✅ Todos os dados do Hive foram limpos'); // Debug
    } catch (e) {
      print('❌ Erro ao limpar dados: $e'); // Debug
    }
  }
}
