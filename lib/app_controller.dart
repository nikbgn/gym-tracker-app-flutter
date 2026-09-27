import 'package:flutter/foundation.dart';

import 'data/workout_database.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController._(this._database);

  final WorkoutDatabase _database;
  List<Metric> metrics = const [];
  List<Exercise> exercises = const [];
  List<WorkoutTemplate> templates = const [];
  List<WorkoutSession> sessions = const [];

  static Future<AppController> create() async {
    final controller = AppController._(await WorkoutDatabase.open());
    await controller.reload(notify: false);
    return controller;
  }

  Map<String, Metric> get metricsById => {
    for (final metric in metrics) metric.id: metric,
  };
  Map<String, Exercise> get exercisesById => {
    for (final exercise in exercises) exercise.id: exercise,
  };

  Future<void> reload({bool notify = true}) async {
    metrics = await _database.getMetrics();
    exercises = await _database.getExercises();
    templates = await _database.getTemplates();
    sessions = await _database.getSessions();
    if (notify) notifyListeners();
  }

  Future<void> saveMetric({
    String? id,
    required String name,
    required String unit,
  }) async {
    await _database.saveMetric(
      Metric(id: id ?? newId('metric'), name: name.trim(), unit: unit.trim()),
    );
    await reload();
  }

  Future<void> removeMetric(String id) async {
    await _database.deleteMetric(id);
    await reload();
  }

  Future<void> saveExercise({
    String? id,
    required String name,
    required String metricId,
  }) async {
    await _database.saveExercise(
      Exercise(
        id: id ?? newId('exercise'),
        name: name.trim(),
        metricId: metricId,
      ),
    );
    await reload();
  }

  Future<void> removeExercise(String id) async {
    await _database.deleteExercise(id);
    await reload();
  }

  Future<void> saveTemplate({
    String? id,
    required String name,
    required List<String> exerciseIds,
  }) async {
    await _database.saveTemplate(
      WorkoutTemplate(
        id: id ?? newId('template'),
        name: name.trim(),
        exerciseIds: List.unmodifiable(exerciseIds),
      ),
    );
    await reload();
  }

  Future<void> removeTemplate(String id) async {
    await _database.deleteTemplate(id);
    await reload();
  }

  Future<void> completeWorkout({
    required String templateId,
    required String templateName,
    required List<ExerciseSessionSnapshot> exercises,
  }) async {
    await _database.saveSession(
      WorkoutSession(
        id: newId('session'),
        templateId: templateId,
        templateName: templateName,
        completedAt: DateTime.now(),
        exercises: List.unmodifiable(exercises),
      ),
    );
    await reload();
  }

  DateTime? lastPerformed(String templateId) {
    for (final session in sessions) {
      if (session.templateId == templateId) return session.completedAt;
    }
    return null;
  }
}
