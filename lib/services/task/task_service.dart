import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:todo_list/models/task_model.dart';

class TaskService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference _taskRef = FirebaseFirestore.instance.collection(
    'tasks',
  );

  Future<void> addTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final taskData = task.toMap();
    taskData['userId'] = uid;
    await _taskRef.add(taskData);

    if (kDebugMode) {
      print('Task added: ${task.title}');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }

    final taskData = task.toMap();
    taskData['userId'] = uid;
    await _taskRef.doc(task.id).update(taskData);

    if (kDebugMode) {
      print('Task updated: ${task.id}');
    }
  }

  Future<void> deleteTask(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _taskRef.doc(id).delete();

    if (kDebugMode) {
      print('Task deleted: $id');
    }
  }

  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _taskRef.doc(id).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Stream<List<TaskModel>> getTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'];
                if (ts == null) {
                  data['createdAt'] = Timestamp.now();
                }
                return TaskModel.fromMap(data, doc.id);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing task ${doc.id}: $e');
                }
                rethrow;
              }
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  Stream<List<TaskModel>> getAssignedTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('assignedToUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading assigned tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  Stream<List<TaskModel>> getTeamTasks(String teamId) {
    return _taskRef
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading team tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  // Assigner/réassigner une tâche
  Future<void> assignTask(
    String taskId,
    String userId,
    String userName,
    String userEmail,
  ) async {
    await _taskRef.doc(taskId).update({
      'assignedToUserId': userId,
      'assignedToUserName': userName,
      'assignedToUserEmail': userEmail,
    });

    if (kDebugMode) {
      print('Task assigned: $taskId -> $userName');
    }
  }

  // Retirer l'assignation d'une tâche
  Future<void> unassignTask(String taskId) async {
    await _taskRef.doc(taskId).update({
      'assignedToUserId': null,
      'assignedToUserName': null,
      'assignedToUserEmail': null,
    });

    if (kDebugMode) {
      print('Task unassigned: $taskId');
    }
  }

  // Basculer le statut complété
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _taskRef.doc(taskId).update({
      'isCompleted': !isCompleted,
      'completedAt': !isCompleted ? Timestamp.now() : null,
    });

    if (kDebugMode) {
      print('Task completion toggled: $taskId');
    }
  }

  Stream<List<TaskModel>> getTodayTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _taskRef
        .where('userId', isEqualTo: uid)
        .where(
          'dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading today tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  Stream<List<TaskModel>> getOverdueTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .where('isCompleted', isEqualTo: false)
        .where('dueDate', isLessThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading overdue tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  Stream<List<TaskModel>> getTasksByPriority(TaskPriority priority) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .where('priority', isEqualTo: priority.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error loading tasks by priority: $e');
            }
            return <TaskModel>[];
          }
        });
  }

  Stream<List<TaskModel>> searchTasks(String query) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) => TaskModel.fromMap(d.data(), d.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('Error searching tasks: $e');
            }
            return <TaskModel>[];
          }
        });
  }
}
