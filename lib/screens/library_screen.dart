import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import 'catalog_screens.dart';
import '../widgets/common.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const PageHeading(
          eyebrow: 'BUILD YOUR LIBRARY',
          title: 'Manage',
          subtitle: 'Exercises and metrics used by your plans.',
        ),
        _LibraryLink(
          title: 'Exercises',
          description: 'Create and configure movements',
          count: controller.exercises.length,
          icon: Icons.fitness_center_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ExerciseListScreen(controller: controller),
            ),
          ),
        ),
        const Hairline(),
        _LibraryLink(
          title: 'Metrics',
          description: 'Units and measurement types',
          count: controller.metrics.length,
          icon: Icons.straighten_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => MetricListScreen(controller: controller),
            ),
          ),
        ),
        const Hairline(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 25, 22, 0),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('ONE METRIC PER EXERCISE', color: AppColors.accent),
                SizedBox(height: 8),
                Text(
                  'Choose the primary value you want to track for each movement. Reps are recorded separately in every set.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _LibraryLink extends StatelessWidget {
  const _LibraryLink({
    required this.title,
    required this.description,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 21),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('$count', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    ),
  );
}
