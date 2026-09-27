import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Workout record')),
    body: ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        PageHeading(
          eyebrow: formatDate(session.completedAt).toUpperCase(),
          title: session.templateName,
          subtitle:
              '${session.exercises.length} exercises · ${session.setCount} sets',
        ),
        for (
          var exerciseIndex = 0;
          exerciseIndex < session.exercises.length;
          exerciseIndex++
        )
          _HistoricalExercise(
            index: exerciseIndex,
            exercise: session.exercises[exerciseIndex],
          ),
      ],
    ),
  );
}

class _HistoricalExercise extends StatelessWidget {
  const _HistoricalExercise({required this.index, required this.exercise});

  final int index;
  final ExerciseSessionSnapshot exercise;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(index + 1).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.metricName} · ${exercise.metricUnit}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (exercise.sets.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(56, 0, 22, 16),
          child: Text(
            'No sets recorded',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        )
      else
        for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++)
          _HistoricalSetRow(
            index: setIndex,
            set: exercise.sets[setIndex],
            unit: exercise.metricUnit,
          ),
      const Hairline(),
    ],
  );
}

class _HistoricalSetRow extends StatelessWidget {
  const _HistoricalSetRow({
    required this.index,
    required this.set,
    required this.unit,
  });

  final int index;
  final WorkoutSet set;
  final String unit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(56, 9, 22, 9),
    child: Row(
      children: [
        Text(
          'SET ${(index + 1).toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        Text(
          '${formatMetricValue(set.metricValue)} $unit',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 20),
        Text(
          '${set.reps} reps',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
