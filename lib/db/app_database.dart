import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/course.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'timetable.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE courses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location TEXT,
            lecturer TEXT,
            weekday INTEGER NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            notifications_enabled INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Course>> getCoursesForDay(int weekday) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'weekday = ?',
      whereArgs: [weekday],
      orderBy: 'start_time ASC',
    );
    return maps.map(Course.fromMap).toList();
  }

  Future<int> insertCourse(Course course) async {
    final db = await database;
    return db.insert('courses', course.toMap());
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    return db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

