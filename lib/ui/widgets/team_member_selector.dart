import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/team_model.dart';
import 'package:todo_list/services/team/team_service.dart';

class TeamMemberSelector extends StatefulWidget {
  final String? initialTeamId;
  final String? initialMemberId;
  final Function(
    String? teamId,
    String? teamName,
    String? memberId,
    String? memberName,
    String? memberEmail,
  )
  onSelectionChanged;

  const TeamMemberSelector({
    super.key,
    this.initialTeamId,
    this.initialMemberId,
    required this.onSelectionChanged,
  });

  @override
  State<TeamMemberSelector> createState() => _TeamMemberSelectorState();
}

class _TeamMemberSelectorState extends State<TeamMemberSelector> {
  String? _selectedTeamId;
  String? _selectedMemberId;
  TeamModel? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.initialTeamId;
    _selectedMemberId = widget.initialMemberId;
  }

  @override
  Widget build(BuildContext context) {
    final teamService = context.read<TeamService>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigner à une équipe (optionnel)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TeamModel>>(
          stream: teamService.getUserTeams(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            final teams = snapshot.data ?? [];

            if (teams.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Créez une équipe pour assigner des tâches',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Équipe',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.groups_rounded),
                      ),
                      hint: const Text('Sélectionner une équipe'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Aucune équipe (tâche personnelle)'),
                        ),
                        ...teams.map((team) {
                          return DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name),
                          );
                        }),
                      ],
                      onChanged: (value) async {
                        setState(() {
                          _selectedTeamId = value;
                          _selectedMemberId = null;
                          _selectedTeam = null;
                        });

                        if (value != null) {
                          _selectedTeam = teams.firstWhere(
                            (t) => t.id == value,
                          );
                        }

                        widget.onSelectionChanged(
                          _selectedTeamId,
                          _selectedTeam?.name,
                          null,
                          null,
                          null,
                        );
                      },
                    ),
                  ),
                ),
                if (_selectedTeamId != null && _selectedTeam != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedMemberId,
                        decoration: const InputDecoration(
                          labelText: 'Assigner à',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        hint: const Text('Sélectionner un membre'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Toute l\'équipe'),
                          ),
                          ..._selectedTeam!.members.map((member) {
                            return DropdownMenuItem(
                              value: member.userId,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Text(
                                      (member.displayName ?? member.email)[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          member.displayName ?? member.email,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (member.displayName != null)
                                          Text(
                                            member.email,
                                            style: theme.textTheme.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      member.role.name,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMemberId = value;
                          });

                          if (value != null) {
                            final member = _selectedTeam!.members.firstWhere(
                              (m) => m.userId == value,
                            );
                            widget.onSelectionChanged(
                              _selectedTeamId,
                              _selectedTeam?.name,
                              member.userId,
                              member.displayName,
                              member.email,
                            );
                          } else {
                            widget.onSelectionChanged(
                              _selectedTeamId,
                              _selectedTeam?.name,
                              null,
                              null,
                              null,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
