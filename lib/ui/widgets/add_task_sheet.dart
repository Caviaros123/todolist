import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/widgets/team_member_selector.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedTeamId;
  String? _selectedTeamName;
  String? _selectedMemberId;
  String? _selectedMemberName;
  String? _selectedMemberEmail;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onTeamMemberSelected(
    String? teamId,
    String? teamName,
    String? memberId,
    String? memberName,
    String? memberEmail,
  ) {
    setState(() {
      _selectedTeamId = teamId;
      _selectedTeamName = teamName;
      _selectedMemberId = memberId;
      _selectedMemberName = memberName;
      _selectedMemberEmail = memberEmail;
    });
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
            const _SheetHandle(),
            const SizedBox(height: 8),
            Text(
              'Nouvelle tâche',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Acheter du lait',
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
            TeamMemberSelector(onSelectionChanged: _onTeamMemberSelected),
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
                          teamId: _selectedTeamId,
                          teamName: _selectedTeamName,
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
                                  : _selectedTeamId != null
                                  ? 'Tâche ajoutée à l\'équipe'
                                  : 'Tâche ajoutée',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Ajouter'),
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
