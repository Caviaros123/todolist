# Guide d'Implémentation des Bonus

## Bonus 1: Gestion d'Équipes & Assignation de Tâches 👥

### 1. Modèles de données

#### Nouveau modèle Team
```dart
// lib/models/team_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final List<TeamMember> members;
  final DateTime createdAt;
  final String? description;

  TeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.members,
    required this.createdAt,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
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
              ?.map((m) => TeamMember.fromMap(m))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      description: map['description'],
    );
  }
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
}

enum TeamRole {
  admin,   // Peut tout faire
  member,  // Peut créer/modifier/supprimer ses tâches
  viewer,  // Lecture seule
}
```

#### Modification du TaskModel existant
```dart
// lib/models/task_model.dart
// Ajouter ces champs:

class TaskModel {
  // ... champs existants ...
  
  // NOUVEAUX CHAMPS
  final String? assignedToUserId;
  final String? assignedToUserName;
  final String? assignedToUserEmail;
  final String? teamId;
  final String? teamName;

  TaskModel({
    // ... paramètres existants ...
    this.assignedToUserId,
    this.assignedToUserName,
    this.assignedToUserEmail,
    this.teamId,
    this.teamName,
  });

  Map<String, dynamic> toMap() {
    return {
      // ... champs existants ...
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'assignedToUserEmail': assignedToUserEmail,
      'teamId': teamId,
      'teamName': teamName,
    };
  }

  factory TaskModel.fromMap(Object? obj, String id) {
    final map = obj as Map<String, dynamic>;
    return TaskModel(
      // ... paramètres existants ...
      assignedToUserId: map['assignedToUserId'],
      assignedToUserName: map['assignedToUserName'],
      assignedToUserEmail: map['assignedToUserEmail'],
      teamId: map['teamId'],
      teamName: map['teamName'],
    );
  }
}
```

### 2. Service Team

```dart
// lib/services/team/team_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return doc.id;
  }

  // Récupérer les équipes de l'utilisateur
  Stream<List<TeamModel>> getUserTeams() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _teamsRef
        .where('members', arrayContains: {'userId': user.uid})
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.data(), doc.id))
            .toList());
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
    final team = await _teamsRef.doc(teamId).get();
    final teamData = TeamModel.fromMap(team.data(), teamId);
    
    final currentUserMember = teamData.members
        .firstWhere((m) => m.userId == user.uid);
    
    if (currentUserMember.role != TeamRole.admin) {
      throw Exception('Only admins can invite members');
    }

    // Ajouter le nouveau membre
    final newMember = TeamMember(
      userId: '', // Sera mis à jour quand l'utilisateur accepte
      email: email,
      displayName: null,
      role: role,
      joinedAt: DateTime.now(),
    );

    await _teamsRef.doc(teamId).update({
      'members': FieldValue.arrayUnion([newMember.toMap()]),
    });

    // TODO: Envoyer une notification/email d'invitation
  }

  // Supprimer un membre
  Future<void> removeMember(String teamId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await _teamsRef.doc(teamId).get();
    final teamData = TeamModel.fromMap(team.data(), teamId);
    
    // Vérifier permissions
    final currentUserMember = teamData.members
        .firstWhere((m) => m.userId == user.uid);
    
    if (currentUserMember.role != TeamRole.admin && 
        currentUserMember.userId != userId) {
      throw Exception('Insufficient permissions');
    }

    final memberToRemove = teamData.members
        .firstWhere((m) => m.userId == userId);

    await _teamsRef.doc(teamId).update({
      'members': FieldValue.arrayRemove([memberToRemove.toMap()]),
    });
  }

  // Mettre à jour le rôle d'un membre
  Future<void> updateMemberRole(
    String teamId,
    String userId,
    TeamRole newRole,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await _teamsRef.doc(teamId).get();
    final teamData = TeamModel.fromMap(team.data(), teamId);
    
    // Vérifier que l'utilisateur est admin
    final currentUserMember = teamData.members
        .firstWhere((m) => m.userId == user.uid);
    
    if (currentUserMember.role != TeamRole.admin) {
      throw Exception('Only admins can change roles');
    }

    // Mettre à jour le rôle
    final updatedMembers = teamData.members.map((m) {
      if (m.userId == userId) {
        return TeamMember(
          userId: m.userId,
          email: m.email,
          displayName: m.displayName,
          role: newRole,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    await _teamsRef.doc(teamId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
  }

  // Quitter une équipe
  Future<void> leaveTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await removeMember(teamId, user.uid);
  }

  // Supprimer une équipe (admin seulement)
  Future<void> deleteTeam(String teamId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = await _teamsRef.doc(teamId).get();
    final teamData = TeamModel.fromMap(team.data(), teamId);
    
    if (teamData.ownerId != user.uid) {
      throw Exception('Only the owner can delete the team');
    }

    await _teamsRef.doc(teamId).delete();
  }
}
```

### 3. Modification du TaskService

```dart
// lib/services/task/task_service.dart
// Ajouter ces méthodes:

// Créer une tâche assignée
Future<void> addTaskWithAssignment({
  required TaskModel task,
  String? teamId,
  String? assignedToUserId,
}) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');

  final taskData = {
    ...task.toMap(),
    'userId': uid,
    'teamId': teamId,
    'assignedToUserId': assignedToUserId,
  };

  await _taskRef.add(taskData);
}

// Récupérer les tâches assignées à l'utilisateur
Stream<List<TaskModel>> getAssignedTasks() {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return _taskRef
      .where('assignedToUserId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => TaskModel.fromMap(d.data(), d.id))
          .toList());
}

// Récupérer les tâches d'une équipe
Stream<List<TaskModel>> getTeamTasks(String teamId) {
  return _taskRef
      .where('teamId', isEqualTo: teamId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => TaskModel.fromMap(d.data(), d.id))
          .toList());
}

// Assigner/réassigner une tâche
Future<void> assignTask(String taskId, String userId, String userName) async {
  await _taskRef.doc(taskId).update({
    'assignedToUserId': userId,
    'assignedToUserName': userName,
  });
}
```

### 4. Interface UI - Page Teams

```dart
// lib/ui/pages/teams_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/team_model.dart';
import 'package:todo_list/services/team/team_service.dart';

class TeamsPage extends StatelessWidget {
  static const String route = '/teams';
  
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final teamService = context.read<TeamService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Équipes'),
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: teamService.getUserTeams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucune équipe'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTeamDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une équipe'),
                  ),
                ],
              ),
            );
          }

          final teams = snapshot.data!;
          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return TeamTile(team: team);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une équipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'équipe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await context.read<TeamService>().createTeam(
                      nameController.text,
                      descController.text.isEmpty 
                          ? null 
                          : descController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class TeamTile extends StatelessWidget {
  final TeamModel team;

  const TeamTile({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(team.name[0].toUpperCase()),
        ),
        title: Text(team.name),
        subtitle: Text('${team.members.length} membres'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailPage(team: team),
            ),
          );
        },
      ),
    );
  }
}

// Page de détail d'équipe (à implémenter)
class TeamDetailPage extends StatelessWidget {
  final TeamModel team;

  const TeamDetailPage({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
      ),
      body: Column(
        children: [
          // Liste des membres
          Expanded(
            child: ListView.builder(
              itemCount: team.members.length,
              itemBuilder: (context, index) {
                final member = team.members[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(member.email[0].toUpperCase()),
                  ),
                  title: Text(member.displayName ?? member.email),
                  subtitle: Text(member.role.name),
                  trailing: _buildMemberActions(context, member),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteMemberDialog(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildMemberActions(BuildContext context, TeamMember member) {
    // Implémenter actions (changer rôle, supprimer)
    return PopupMenuButton(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'change_role',
          child: Text('Changer le rôle'),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Retirer'),
        ),
      ],
    );
  }

  void _showInviteMemberDialog(BuildContext context) {
    // Implémenter dialogue d'invitation
  }
}
```

---

## Bonus 2: Dates d'Échéance 📅

### 1. Modification du TaskModel

```dart
// lib/models/task_model.dart
// Ajouter ces champs:

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class TaskModel {
  // ... champs existants ...
  
  // NOUVEAUX CHAMPS
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool hasReminder;

  TaskModel({
    // ... paramètres existants ...
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.hasReminder = false,
  });

  // Calculer si la tâche est en retard
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Calculer le statut d'échéance
  DueDateStatus get dueDateStatus {
    if (dueDate == null) return DueDateStatus.none;
    if (isCompleted) return DueDateStatus.completed;
    if (isOverdue) return DueDateStatus.overdue;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (dueDay == today) return DueDateStatus.today;
    if (dueDay.isBefore(today.add(const Duration(days: 7)))) {
      return DueDateStatus.thisWeek;
    }
    return DueDateStatus.upcoming;
  }

  Map<String, dynamic> toMap() {
    return {
      // ... champs existants ...
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.name,
      'hasReminder': hasReminder,
    };
  }

  factory TaskModel.fromMap(Object? obj, String id) {
    final map = obj as Map<String, dynamic>;
    return TaskModel(
      // ... paramètres existants ...
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      hasReminder: map['hasReminder'] ?? false,
    );
  }
}

enum DueDateStatus {
  none,
  overdue,
  today,
  thisWeek,
  upcoming,
  completed,
}
```

### 2. Widget de sélection de date

```dart
// lib/ui/widgets/due_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DueDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Function(DateTime?) onDateSelected;

  const DueDatePicker({
    super.key,
    this.initialDate,
    this.initialTime,
    required this.onDateSelected,
  });

  @override
  State<DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            _selectedDate == null
                ? 'Ajouter une échéance'
                : 'Échéance: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
          ),
          subtitle: _selectedTime != null
              ? Text('Heure: ${_selectedTime!.format(context)}')
              : null,
          trailing: _selectedDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                    widget.onDateSelected(null);
                  },
                )
              : null,
          onTap: _selectDate,
        ),
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.access_time),
                  label: const Text('Définir l\'heure'),
                  onPressed: _selectTime,
                ),
                ActionChip(
                  avatar: const Icon(Icons.today),
                  label: const Text('Aujourd\'hui'),
                  onPressed: () => _setQuickDate(0),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tomorrow),
                  label: const Text('Demain'),
                  onPressed: () => _setQuickDate(1),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range),
                  label: const Text('Dans 1 semaine'),
                  onPressed: () => _setQuickDate(7),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _notifyDateChange();
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      await _selectDate();
      if (_selectedDate == null) return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _notifyDateChange();
    }
  }

  void _setQuickDate(int daysFromNow) {
    setState(() {
      _selectedDate = DateTime.now().add(Duration(days: daysFromNow));
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    });
    _notifyDateChange();
  }

  void _notifyDateChange() {
    if (_selectedDate == null) {
      widget.onDateSelected(null);
      return;
    }

    DateTime finalDate = _selectedDate!;
    if (_selectedTime != null) {
      finalDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    widget.onDateSelected(finalDate);
  }
}
```

### 3. Badge de statut d'échéance

```dart
// lib/ui/widgets/due_date_badge.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/models/task_model.dart';

class DueDateBadge extends StatelessWidget {
  final TaskModel task;

  const DueDateBadge({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    if (task.dueDate == null) return const SizedBox.shrink();

    final status = task.dueDateStatus;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(task.dueDate!),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DueDateStatus status) {
    switch (status) {
      case DueDateStatus.overdue:
        return Colors.red;
      case DueDateStatus.today:
        return Colors.orange;
      case DueDateStatus.thisWeek:
        return Colors.amber;
      case DueDateStatus.upcoming:
        return Colors.green;
      case DueDateStatus.completed:
        return Colors.grey;
      case DueDateStatus.none:
        return Colors.transparent;
    }
  }

  IconData _getStatusIcon(DueDateStatus status) {
    switch (status) {
      case DueDateStatus.overdue:
        return Icons.warning;
      case DueDateStatus.today:
        return Icons.today;
      case DueDateStatus.thisWeek:
        return Icons.date_range;
      case DueDateStatus.upcoming:
        return Icons.event;
      case DueDateStatus.completed:
        return Icons.check_circle;
      case DueDateStatus.none:
        return Icons.event_available;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    
    final difference = dueDay.difference(today).inDays;

    if (difference < 0) {
      return 'En retard de ${-difference}j';
    } else if (difference == 0) {
      return 'Aujourd\'hui ${DateFormat('HH:mm').format(date)}';
    } else if (difference == 1) {
      return 'Demain ${DateFormat('HH:mm').format(date)}';
    } else if (difference < 7) {
      return 'Dans ${difference}j';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
```

### 4. Vue Calendrier

```dart
// lib/ui/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // À ajouter dans pubspec
import 'package:provider/provider.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/models/task_model.dart';

class CalendarPage extends StatefulWidget {
  static const String route = '/calendar';

  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des échéances'),
      ),
      body: Column(
        children: [
          StreamBuilder<List<TaskModel>>(
            stream: context.read<TaskService>().getTasks(),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final events = _getEventsForDays(tasks);

              return TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => events[_normalizeDate(day)] ?? [],
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildTasksList(),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<TaskModel>> _getEventsForDays(List<TaskModel> tasks) {
    final Map<DateTime, List<TaskModel>> events = {};
    
    for (final task in tasks) {
      if (task.dueDate != null) {
        final date = _normalizeDate(task.dueDate!);
        events[date] = [...(events[date] ?? []), task];
      }
    }
    
    return events;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildTasksList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Sélectionnez une date'),
      );
    }

    return StreamBuilder<List<TaskModel>>(
      stream: context.read<TaskService>().getTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasksForDay = snapshot.data!
            .where((task) => 
                task.dueDate != null &&
                isSameDay(task.dueDate, _selectedDay))
            .toList();

        if (tasksForDay.isEmpty) {
          return const Center(
            child: Text('Aucune tâche pour ce jour'),
          );
        }

        return ListView.builder(
          itemCount: tasksForDay.length,
          itemBuilder: (context, index) {
            final task = tasksForDay[index];
            return TaskTile(task: task); // Utiliser votre TaskTile existant
          },
        );
      },
    );
  }
}
```

### 5. Service de notifications (rappels)

```dart
// lib/services/notification/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_list/models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  // Planifier un rappel pour une tâche
  static Future<void> scheduleTaskReminder(TaskModel task) async {
    if (task.dueDate == null || !task.hasReminder) return;

    // Rappel 24h avant
    final reminder24h = task.dueDate!.subtract(const Duration(hours: 24));
    if (reminder24h.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        task.id.hashCode,
        'Rappel: Tâche à échéance demain',
        task.title,
        tz.TZDateTime.from(reminder24h, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Rappels de tâches',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Rappel 1h avant
    final reminder1h = task.dueDate!.subtract(const Duration(hours: 1));
    if (reminder1h.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        task.id.hashCode + 1,
        'Rappel: Tâche à échéance dans 1h',
        task.title,
        tz.TZDateTime.from(reminder1h, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Rappels de tâches',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Annuler les rappels d'une tâche
  static Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
    await _notifications.cancel(taskId.hashCode + 1);
  }
}
```

---

## Prochaines étapes

1. **Ajouter les packages nécessaires dans `pubspec.yaml`:**
```yaml
dependencies:
  table_calendar: ^3.0.9
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2
```

2. **Configurer les permissions:**
   - Android: Ajouter dans `AndroidManifest.xml`
   - iOS: Ajouter dans `Info.plist`

3. **Implémenter les règles Firestore:**
```javascript
// Pour les équipes
match /teams/{teamId} {
  allow read: if request.auth.uid in resource.data.members;
  allow write: if request.auth.uid == resource.data.ownerId;
}
```

4. **Tester les fonctionnalités:**
   - Création d'équipes
   - Invitation de membres
   - Assignation de tâches
   - Sélection de dates
   - Notifications de rappels

---

Bon courage pour l'implémentation des bonus ! 🚀

