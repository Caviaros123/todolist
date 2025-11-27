import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:todo_list/models/team_model.dart';

class TeamService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference _teamsRef =
      FirebaseFirestore.instance.collection('teams');

  // Créer une équipe
  Future<String> createTeam(String name, String? description) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = TeamModel(
      id: '',
      name: name,
      ownerId: user.uid,
      ownerName: user.displayName ?? user.email ?? 'Unknown',
      members: [
        TeamMember(
          userId: user.uid,
          email: user.email!,
          displayName: user.displayName,
          role: TeamRole.admin,
          joinedAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      description: description,
    );

    final doc = await _teamsRef.add(team.toMap());
    
    if (kDebugMode) {
      print('Team created: ${doc.id}');
    }
    
    return doc.id;
  }

  Stream<List<TeamModel>> getUserTeams() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _teamsRef
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .handleError((e) {
          if (kDebugMode) {
            print('Error loading teams: $e');
          }
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Récupérer une équipe par ID
  Future<TeamModel?> getTeam(String teamId) async {
    try {
      final doc = await _teamsRef.doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting team: $e');
      }
      rethrow;
    }
  }

  // Inviter un membre (par email)
  Future<void> inviteMember(
    String teamId,
    String email,
    TeamRole role,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Vérifier que l'utilisateur est admin de l'équipe
    final team = await getTeam(teamId);
    if (team == null) throw Exception('Team not found');

    if (!team.isAdmin(user.uid)) {
      throw Exception('Only admins can invite members');
    }

    // Vérifier si l'utilisateur est déjà membre
    if (team.members.any((m) => m.email == email)) {
      throw Exception('User is already a member');
    }

    final newMember = TeamMember(
      userId: '',
      email: email,
      displayName: null,
      role: role,
      joinedAt: DateTime.now(),
    );

    await _teamsRef.doc(teamId).update({
      'members': FieldValue.arrayUnion([newMember.toMap()]),
      'memberIds': FieldValue.arrayUnion(['']),
    });

    if (kDebugMode) {
      print('Member invited: $email');
    }

    // TODO: Envoyer une notification/email d'invitation via Firebase Messaging
  }

  // Supprimer un membre
  Future<void> removeMember(String teamId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await getTeam(teamId);
    if (team == null) throw Exception('Team not found');

    // Vérifier permissions
    if (!team.isAdmin(user.uid) && user.uid != userId) {
      throw Exception('Insufficient permissions');
    }

    // Ne pas permettre au propriétaire de se retirer
    if (userId == team.ownerId) {
      throw Exception('Owner cannot leave the team');
    }

    final memberToRemove = team.members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => throw Exception('Member not found'),
    );

    await _teamsRef.doc(teamId).update({
      'members': FieldValue.arrayRemove([memberToRemove.toMap()]),
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    if (kDebugMode) {
      print('Member removed: $userId');
    }
  }

  // Mettre à jour le rôle d'un membre
  Future<void> updateMemberRole(
    String teamId,
    String userId,
    TeamRole newRole,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await getTeam(teamId);
    if (team == null) throw Exception('Team not found');

    // Vérifier que l'utilisateur est admin
    if (!team.isAdmin(user.uid)) {
      throw Exception('Only admins can change roles');
    }

    // Ne pas changer le rôle du propriétaire
    if (userId == team.ownerId) {
      throw Exception('Cannot change owner role');
    }

    final updatedMembers = team.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();

    await _teamsRef.doc(teamId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
      'memberIds': updatedMembers.map((m) => m.userId).toList(),
    });

    if (kDebugMode) {
      print('Member role updated: $userId -> ${newRole.name}');
    }
  }

  // Quitter une équipe
  Future<void> leaveTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await removeMember(teamId, user.uid);
  }

  // Mettre à jour les informations de l'équipe
  Future<void> updateTeam(
    String teamId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await getTeam(teamId);
    if (team == null) throw Exception('Team not found');

    // Vérifier que l'utilisateur est admin
    if (!team.isAdmin(user.uid)) {
      throw Exception('Only admins can update team info');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _teamsRef.doc(teamId).update(updates);
      
      if (kDebugMode) {
        print('Team updated: $teamId');
      }
    }
  }

  // Supprimer une équipe (admin seulement)
  Future<void> deleteTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await getTeam(teamId);
    if (team == null) throw Exception('Team not found');

    if (team.ownerId != user.uid) {
      throw Exception('Only the owner can delete the team');
    }

    await _teamsRef.doc(teamId).delete();

    if (kDebugMode) {
      print('Team deleted: $teamId');
    }

    // TODO: Supprimer aussi toutes les tâches associées ?
  }

  // Rechercher des équipes par nom
  Stream<List<TeamModel>> searchTeams(String query) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _teamsRef
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
            .where((team) => team.isMember(user.uid))
            .toList());
  }
}

