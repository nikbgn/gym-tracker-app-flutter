import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/template_list_tile.dart';
import 'active_workout_screen.dart';
import '../widgets/common.dart';
import 'template_editor_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({
    super.key,
    required this.controller,
    required this.onOpenHistory,
  });

  final AppController controller;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageHeading(
            eyebrow: 'PLAN YOUR TRAINING',
            title: 'Templates',
            subtitle: 'Reusable plans for the workouts you repeat.',
            action: IconButton.filledTonal(
              onPressed: () => _editTemplate(context),
              tooltip: 'Create template',
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.accent,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        if (controller.templates.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.view_list_outlined,
              title: 'No templates yet',
              message: 'Build a reusable workout by choosing exercises and putting them in order.',
              action: SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Create template',
                  icon: Icons.add,
                  onPressed: () => _editTemplate(context),
                ),
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              'SAVED PLANS',
              trailing: Text('${controller.templates.length}'),
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
                onEdit: () => _editTemplate(context, template: template),
                onDelete: () => _deleteTemplate(context, template),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    ),
  );

  Future<void> _editTemplate(
    BuildContext context, {
    WorkoutTemplate? template,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            TemplateEditorScreen(controller: controller, template: template),
      ),
    );
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    WorkoutTemplate template,
  ) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete ${template.name}?',
      message: 'The template will be removed. Completed workout history will be kept.',
    );
    if (!confirmed) return;
    await controller.removeTemplate(template.id);
  }

  Future<void> _startWorkout(
    BuildContext context,
    WorkoutTemplate template,
  ) async {
    final exerciseMap = controller.exercisesById;
    final metricMap = controller.metricsById;
    final snapshots = <ExerciseSessionSnapshot>[];
    for (final id in template.exerciseIds) {
      final exercise = exerciseMap[id];
      final metric = exercise == null ? null : metricMap[exercise.metricId];
      if (exercise != null && metric != null) {
        snapshots.add(
          ExerciseSessionSnapshot(
            name: exercise.name,
            metricName: metric.name,
            metricUnit: metric.unit,
            sets: const [],
          ),
        );
      }
    }
    if (snapshots.isEmpty) {
      showMessage(context, 'Add at least one exercise to this template first.');
      return;
    }
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ActiveWorkoutScreen(
          controller: controller,
          templateId: template.id,
          templateName: template.name,
          exercises: snapshots,
        ),
      ),
    );
    if (completed == true) onOpenHistory();
  }
}
