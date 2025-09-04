import 'package:hive/hive.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/domain/repositories/contact_repository.dart';

class LocalContactRepository implements ContactRepository {
  static const String _boxName = 'contacts';
  late Box _contactsBox;

  Future<void> init() async {
    _contactsBox = await Hive.openBox(_boxName);
    print('📦 ContactRepository inicializado'); // Debug
  }

  @override
  Future<List<VirtualContact>> getAllContacts() async {
    try {
      final contactMaps = _contactsBox.values.toList();
      print('📱 Carregando ${contactMaps.length} contatos do Hive'); // Debug

      final contacts = <VirtualContact>[];

      for (final contactData in contactMaps) {
        try {
          // Convert to proper Map<String, dynamic>
          final Map<String, dynamic> contactMap = Map<String, dynamic>.from(
            contactData as Map,
          );
          final contact = VirtualContact.fromJson(contactMap);
          contacts.add(contact);
        } catch (e) {
          print('⚠️ Erro ao converter contato: $e'); // Debug
          // Skip invalid contact
          continue;
        }
      }

      print('✅ ${contacts.length} contatos carregados com sucesso'); // Debug
      return contacts;
    } catch (e) {
      print('❌ Erro ao carregar contatos: $e'); // Debug
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<VirtualContact?> getContactById(String id) async {
    try {
      final contactData = _contactsBox.get(id);
      if (contactData == null) return null;

      final Map<String, dynamic> contactMap = Map<String, dynamic>.from(
        contactData as Map,
      );
      return VirtualContact.fromJson(contactMap);
    } catch (e) {
      print('❌ Erro ao buscar contato $id: $e'); // Debug
      return null;
    }
  }

  @override
  Future<VirtualContact> createContact(VirtualContact contact) async {
    try {
      await _contactsBox.put(contact.id, contact.toJson());
      print('✅ Contato ${contact.name} criado'); // Debug
      return contact;
    } catch (e) {
      print('❌ Erro ao criar contato: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<VirtualContact> updateContact(VirtualContact contact) async {
    try {
      await _contactsBox.put(contact.id, contact.toJson());
      print('✅ Contato ${contact.name} atualizado'); // Debug
      return contact;
    } catch (e) {
      print('❌ Erro ao atualizar contato: $e'); // Debug
      rethrow;
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    try {
      await _contactsBox.delete(id);
      print('✅ Contato $id deletado'); // Debug
    } catch (e) {
      print('❌ Erro ao deletar contato: $e'); // Debug
      rethrow;
    }
  }

  @override
  Stream<List<VirtualContact>> watchContacts() {
    return _contactsBox
        .watch()
        .map((_) => getAllContacts())
        .asyncMap((future) => future);
  }
}
