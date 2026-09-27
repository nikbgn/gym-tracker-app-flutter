import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import 'history_detail_screen.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final groups = <String, List<WorkoutSession>>{};
      for (final session in controller.sessions) {
        groups.putIfAbsent(session.templateId, () => []).add(session);
      }
      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeading(
              eyebrow: 'YOUR TRAINING LOG',
              title: 'History',
              subtitle: 'Completed workouts, saved as they happened.',
            ),
          ),
          if (groups.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.history_rounded,
                title: 'Nothing in history yet',
                message: 'Finish a workout to keep it here for later.',
              ),
            )
          else
            SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, groupIndex) {
                final entry = groups.entries.elementAt(groupIndex);
                final sessions = entry.value;
                return _HistoryGroup(sessions: sessions);
              },
            ),
        ],
      );
    },
  );
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final title = sessions.first.templateName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 19, 22, 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${sessions.length} ${sessions.length == 1 ? 'SESSION' : 'SESSIONS'}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        for (final session in sessions)
          _SessionRow(
            session: session,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => HistoryDetailScreen(session: session),
              ),
            ),
          ),
        const Hairline(),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final WorkoutSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(session.completedAt),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.exercises.length} ${session.exercises.length == 1 ? 'exercise' : 'exercises'}  ·  ${session.setCount} ${session.setCount == 1 ? 'set' : 'sets'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}
