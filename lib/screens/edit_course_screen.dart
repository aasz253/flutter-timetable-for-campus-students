import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/course.dart';
import '../services/notification_service.dart';

class EditCourseScreen extends StatefulWidget {
  final Course? course;

  const EditCourseScreen({super.key, this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _lecturerCtrl = TextEditingController();

  int _weekday = 1;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _notificationsEnabled = false;

  final AppDatabase _db = AppDatabase.instance;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    if (c != null) {
      _nameCtrl.text = c.name;
      _locationCtrl.text = c.location;
      _lecturerCtrl.text = c.lecturer;
      _weekday = c.weekday;
      _start = _parseTime(c.startTime);
      _end = _parseTime(c.endTime);
      _notificationsEnabled = c.notificationsEnabled;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _lecturerCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({
    required bool isStart,
  }) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final course = Course(
      id: widget.course?.id,
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      lecturer: _lecturerCtrl.text.trim(),
      weekday: _weekday,
      startTime: _formatTime(_start),
      endTime: _formatTime(_end),
      notificationsEnabled: _notificationsEnabled,
    );

    if (course.id == null) {
      final id = await _db.insertCourse(course);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleNotification(
          id: id,
          title: 'Upcoming class: ${course.name}',
          body:
              'Starts at ${course.startTime} in ${course.location.isEmpty ? 'classroom' : course.location}',
          time: _start,
          weekday: _weekday,
        );
      }
    } else {
      await _db.updateCourse(course);
      if (_notificationsEnabled) {
        await NotificationService.instance.scheduleNotification(
          id: course.id!,
          title: 'Upcoming class: ${course.name}',
          body:
              'Starts at ${course.startTime} in ${course.location.isEmpty ? 'classroom' : course.location}',
          time: _start,
          weekday: _weekday,
        );
      } else {
        await NotificationService.instance.cancelNotification(course.id!);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit course' : 'Add course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Course name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lecturerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lecturer (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weekday,
                      decoration: const InputDecoration(
                        labelText: 'Day of week',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _weekday = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: true),
                      child: Text('Start: ${_formatTime(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: false),
                      child: Text('End: ${_formatTime(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _notificationsEnabled,
                title: const Text('Notification before class'),
                subtitle: const Text('Get a reminder before class starts'),
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Add course'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

