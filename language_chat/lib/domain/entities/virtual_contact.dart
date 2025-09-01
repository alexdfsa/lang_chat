class VirtualContact {
  final String id;
  final String name;
  final String nationality;
  final String language;
  final int age;
  final String gender;
  final String temperament;
  final String profileImage;
  final String description;
  final DateTime createdAt;
  final bool isOnline;

  const VirtualContact({
    required this.id,
    required this.name,
    required this.nationality,
    required this.language,
    required this.age,
    required this.gender,
    required this.temperament,
    required this.profileImage,
    required this.description,
    required this.createdAt,
    this.isOnline = true,
  });

  VirtualContact copyWith({
    String? id,
    String? name,
    String? nationality,
    String? language,
    int? age,
    String? gender,
    String? temperament,
    String? profileImage,
    String? description,
    DateTime? createdAt,
    bool? isOnline,
  }) {
    return VirtualContact(
      id: id ?? this.id,
      name: name ?? this.name,
      nationality: nationality ?? this.nationality,
      language: language ?? this.language,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      temperament: temperament ?? this.temperament,
      profileImage: profileImage ?? this.profileImage,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality,
      'language': language,
      'age': age,
      'gender': gender,
      'temperament': temperament,
      'profileImage': profileImage,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory VirtualContact.fromJson(Map<String, dynamic> json) {
    return VirtualContact(
      id: json['id'],
      name: json['name'],
      nationality: json['nationality'],
      language: json['language'],
      age: json['age'],
      gender: json['gender'],
      temperament: json['temperament'],
      profileImage: json['profileImage'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      isOnline: json['isOnline'] ?? true,
    );
  }
}
