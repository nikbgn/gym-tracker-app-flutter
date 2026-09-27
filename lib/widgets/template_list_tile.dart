import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import 'common.dart';

class TemplateListTile extends StatelessWidget {
  const TemplateListTile({
    super.key,
    required this.controller,
    required this.template,
    required this.onStart,
    this.onEdit,
    this.onDelete,
  });

  final AppController controller;
  final WorkoutTemplate template;
  final VoidCallback onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final lastPerformed = controller.lastPerformed(template.id);
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${template.exerciseIds.length} ${template.exerciseIds.length == 1 ? 'exercise' : 'exercises'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Template actions',
                    icon: const Icon(Icons.more_horiz, color: AppColors.muted),
                    onSelected: (action) {
                      if (action == 'edit') onEdit?.call();
                      if (action == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                Text(
                  lastPerformed == null
                      ? 'Not performed yet'
                      : 'Last performed · ${formatShortDate(lastPerformed)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 17, 22, 20),
            child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: template.exerciseIds.isEmpty ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Start workout'),
                style: FilledButton.styleFrom(
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          const Hairline(),
        ],
      ),
    );
  }
}
