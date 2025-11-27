import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/pages/settings_page.dart';
import 'package:todo_list/ui/pages/teams_page.dart';
import 'package:todo_list/ui/widgets/app_drawer.dart';

import '../widgets/add_task_sheet.dart';
import '../widgets/task_tile.dart';

class TasksPage extends StatelessWidget {
  static const route = '/tasks';
  final VoidCallback? onThemeToggle;
  const TasksPage({super.key, this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final taskService = context.read<TaskService>();

    return StreamProvider<List<TaskModel>>.value(
      value: taskService.getTasks(),
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes tâches'),
          actions: [
            IconButton(
              icon: const Icon(Icons.groups_rounded),
              tooltip: 'Mes équipes',
              onPressed: () => Navigator.pushNamed(context, TeamsPage.route),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Paramètres',
              onPressed: () => Navigator.pushNamed(context, SettingsPage.route),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: const _TaskList(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => const AddTaskSheet(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle tâche'),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<List<TaskModel>>();
    if (tasks.isEmpty) {
      return const Center(child: Text('Aucune tâche pour le moment'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => TaskTile(task: tasks[i]),
    );
  }
}
