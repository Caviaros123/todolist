import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/theme/app_theme.dart';

class DueDateBadge extends StatelessWidget {
  final TaskModel task;
  final bool showIcon;

  const DueDateBadge({
    super.key,
    required this.task,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (task.dueDate == null) return const SizedBox.shrink();

    final status = task.dueDateStatus;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final text = _formatDueDate(task.dueDate!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(DueDateStatus status) {
    return AppTheme.statusColors[status.name] ?? Colors.grey;
  }

  IconData _getStatusIcon(DueDateStatus status) {
    switch (status) {
      case DueDateStatus.overdue:
        return Icons.warning_rounded;
      case DueDateStatus.today:
        return Icons.today_rounded;
      case DueDateStatus.thisWeek:
        return Icons.date_range_rounded;
      case DueDateStatus.upcoming:
        return Icons.event_rounded;
      case DueDateStatus.completed:
        return Icons.check_circle_rounded;
      case DueDateStatus.none:
        return Icons.event_available_rounded;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);

    final difference = dueDay.difference(today).inDays;

    if (difference < 0) {
      return 'En retard de ${-difference}j';
    } else if (difference == 0) {
      return 'Aujourd\'hui ${DateFormat('HH:mm').format(date)}';
    } else if (difference == 1) {
      return 'Demain ${DateFormat('HH:mm').format(date)}';
    } else if (difference < 7) {
      return 'Dans ${difference}j';
    } else {
      return DateFormat('dd/MM HH:mm').format(date);
    }
  }
}

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(priority);
    final text = _getPriorityText(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    return AppTheme.statusColors[priority.name] ?? Colors.grey;
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
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
}

