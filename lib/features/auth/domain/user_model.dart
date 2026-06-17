class UserModel {
  final String uid;
  final String phone;
  final String? name;
  final String? photoUrl;
  final List<String> sports;
  final String? preferredLocation;
  final DateTime createdAt;
  final String? about;
  final int? age;
  final String? gender;
  final List<String> starredGameIds;

  const UserModel({
    required this.uid,
    required this.phone,
    this.name,
    this.photoUrl,
    this.sports = const [],
    this.preferredLocation,
    required this.createdAt,
    this.about,
    this.age,
    this.gender,
    this.starredGameIds = const [],
  });

  bool get isProfileComplete => name != null && name!.isNotEmpty;

  String get initials {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    if (parts.length == 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    // 3+ words: first + last initial
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'sports': sports,
      'preferredLocation': preferredLocation,
      'createdAt': createdAt.toIso8601String(),
      'about': about,
      'age': age,
      'gender': gender,
      'starredGameIds': starredGameIds,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'],
      photoUrl: map['photoUrl'],
      sports: List<String>.from(map['sports'] ?? []),
      preferredLocation: map['preferredLocation'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      about: map['about'],
      age: map['age'],
      gender: map['gender'],
      starredGameIds: List<String>.from(map['starredGameIds'] ?? []),
    );
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    List<String>? sports,
    String? preferredLocation,
    String? about,
    int? age,
    String? gender,
    List<String>? starredGameIds,
  }) {
    return UserModel(
      uid: uid,
      phone: phone,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      sports: sports ?? this.sports,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      createdAt: createdAt,
      about: about ?? this.about,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      starredGameIds: starredGameIds ?? this.starredGameIds,
    );
  }
}