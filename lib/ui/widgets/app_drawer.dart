import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/ui/pages/settings_page.dart';
import 'package:todo_list/ui/pages/tasks_page.dart';
import 'package:todo_list/ui/pages/teams_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user?.email ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.task_rounded),
                  title: const Text('Mes tâches'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, TasksPage.route);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: const Text('Mes équipes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, TeamsPage.route);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Paramètres'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, SettingsPage.route);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                    'Voulez-vous vraiment vous déconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
