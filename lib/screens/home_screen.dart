import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/template_list_tile.dart';
import 'active_workout_screen.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenTemplates,
    required this.onOpenHistory,
  });

  final AppController controller;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeading(
            eyebrow: 'GYM TRACKER',
            title: 'Ready to train?',
            subtitle: 'Choose a plan and pick up where you left off.',
          ),
        ),
        if (controller.templates.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'Your first workout starts here',
              message: 'Create a template from your exercises, then start tracking sets.',
              action: SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Create a template',
                  icon: Icons.add,
                  onPressed: onOpenTemplates,
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              'YOUR WORKOUTS',
              trailing: Text(
                '${controller.templates.length}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: controller.templates.length,
            itemBuilder: (context, index) {
              final template = controller.templates[index];
              return TemplateListTile(
                controller: controller,
                template: template,
                onStart: () => _startWorkout(context, template),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: OutlinedButton.icon(
                onPressed: onOpenTemplates,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Manage templates'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _startWorkout(
    BuildContext context,
    WorkoutTemplate template,
  ) async {
    final exercisesById = controller.exercisesById;
    final metricsById = controller.metricsById;
    final exercises = <ExerciseSessionSnapshot>[];
    for (final id in template.exerciseIds) {
      final exercise = exercisesById[id];
      final metric = exercise == null ? null : metricsById[exercise.metricId];
      if (exercise == null || metric == null) continue;
      exercises.add(
        ExerciseSessionSnapshot(
          name: exercise.name,
          metricName: metric.name,
          metricUnit: metric.unit,
          sets: const [],
        ),
      );
    }
    if (exercises.isEmpty) {
      showMessage(context, 'Add at least one exercise to this template first.');
      return;
    }
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ActiveWorkoutScreen(
          controller: controller,
          templateId: template.id,
          templateName: template.name,
          exercises: exercises,
        ),
      ),
    );
    if (completed == true) onOpenHistory();
  }
}
