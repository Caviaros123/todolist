import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:todo_list/models/task_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late final GetStorage _box;
  bool _initialized = false;

  static const String _keyThemeMode = 'theme_mode';

  Future<void> init() async {
    if (_initialized) return;
    await GetStorage.init();
    _box = GetStorage();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _box.write(_keyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final themeName = _box.read(_keyThemeMode);
    if (themeName == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
  }

  dynamic getJson(String key) {
    return _box.read(key);
  }

  Future<void> saveJson(String key, dynamic value) async {
    await _box.write(key, value);
  }

  Future<void> saveDefaultPriority(TaskPriority priority) async {
    await _box.write('default_priority', priority.name);
  }

  TaskPriority getDefaultPriority() {
    final val = _box.read('default_priority');
    if (val == null) return TaskPriority.medium;
    try {
      return TaskPriority.values.firstWhere((e) => e.name == val);
    } catch (_) {
      return TaskPriority.medium;
    }
  }

  Future<void> saveDefaultReminderTime(TimeOfDay time) async {
    await _box.write('reminder_time', {
      'hour': time.hour,
      'minute': time.minute,
    });
  }

  TimeOfDay getDefaultReminderTime() {
    final data = _box.read('reminder_time');
    if (data == null) return const TimeOfDay(hour: 9, minute: 0);
    return TimeOfDay(hour: data['hour'] ?? 9, minute: data['minute'] ?? 0);
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _box.write('notifications_enabled', enabled);
  }

  bool getNotificationsEnabled() {
    return _box.read('notifications_enabled') ?? true;
  }

  DateTime? getLastSyncTimestamp() {
    final ts = _box.read('last_sync_timestamp');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  int getStorageSize() {
    return _box.getKeys().length;
  }

  Future<void> clearCache() async {
    await _box.remove('cached_tasks');
    await _box.remove('cached_teams');
    await _box.remove('last_sync_timestamp');
  }

  List<String> getSearchHistory() {
    final history = _box.read('search_history');
    if (history == null) return [];
    return List<String>.from(history);
  }

  Future<void> clearSearchHistory() async {
    await _box.remove('search_history');
  }
}
