import 'package:language_chat/domain/entities/virtual_contact.dart';

abstract class ContactRepository {
  Future<List<VirtualContact>> getAllContacts();
  Future<VirtualContact?> getContactById(String id);
  Future<VirtualContact> createContact(VirtualContact contact);
  Future<VirtualContact> updateContact(VirtualContact contact);
  Future<void> deleteContact(String id);
  Stream<List<VirtualContact>> watchContacts();
}
