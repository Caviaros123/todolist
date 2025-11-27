import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DueDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Function(DateTime?) onDateSelected;

  const DueDatePicker({
    super.key,
    this.initialDate,
    this.initialTime,
    required this.onDateSelected,
  });

  @override
  State<DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, 
                size: 20, 
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Date d\'échéance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Date Display
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDate != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: _selectedDate != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Sélectionner une date'
                            : DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                                .format(_selectedDate!),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _selectedDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_selectedTime != null)
                        Text(
                          _selectedTime!.format(context),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                      });
                      widget.onDateSelected(null);
                    },
                    tooltip: 'Effacer',
                  ),
              ],
            ),
          ),
        ),

        // Quick Actions
        if (_selectedDate != null) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _QuickActionChip(
                  icon: Icons.access_time_rounded,
                  label: 'Définir l\'heure',
                  onTap: _selectTime,
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.wb_twilight_rounded,
                  label: '9h00',
                  onTap: () => _setTime(9, 0),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.wb_sunny_rounded,
                  label: '12h00',
                  onTap: () => _setTime(12, 0),
                ),
                const SizedBox(width: 8),
                _QuickActionChip(
                  icon: Icons.nights_stay_rounded,
                  label: '18h00',
                  onTap: () => _setTime(18, 0),
                ),
              ],
            ),
          ),
        ],

        // Preset Dates
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _PresetDateChip(
                icon: Icons.today_rounded,
                label: 'Aujourd\'hui',
                onTap: () => _setQuickDate(0),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _PresetDateChip(
                icon: Icons.wb_sunny_outlined,
                label: 'Demain',
                onTap: () => _setQuickDate(1),
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _PresetDateChip(
                icon: Icons.next_week_rounded,
                label: 'Lundi prochain',
                onTap: _setNextMonday,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _PresetDateChip(
                icon: Icons.date_range_rounded,
                label: 'Dans 1 semaine',
                onTap: () => _setQuickDate(7),
                color: Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _notifyDateChange();
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      await _selectDate();
      if (_selectedDate == null) return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _notifyDateChange();
    }
  }

  void _setTime(int hour, int minute) {
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
    _notifyDateChange();
  }

  void _setQuickDate(int daysFromNow) {
    setState(() {
      _selectedDate = DateTime.now().add(Duration(days: daysFromNow));
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    });
    _notifyDateChange();
  }

  void _setNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    
    setState(() {
      _selectedDate = nextMonday;
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    });
    _notifyDateChange();
  }

  void _notifyDateChange() {
    if (_selectedDate == null) {
      widget.onDateSelected(null);
      return;
    }

    DateTime finalDate = _selectedDate!;
    if (_selectedTime != null) {
      finalDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    widget.onDateSelected(finalDate);
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _PresetDateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _PresetDateChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

