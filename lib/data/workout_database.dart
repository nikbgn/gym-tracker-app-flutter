import 'package:sqflite/sqflite.dart';

import '../models.dart';

class WorkoutDatabase {
  WorkoutDatabase._(this._database);

  final Database _database;

  static Future<WorkoutDatabase> open() async {
    final root = await getDatabasesPath();
    final database = await openDatabase(
      '$root/gym_tracker.db',
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
    );
    return WorkoutDatabase._(database);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE metrics (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        metric_id TEXT NOT NULL,
        FOREIGN KEY (metric_id) REFERENCES metrics(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE template_exercises (
        template_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (template_id, exercise_id),
        FOREIGN KEY (template_id) REFERENCES templates(id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        template_name TEXT NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE session_exercises (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        metric_name TEXT NOT NULL,
        metric_unit TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_sets (
        id TEXT PRIMARY KEY,
        session_exercise_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        reps INTEGER NOT NULL CHECK (reps > 0),
        metric_value REAL NOT NULL CHECK (metric_value >= 0),
        FOREIGN KEY (session_exercise_id) REFERENCES session_exercises(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sessions_template_date ON workout_sessions(template_id, completed_at DESC)',
    );
    await db.insert('metrics', {
      'id': Metric.kilogramsId,
      'name': 'Kilograms',
      'unit': 'kg',
      'is_default': 1,
    });
  }

  Future<List<Metric>> getMetrics() async {
    final rows = await _database.query(
      'metrics',
      orderBy: 'is_default DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Metric.fromMap).toList();
  }

  Future<List<Exercise>> getExercises() async {
    final rows = await _database.query(
      'exercises',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<WorkoutTemplate>> getTemplates() async {
    final rows = await _database.query(
      'templates',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final templates = <WorkoutTemplate>[];
    for (final row in rows) {
      final exerciseRows = await _database.query(
        'template_exercises',
        columns: ['exercise_id'],
        where: 'template_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      templates.add(
        WorkoutTemplate.fromMap(
          row,
          exerciseIds: exerciseRows
              .map((item) => item['exercise_id']! as String)
              .toList(),
        ),
      );
    }
    return templates;
  }

  Future<List<WorkoutSession>> getSessions() async {
    final rows = await _database.query(
      'workout_sessions',
      orderBy: 'completed_at DESC',
    );
    final sessions = <WorkoutSession>[];
    for (final row in rows) {
      final exerciseRows = await _database.query(
        'session_exercises',
        where: 'session_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      final exercises = <ExerciseSessionSnapshot>[];
      for (final exerciseRow in exerciseRows) {
        final setRows = await _database.query(
          'workout_sets',
          where: 'session_exercise_id = ?',
          whereArgs: [exerciseRow['id']],
          orderBy: 'position ASC',
        );
        exercises.add(
          ExerciseSessionSnapshot(
            name: exerciseRow['exercise_name']! as String,
            metricName: exerciseRow['metric_name']! as String,
            metricUnit: exerciseRow['metric_unit']! as String,
            sets: setRows.map(WorkoutSet.fromMap).toList(),
          ),
        );
      }
      sessions.add(
        WorkoutSession(
          id: row['id']! as String,
          templateId: row['template_id']! as String,
          templateName: row['template_name']! as String,
          completedAt: DateTime.parse(row['completed_at']! as String).toLocal(),
          exercises: exercises,
        ),
      );
    }
    return sessions;
  }

  Future<void> saveMetric(Metric metric) async {
    final values = {
      'id': metric.id,
      'name': metric.name,
      'unit': metric.unit,
      'is_default': metric.isDefault ? 1 : 0,
    };
    final updated = await _database.update(
      'metrics',
      values,
      where: 'id = ?',
      whereArgs: [metric.id],
    );
    if (updated == 0) await _database.insert('metrics', values);
  }

  Future<void> deleteMetric(String id) async {
    if (id == Metric.kilogramsId) {
      throw StateError('The default kilograms metric cannot be removed.');
    }
    final uses = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM exercises WHERE metric_id = ?',
        [id],
      ),
    );
    if ((uses ?? 0) > 0) {
      throw StateError(
        'This metric is used by an exercise. Change that exercise first.',
      );
    }
    await _database.delete('metrics', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveExercise(Exercise exercise) async {
    final values = {
      'id': exercise.id,
      'name': exercise.name,
      'metric_id': exercise.metricId,
    };
    final updated = await _database.update(
      'exercises',
      values,
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
    if (updated == 0) await _database.insert('exercises', values);
  }

  Future<void> deleteExercise(String id) async {
    await _database.transaction((txn) async {
      await txn.delete(
        'template_exercises',
        where: 'exercise_id = ?',
        whereArgs: [id],
      );
      await txn.delete('exercises', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _database.transaction((txn) async {
      final values = {'id': template.id, 'name': template.name};
      final updated = await txn.update(
        'templates',
        values,
        where: 'id = ?',
        whereArgs: [template.id],
      );
      if (updated == 0) await txn.insert('templates', values);
      await txn.delete(
        'template_exercises',
        where: 'template_id = ?',
        whereArgs: [template.id],
      );
      for (
        var position = 0;
        position < template.exerciseIds.length;
        position++
      ) {
        await txn.insert('template_exercises', {
          'template_id': template.id,
          'exercise_id': template.exerciseIds[position],
          'position': position,
        });
      }
    });
  }

  Future<void> deleteTemplate(String id) async {
    // Sessions deliberately have no foreign key to templates: deleting a
    // reusable template must never delete or rewrite completed history.
    await _database.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _database.transaction((txn) async {
      await txn.insert('workout_sessions', {
        'id': session.id,
        'template_id': session.templateId,
        'template_name': session.templateName,
        'completed_at': session.completedAt.toUtc().toIso8601String(),
      });
      for (var position = 0; position < session.exercises.length; position++) {
        final exercise = session.exercises[position];
        final exerciseId = newId('session-exercise');
        await txn.insert('session_exercises', {
          'id': exerciseId,
          'session_id': session.id,
          'position': position,
          'exercise_name': exercise.name,
          'metric_name': exercise.metricName,
          'metric_unit': exercise.metricUnit,
        });
        for (
          var setPosition = 0;
          setPosition < exercise.sets.length;
          setPosition++
        ) {
          final set = exercise.sets[setPosition];
          await txn.insert('workout_sets', {
            'id': newId('set'),
            'session_exercise_id': exerciseId,
            'position': setPosition,
            'reps': set.reps,
            'metric_value': set.metricValue,
          });
        }
      }
    });
  }
}
