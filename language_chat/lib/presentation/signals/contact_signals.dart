import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/domain/usecases/base_usecase.dart';
import 'package:langchat/domain/usecases/contact_usecases.dart';
import 'package:signals/signals.dart';

class ContactSignals {
  final GetAllContactsUseCase _getAllContactsUseCase;
  final CreateContactUseCase _createContactUseCase;
  final UpdateContactUseCase _updateContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;

  ContactSignals({
    required GetAllContactsUseCase getAllContactsUseCase,
    required CreateContactUseCase createContactUseCase,
    required UpdateContactUseCase updateContactUseCase,
    required DeleteContactUseCase deleteContactUseCase,
  }) : _getAllContactsUseCase = getAllContactsUseCase,
       _createContactUseCase = createContactUseCase,
       _updateContactUseCase = updateContactUseCase,
       _deleteContactUseCase = deleteContactUseCase;

  // Signals
  final _contacts = signal<List<VirtualContact>>([]);
  final _isLoading = signal<bool>(false);
  final _error = signal<String?>(null);
  final _selectedContact = signal<VirtualContact?>(null);

  // Getters
  ReadonlySignal<List<VirtualContact>> get contacts => _contacts.readonly();
  ReadonlySignal<bool> get isLoading => _isLoading.readonly();
  ReadonlySignal<String?> get error => _error.readonly();
  ReadonlySignal<VirtualContact?> get selectedContact =>
      _selectedContact.readonly();

  // Computed
  late final availableLanguages = computed(() {
    final languages = <String>{};
    for (final contact in _contacts.value) {
      languages.add(contact.language);
    }
    return languages.toList()..sort();
  });

  late final contactsByLanguage = computed(() {
    final Map<String, List<VirtualContact>> grouped = {};
    for (final contact in _contacts.value) {
      grouped.putIfAbsent(contact.language, () => []).add(contact);
    }
    return grouped;
  });

  // Actions
  Future<void> loadContacts() async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      final contactList = await _getAllContactsUseCase.call(NoParams());
      _contacts.value = contactList;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> createContact(VirtualContact contact) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      final newContact = await _createContactUseCase.call(
        CreateContactParams(contact),
      );
      _contacts.value = [..._contacts.value, newContact];
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateContact(VirtualContact contact) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      final updatedContact = await _updateContactUseCase.call(
        UpdateContactParams(contact),
      );

      final contactIndex = _contacts.value.indexWhere(
        (c) => c.id == contact.id,
      );
      if (contactIndex != -1) {
        final updatedList = List<VirtualContact>.from(_contacts.value);
        updatedList[contactIndex] = updatedContact;
        _contacts.value = updatedList;
      }

      if (_selectedContact.value?.id == contact.id) {
        _selectedContact.value = updatedContact;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteContact(String contactId) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = null;

    try {
      await _deleteContactUseCase.call(DeleteContactParams(contactId));
      _contacts.value = _contacts.value
          .where((c) => c.id != contactId)
          .toList();

      if (_selectedContact.value?.id == contactId) {
        _selectedContact.value = null;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  void selectContact(VirtualContact? contact) {
    _selectedContact.value = contact;
  }

  void clearError() {
    _error.value = null;
  }
}
