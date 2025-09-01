import 'package:hive/hive.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/domain/repositories/contact_repository.dart';

class LocalContactRepository implements ContactRepository {
  static const String _boxName = 'contacts';
  late Box<Map> _contactsBox;

  Future<void> init() async {
    _contactsBox = await Hive.openBox<Map>(_boxName);
  }

  @override
  Future<List<VirtualContact>> getAllContacts() async {
    final contactMaps = _contactsBox.values.toList();
    return contactMaps
        .map((map) => VirtualContact.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  @override
  Future<VirtualContact?> getContactById(String id) async {
    final contactMap = _contactsBox.get(id);
    if (contactMap == null) return null;
    return VirtualContact.fromJson(Map<String, dynamic>.from(contactMap));
  }

  @override
  Future<VirtualContact> createContact(VirtualContact contact) async {
    await _contactsBox.put(contact.id, contact.toJson());
    return contact;
  }

  @override
  Future<VirtualContact> updateContact(VirtualContact contact) async {
    await _contactsBox.put(contact.id, contact.toJson());
    return contact;
  }

  @override
  Future<void> deleteContact(String id) async {
    await _contactsBox.delete(id);
  }

  @override
  Stream<List<VirtualContact>> watchContacts() {
    return _contactsBox
        .watch()
        .map((_) => getAllContacts())
        .asyncMap((future) => future);
  }
}
