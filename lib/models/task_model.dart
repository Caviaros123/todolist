import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high, urgent }

enum DueDateStatus { none, overdue, today, thisWeek, upcoming, completed }

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Nouveaux champs pour équipes
  final String? assignedToUserId;
  final String? assignedToUserName;
  final String? assignedToUserEmail;
  final String? teamId;
  final String? teamName;

  // Nouveaux champs pour dates d'échéance
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool hasReminder;
  final List<String> tags;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.assignedToUserId,
    this.assignedToUserName,
    this.assignedToUserEmail,
    this.teamId,
    this.teamName,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.hasReminder = false,
    this.tags = const [],
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
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'assignedToUserId': assignedToUserId,
      'assignedToUserName': assignedToUserName,
      'assignedToUserEmail': assignedToUserEmail,
      'teamId': teamId,
      'teamName': teamName,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.name,
      'hasReminder': hasReminder,
      'tags': tags,
    };
  }

  factory TaskModel.fromMap(Object? obj, String id) {
    final map = obj as Map<String, dynamic>;

    DateTime? parseOptionalTimestamp(dynamic value) {
      if (value == null) return null;
      try {
        return (value as Timestamp).toDate();
      } catch (e) {
        return null;
      }
    }

    DateTime parseRequiredTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return (value as Timestamp).toDate();
      } catch (e) {
        return DateTime.now();
      }
    }

    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: parseRequiredTimestamp(map['createdAt']),
      completedAt: parseOptionalTimestamp(map['completedAt']),
      assignedToUserId: map['assignedToUserId'],
      assignedToUserName: map['assignedToUserName'],
      assignedToUserEmail: map['assignedToUserEmail'],
      teamId: map['teamId'],
      teamName: map['teamName'],
      dueDate: parseOptionalTimestamp(map['dueDate']),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      hasReminder: map['hasReminder'] ?? false,
      tags:
          (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
    );
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? assignedToUserId,
    String? assignedToUserName,
    String? assignedToUserEmail,
    String? teamId,
    String? teamName,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? hasReminder,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      assignedToUserEmail: assignedToUserEmail ?? this.assignedToUserEmail,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      hasReminder: hasReminder ?? this.hasReminder,
      tags: tags ?? this.tags,
    );
  }
}
