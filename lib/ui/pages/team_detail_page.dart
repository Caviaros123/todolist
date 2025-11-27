import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/models/team_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/team/team_service.dart';
import 'package:todo_list/ui/widgets/task_tile.dart';

class TeamDetailPage extends StatefulWidget {
  final TeamModel team;

  const TeamDetailPage({super.key, required this.team});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = widget.team.isAdmin(currentUserId);
    final isOwner = widget.team.ownerId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => _showTeamSettings(context),
              tooltip: 'Paramètres',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (!isOwner)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app_rounded),
                      SizedBox(width: 12),
                      Text('Quitter l\'équipe'),
                    ],
                  ),
                ),
              if (isOwner)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Supprimer l\'équipe',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'leave') {
                _leaveTeam(context);
              } else if (value == 'delete') {
                _deleteTeam(context);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded), text: 'Membres'),
            Tab(icon: Icon(Icons.task_rounded), text: 'Tâches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMembersTab(), _buildTasksTab()],
      ),
      floatingActionButton: isAdmin
          ? AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isMembersTab = _tabController.index == 0;
                return FloatingActionButton.extended(
                  onPressed: isMembersTab
                      ? () => _showInviteMemberDialog(context)
                      : () => _createTeamTask(),
                  icon: Icon(
                    isMembersTab
                        ? Icons.person_add_rounded
                        : Icons.add_task_rounded,
                  ),
                  label: Text(isMembersTab ? 'Inviter' : 'Nouvelle tâche'),
                );
              },
            )
          : null,
    );
  }

  Widget _buildMembersTab() {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = widget.team.isAdmin(currentUserId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.team.description != null &&
                    widget.team.description!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.team.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.team.members.length} membres',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Members list
        ...widget.team.members.map(
          (member) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (member.displayName ?? member.email)[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(
                member.displayName ?? member.email,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(member.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(member.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getRoleLabel(member.role),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(member.role),
                      ),
                    ),
                  ),
                  if (isAdmin && member.userId != widget.team.ownerId)
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        if (member.role != TeamRole.admin)
                          const PopupMenuItem(
                            value: 'promote',
                            child: Text('Promouvoir admin'),
                          ),
                        if (member.role == TeamRole.admin)
                          const PopupMenuItem(
                            value: 'demote',
                            child: Text('Rétrograder membre'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Retirer de l\'équipe',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'remove') {
                          _removeMember(
                            context,
                            member.userId,
                            member.displayName ?? member.email,
                          );
                        } else if (value == 'promote') {
                          _updateMemberRole(
                            context,
                            member.userId,
                            TeamRole.admin,
                          );
                        } else if (value == 'demote') {
                          _updateMemberRole(
                            context,
                            member.userId,
                            TeamRole.member,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    final taskService = context.read<TaskService>();

    return StreamBuilder<List<TaskModel>>(
      stream: taskService.getTeamTasks(widget.team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune tâche',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez la première tâche\npour cette équipe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => _createTeamTask(),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une tâche'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              '${tasks.length}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Text('Tâches'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              '${tasks.where((t) => t.isCompleted).length}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.green),
                            ),
                            const Text('Terminées'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              '${tasks.where((t) => !t.isCompleted).length}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.orange),
                            ),
                            const Text('En cours'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => TaskTile(task: tasks[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createTeamTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateTeamTaskSheet(team: widget.team),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.admin:
        return Colors.purple;
      case TeamRole.member:
        return Colors.blue;
      case TeamRole.viewer:
        return Colors.grey;
    }
  }

  String _getRoleLabel(TeamRole role) {
    switch (role) {
      case TeamRole.admin:
        return 'Admin';
      case TeamRole.member:
        return 'Membre';
      case TeamRole.viewer:
        return 'Viewer';
    }
  }

  void _showInviteMemberDialog(BuildContext context) {
    final emailController = TextEditingController();
    TeamRole selectedRole = TeamRole.member;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded),
              SizedBox(width: 12),
              Text('Inviter un membre'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text('Rôle', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<TeamRole>(
                  segments: const [
                    ButtonSegment(
                      value: TeamRole.viewer,
                      label: Text('Viewer'),
                      icon: Icon(Icons.visibility_rounded),
                    ),
                    ButtonSegment(
                      value: TeamRole.member,
                      label: Text('Membre'),
                      icon: Icon(Icons.person_rounded),
                    ),
                    ButtonSegment(
                      value: TeamRole.admin,
                      label: Text('Admin'),
                      icon: Icon(Icons.admin_panel_settings_rounded),
                    ),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (Set<TeamRole> selected) {
                    setState(() {
                      selectedRole = selected.first;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    await context.read<TeamService>().inviteMember(
                      widget.team.id,
                      emailController.text.trim(),
                      selectedRole,
                    );
                    Navigator.pop(dialogContext);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invitation envoyée'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Modifier les informations'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter l'édition
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Changer l\'avatar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implémenter le changement d'avatar
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeMember(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer un membre'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer $userName de l\'équipe ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<TeamService>().removeMember(
                  widget.team.id,
                  userId,
                );
                Navigator.pop(dialogContext);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$userName retiré de l\'équipe'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _updateMemberRole(
    BuildContext context,
    String userId,
    TeamRole newRole,
  ) async {
    try {
      await context.read<TeamService>().updateMemberRole(
        widget.team.id,
        userId,
        newRole,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôle mis à jour'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _leaveTeam(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter l\'équipe'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette équipe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<TeamService>().leaveTeam(widget.team.id);
                Navigator.pop(dialogContext);
                Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vous avez quitté l\'équipe'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _deleteTeam(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'équipe'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette équipe ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<TeamService>().deleteTeam(widget.team.id);
                Navigator.pop(dialogContext);
                Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Équipe supprimée'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _CreateTeamTaskSheet extends StatefulWidget {
  final TeamModel team;

  const _CreateTeamTaskSheet({required this.team});

  @override
  State<_CreateTeamTaskSheet> createState() => _CreateTeamTaskSheetState();
}

class _CreateTeamTaskSheetState extends State<_CreateTeamTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedMemberId;
  String? _selectedMemberName;
  String? _selectedMemberEmail;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nouvelle tâche - ${widget.team.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Préparer la réunion',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Détails (optionnel)',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigner à un membre',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMemberId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_rounded),
                        hintText: 'Sélectionner un membre',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Toute l\'équipe'),
                        ),
                        ...widget.team.members.map((member) {
                          return DropdownMenuItem(
                            value: member.userId,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Text(
                                    (member.displayName ?? member.email)[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    member.displayName ?? member.email,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMemberId = value;
                          if (value != null) {
                            final member = widget.team.members.firstWhere(
                              (m) => m.userId == value,
                            );
                            _selectedMemberName = member.displayName;
                            _selectedMemberEmail = member.email;
                          } else {
                            _selectedMemberName = null;
                            _selectedMemberEmail = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (_titleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Le titre est requis')),
                        );
                        return;
                      }

                      final service = context.read<TaskService>();
                      await service.addTask(
                        TaskModel(
                          id: '',
                          userId: '',
                          title: _titleCtrl.text.trim(),
                          description: _descCtrl.text.trim(),
                          isCompleted: false,
                          createdAt: DateTime.now(),
                          teamId: widget.team.id,
                          teamName: widget.team.name,
                          assignedToUserId: _selectedMemberId,
                          assignedToUserName: _selectedMemberName,
                          assignedToUserEmail: _selectedMemberEmail,
                        ),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedMemberId != null
                                  ? 'Tâche assignée à ${_selectedMemberName ?? _selectedMemberEmail}'
                                  : 'Tâche créée pour l\'équipe',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Créer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
