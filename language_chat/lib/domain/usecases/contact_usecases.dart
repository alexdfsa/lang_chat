import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/domain/repositories/chat_repository.dart';
import 'package:langchat/domain/repositories/contact_repository.dart';
import 'package:langchat/domain/usecases/base_usecase.dart';

class CreateContactUseCase
    extends BaseUseCase<VirtualContact, CreateContactParams> {
  final ContactRepository repository;

  CreateContactUseCase(this.repository);

  @override
  Future<VirtualContact> call(CreateContactParams params) {
    return repository.createContact(params.contact);
  }
}

class CreateContactParams {
  final VirtualContact contact;
  CreateContactParams(this.contact);
}

class GetAllContactsUseCase
    extends BaseUseCase<List<VirtualContact>, NoParams> {
  final ContactRepository repository;

  GetAllContactsUseCase(this.repository);

  @override
  Future<List<VirtualContact>> call(NoParams params) {
    return repository.getAllContacts();
  }
}

class UpdateContactUseCase
    extends BaseUseCase<VirtualContact, UpdateContactParams> {
  final ContactRepository repository;

  UpdateContactUseCase(this.repository);

  @override
  Future<VirtualContact> call(UpdateContactParams params) {
    return repository.updateContact(params.contact);
  }
}

class UpdateContactParams {
  final VirtualContact contact;
  UpdateContactParams(this.contact);
}

class DeleteContactUseCase extends BaseUseCase<void, DeleteContactParams> {
  final ContactRepository contactRepository;
  final ChatRepository chatRepository;

  DeleteContactUseCase(this.contactRepository, this.chatRepository);

  @override
  Future<void> call(DeleteContactParams params) async {
    // 1. Encontrar a conversa associada ao contato
    final conversation = await chatRepository.getConversationByContactId(
      params.contactId,
    );

    // 2. Se a conversa existir, deletá-la (isso também apaga as mensagens)
    if (conversation != null) {
      await chatRepository.deleteConversation(conversation.id);
    }

    // 3. Deletar o contato
    await contactRepository.deleteContact(params.contactId);
  }
}

class DeleteContactParams {
  final String contactId;
  DeleteContactParams(this.contactId);
}
