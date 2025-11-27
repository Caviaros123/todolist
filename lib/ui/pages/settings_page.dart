import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/storage/local_storage_service.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localStorage = context.read<LocalStorageService>();
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Apparence', Icons.palette_rounded, theme),
          Card(
            child: Column(
              children: [
                _themeSelector(localStorage, theme),
                const Divider(height: 1),
                _showCompletedToggle(localStorage),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Tâches par défaut', Icons.task_rounded, theme),
          Card(
            child: Column(
              children: [
                _prioritySelector(localStorage),
                const Divider(height: 1),
                _reminderTimeSelector(localStorage),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Notifications', Icons.notifications_rounded, theme),
          Card(child: _notificationsToggle(localStorage)),
          const SizedBox(height: 24),
          _sectionHeader('Données', Icons.storage_rounded, theme),
          Card(
            child: Column(
              children: [
                _cacheInfo(localStorage),
                const Divider(height: 1),
                _clearCacheButton(localStorage),
                const Divider(height: 1),
                _clearSearchHistoryButton(localStorage),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Compte', Icons.person_rounded, theme),
          Card(
            child: Column(
              children: [
                _userInfo(authService),
                const Divider(height: 1),
                _signOutButton(authService),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _aboutSection(theme),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _themeSelector(LocalStorageService localStorage, ThemeData theme) {
    final mode = localStorage.getThemeMode();
    return ListTile(
      leading: Icon(
        mode == ThemeMode.light
            ? Icons.light_mode_rounded
            : mode == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : Icons.brightness_auto_rounded,
      ),
      title: const Text('Thème'),
      subtitle: Text(_themeLabel(mode)),
      trailing: DropdownButton<ThemeMode>(
        value: mode,
        items: [
          DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
          DropdownMenuItem(value: ThemeMode.system, child: Text('Auto')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
        ],
        onChanged: (value) async {
          if (value != null) {
            await localStorage.saveThemeMode(value);
            setState(() {});
          }
        },
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  Widget _showCompletedToggle(LocalStorageService localStorage) {
    final val = localStorage.getJson('show_completed_tasks') ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.check_circle_rounded),
      title: const Text('Afficher les tâches terminées'),
      value: val,
      onChanged: (v) async {
        await localStorage.saveJson('show_completed_tasks', v);
        setState(() {});
      },
    );
  }

  Widget _prioritySelector(LocalStorageService localStorage) {
    final p = localStorage.getDefaultPriority();
    return ListTile(
      leading: const Icon(Icons.flag_rounded),
      title: const Text('Priorité'),
      subtitle: Text(_priorityLabel(p)),
      trailing: DropdownButton<TaskPriority>(
        value: p,
        items: TaskPriority.values
            .map(
              (tp) =>
                  DropdownMenuItem(value: tp, child: Text(_priorityLabel(tp))),
            )
            .toList(),
        onChanged: (v) async {
          if (v != null) {
            await localStorage.saveDefaultPriority(v);
            setState(() {});
          }
        },
      ),
    );
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Basse';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Haute';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  Widget _reminderTimeSelector(LocalStorageService localStorage) {
    final t = localStorage.getDefaultReminderTime();
    return ListTile(
      leading: const Icon(Icons.alarm_rounded),
      title: const Text('Heure de rappel'),
      subtitle: Text(
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () async {
        final newT = await showTimePicker(context: context, initialTime: t);
        if (newT != null) {
          await localStorage.saveDefaultReminderTime(newT);
          setState(() {});
        }
      },
    );
  }

  Widget _notificationsToggle(LocalStorageService localStorage) {
    final enabled = localStorage.getNotificationsEnabled();
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_rounded),
      title: const Text('Notifications'),
      value: enabled,
      onChanged: (v) async {
        await localStorage.saveNotificationsEnabled(v);
        setState(() {});
      },
    );
  }

  Widget _cacheInfo(LocalStorageService localStorage) {
    final lastSync = localStorage.getLastSyncTimestamp();
    return ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: const Text('Cache local'),
      subtitle: Text(
        lastSync != null
            ? 'Dernière synchro: ${_date(lastSync)}'
            : 'Aucune donnée en cache',
      ),
      trailing: Text(
        '${localStorage.getStorageSize()} clés',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _date(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  Widget _clearCacheButton(LocalStorageService localStorage) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services_rounded),
      title: const Text('Effacer le cache'),
      onTap: () async {
        await localStorage.clearCache();
        setState(() {});
      },
    );
  }

  Widget _clearSearchHistoryButton(LocalStorageService localStorage) {
    final count = localStorage.getSearchHistory().length;
    return ListTile(
      leading: const Icon(Icons.history_rounded),
      title: const Text('Effacer historique recherche'),
      subtitle: Text('$count'),
      enabled: count > 0,
      onTap: count > 0
          ? () async {
              await localStorage.clearSearchHistory();
              setState(() {});
            }
          : null,
    );
  }

  Widget _userInfo(AuthService authService) {
    final user = authService.currentUser;
    return ListTile(
      leading: const Icon(Icons.person_rounded),
      title: Text(user?.displayName ?? 'Utilisateur'),
      subtitle: Text(user?.email ?? ''),
    );
  }

  Widget _signOutButton(AuthService authService) {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Colors.red),
      title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
      onTap: () async {
        await authService.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      },
    );
  }

  Widget _aboutSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text("Todo List - Version 2.0.0"),
      ),
    );
  }
}
