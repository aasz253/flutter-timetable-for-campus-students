import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/course.dart';
import 'edit_course_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppDatabase _db = AppDatabase.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Mon'),
            Tab(text: 'Tue'),
            Tab(text: 'Wed'),
            Tab(text: 'Thu'),
            Tab(text: 'Fri'),
            Tab(text: 'Sat'),
            Tab(text: 'Sun'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          return _DayView(
            weekday: weekday,
            db: _db,
            onChanged: () => setState(() {}),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EditCourseScreen(),
            ),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final int weekday;
  final AppDatabase db;
  final VoidCallback onChanged;

  const _DayView({
    required this.weekday,
    required this.db,
    required this.onChanged,
  });

  String _weekdayLabel(int weekday) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Course>>(
      future: db.getCoursesForDay(weekday),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return Center(
            child: Text('No classes on ${_weekdayLabel(weekday)} yet'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  course.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${course.startTime} - ${course.endTime}',
                    ),
                    if (course.location.isNotEmpty)
                      Text('Room: ${course.location}'),
                    if (course.lecturer.isNotEmpty)
                      Text('Lecturer: ${course.lecturer}'),
                    if (course.notificationsEnabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active,
                                size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Reminder on'),
                          ],
                        ),
                      ),
                  ],
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditCourseScreen(course: course),
                    ),
                  );
                  onChanged();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete course'),
                        content: const Text(
                            'Are you sure you want to delete this course?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await db.deleteCourse(course.id!);
                      onChanged();
                    }
                  },
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: courses.length,
        );
      },
    );
  }
}

