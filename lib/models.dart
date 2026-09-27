import 'dart:math';

String newId(String prefix) {
  final random = Random.secure().nextInt(1 << 32).toRadixString(16);
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
}

class Metric {
  const Metric({
    required this.id,
    required this.name,
    required this.unit,
    this.isDefault = false,
  });

  static const kilogramsId = 'metric-kilograms';

  final String id;
  final String name;
  final String unit;
  final bool isDefault;

  factory Metric.fromMap(Map<String, Object?> map) => Metric(
    id: map['id']! as String,
    name: map['name']! as String,
    unit: map['unit']! as String,
    isDefault: (map['is_default']! as int) == 1,
  );
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.metricId,
  });

  final String id;
  final String name;
  final String metricId;

  factory Exercise.fromMap(Map<String, Object?> map) => Exercise(
    id: map['id']! as String,
    name: map['name']! as String,
    metricId: map['metric_id']! as String,
  );
}

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exerciseIds,
  });

  final String id;
  final String name;
  final List<String> exerciseIds;

  factory WorkoutTemplate.fromMap(
    Map<String, Object?> map, {
    required List<String> exerciseIds,
  }) => WorkoutTemplate(
    id: map['id']! as String,
    name: map['name']! as String,
    exerciseIds: exerciseIds,
  );
}

class WorkoutSet {
  const WorkoutSet({required this.reps, required this.metricValue});

  final int reps;
  final double metricValue;

  factory WorkoutSet.fromMap(Map<String, Object?> map) => WorkoutSet(
    reps: map['reps']! as int,
    metricValue: (map['metric_value']! as num).toDouble(),
  );
}

/// Exercise and metric names are copied into the session at completion so
/// later edits or deletions cannot rewrite the historical record.
class ExerciseSessionSnapshot {
  const ExerciseSessionSnapshot({
    required this.name,
    required this.metricName,
    required this.metricUnit,
    required this.sets,
  });

  final String name;
  final String metricName;
  final String metricUnit;
  final List<WorkoutSet> sets;
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.completedAt,
    required this.exercises,
  });

  final String id;
  final String templateId;
  final String templateName;
  final DateTime completedAt;
  final List<ExerciseSessionSnapshot> exercises;

  int get setCount =>
      exercises.fold(0, (total, exercise) => total + exercise.sets.length);
}
