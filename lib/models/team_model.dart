import 'package:cloud_firestore/cloud_firestore.dart';

enum TeamRole {
  admin,   // Peut tout faire
  member,  // Peut créer/modifier/supprimer ses tâches
  viewer,  // Lecture seule
}

class TeamMember {
  final String userId;
  final String email;
  final String? displayName;
  final TeamRole role;
  final DateTime joinedAt;

  TeamMember({
    required this.userId,
    required this.email,
    this.displayName,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      role: TeamRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => TeamRole.member,
      ),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  TeamMember copyWith({
    String? userId,
    String? email,
    String? displayName,
    TeamRole? role,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class TeamModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final List<TeamMember> members;
  final DateTime createdAt;
  final String? description;
  final String? avatarUrl;

  TeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.members,
    required this.createdAt,
    this.description,
    this.avatarUrl,
  });

  List<String> get memberIds => members.map((m) => m.userId).toList();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'members': members.map((m) => m.toMap()).toList(),
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'avatarUrl': avatarUrl,
    };
  }

  factory TeamModel.fromMap(Object? obj, String id) {
    final map = obj as Map<String, dynamic>;
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      members: (map['members'] as List<dynamic>?)
              ?.map((m) => TeamMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      description: map['description'],
      avatarUrl: map['avatarUrl'],
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? ownerName,
    List<TeamMember>? members,
    DateTime? createdAt,
    String? description,
    String? avatarUrl,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Obtenir le rôle d'un membre
  TeamRole? getMemberRole(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId).role;
    } catch (e) {
      return null;
    }
  }

  // Vérifier si un utilisateur est admin
  bool isAdmin(String userId) {
    return getMemberRole(userId) == TeamRole.admin;
  }

  // Vérifier si un utilisateur est membre
  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }
}

