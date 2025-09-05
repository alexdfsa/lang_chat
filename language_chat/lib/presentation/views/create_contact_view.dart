import 'package:flutter/material.dart';
import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';
import 'package:uuid/uuid.dart';

class CreateContactView extends StatefulWidget {
  final ContactSignals contactSignals;
  final VirtualContact? editingContact;

  const CreateContactView({
    super.key,
    required this.contactSignals,
    this.editingContact,
  });

  @override
  State<CreateContactView> createState() => _CreateContactViewState();
}

class _CreateContactViewState extends State<CreateContactView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedNationality = 'Brasil';
  String _selectedLanguage = 'Português';
  String _selectedGender = 'Masculino';
  String _selectedTemperament = 'Amigável';
  int _selectedAge = 25;

  final List<String> _nationalities = [
    'Brasil',
    'Estados Unidos',
    'Reino Unido',
    'Espanha',
    'França',
    'Alemanha',
    'Itália',
    'Japão',
    'China',
    'Coreia do Sul',
  ];

  final List<String> _languages = [
    'Português',
    'Inglês',
    'Espanhol',
    'Francês',
    'Alemão',
    'Italiano',
    'Japonês',
    'Chinês',
    'Coreano',
  ];

  final List<String> _genders = ['Masculino', 'Feminino', 'Outro'];

  final List<String> _temperaments = [
    'Amigável',
    'Paciente',
    'Enérgico',
    'Calmo',
    'Encorajador',
    'Humorado',
    'Sério',
    'Carismático',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingContact != null) {
      _initializeWithContact(widget.editingContact!);
    }
  }

  void _initializeWithContact(VirtualContact contact) {
    _nameController.text = contact.name;
    _descriptionController.text = contact.description;
    _selectedNationality = contact.nationality;
    _selectedLanguage = contact.language;
    _selectedGender = contact.gender;
    _selectedTemperament = contact.temperament;
    _selectedAge = contact.age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingContact != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Contato' : 'Novo Contato'),
        backgroundColor: const Color(0xFF128C7E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveContact,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF128C7E),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Nationality Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedNationality,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: _nationalities.map((nationality) {
                  return DropdownMenuItem(
                    value: nationality,
                    child: Text(nationality),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedNationality = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Language Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Idioma',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                items: _languages.map((language) {
                  return DropdownMenuItem(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Age and Gender Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Idade: $_selectedAge anos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: _selectedAge.toDouble(),
                          min: 18,
                          max: 80,
                          divisions: 62,
                          activeColor: const Color(0xFF128C7E),
                          onChanged: (value) {
                            setState(() {
                              _selectedAge = value.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gênero',
                        border: OutlineInputBorder(),
                      ),
                      items: _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Temperament Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedTemperament,
                decoration: const InputDecoration(
                  labelText: 'Temperamento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                ),
                items: _temperaments.map((temperament) {
                  return DropdownMenuItem(
                    value: temperament,
                    child: Text(temperament),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTemperament = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição/Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText:
                      'Conte um pouco sobre a personalidade deste contato...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleção de imagem será implementada')),
    );
  }

  void _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final contact = VirtualContact(
      id: widget.editingContact?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      nationality: _selectedNationality,
      language: _selectedLanguage,
      age: _selectedAge,
      gender: _selectedGender,
      temperament: _selectedTemperament,
      profileImage:
          widget.editingContact?.profileImage ?? 'assets/default_avatar.png',
      description: _descriptionController.text.trim(),
      createdAt: widget.editingContact?.createdAt ?? DateTime.now(),
      isOnline: true,
    );

    try {
      if (widget.editingContact != null) {
        await widget.contactSignals.updateContact(contact);
      } else {
        await widget.contactSignals.createContact(contact);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingContact != null
                  ? 'Contato atualizado com sucesso!'
                  : 'Contato criado com sucesso!',
            ),
            backgroundColor: const Color(0xFF128C7E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar contato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
