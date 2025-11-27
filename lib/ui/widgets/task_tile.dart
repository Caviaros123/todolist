import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: SizedBox(
          width: 40,
          height: 40,
          child: InkWell(
            onTap: () => _toggle(context),
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              child: Icon(
                task.isCompleted ? Icons.check : Icons.circle_outlined,
              ),
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            // Show creation date
            Row(
              children: [
                const Icon(Icons.schedule, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Created: ${DateFormat.yMMMEd().add_Hm().format(task.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            // Show completion date if available
            if (task.completedAt != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Completed: ${DateFormat.yMMMEd().add_Hm().format(task.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (task.teamId != null || task.assignedToUserId != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (task.teamId != null)
                    Chip(
                      avatar: const Icon(Icons.groups_rounded, size: 16),
                      label: Text(task.teamName ?? 'Équipe'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (task.assignedToUserId != null)
                    Chip(
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: theme.primaryContainer,
                        child: Text(
                          (task.assignedToUserName ??
                                  task.assignedToUserEmail ??
                                  'U')[0]
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      label: Text(
                        task.assignedToUserName ??
                            task.assignedToUserEmail ??
                            'Membre',
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ],
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _edit(context);
            if (v == 'delete') _delete(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
        tileColor: task.isCompleted
            ? theme.surfaceContainerHighest.withOpacity(.6)
            : null,
      ),
    );
  }

  void _toggle(BuildContext context) {
    final service = context.read<TaskService>();
    service.updateTask(
      task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      ),
    );
  }

  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
    await service.deleteTask(task.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tâche supprimée')));
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditTaskSheet(task: task),
    );
  }
}

class _EditTaskSheet extends StatelessWidget {
  final TaskModel task;
  const _EditTaskSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),
          Text(
            'Modifier la tâche',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Titre'),
            controller: titleCtrl,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Description'),
            controller: descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
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
                    final service = context.read<TaskService>();
                    await service.updateTask(
                      task.copyWith(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
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
