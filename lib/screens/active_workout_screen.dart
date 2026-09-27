import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.controller,
    required this.templateId,
    required this.templateName,
    required this.exercises,
  });

  final AppController controller;
  final String templateId;
  final String templateName;
  final List<ExerciseSessionSnapshot> exercises;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final List<_ExerciseDraft> _exerciseDrafts;
  bool _saving = false;
  bool _canLeave = false;
  bool _confirmingExit = false;

  @override
  void initState() {
    super.initState();
    _exerciseDrafts = widget.exercises.map(_ExerciseDraft.new).toList();
  }

  @override
  void dispose() {
    for (final exercise in _exerciseDrafts) {
      for (final draft in exercise.sets) {
        draft.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _canLeave,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmDiscard();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Discard workout',
          onPressed: _confirmDiscard,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.templateName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const Text(
              'ACTIVE WORKOUT',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.1,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.accent,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${widget.exercises.length} EXERCISES  ·  ${_completedSetCount} SETS RECORDED',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < _exerciseDrafts.length; index++)
            SliverToBoxAdapter(
              child: _exerciseSection(index, _exerciseDrafts[index]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: PrimaryButton(
            label: _saving ? 'Saving workout…' : 'Finish workout',
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _finishWorkout,
          ),
        ),
      ),
    ),
  );

  int get _completedSetCount => _exerciseDrafts.fold(
    0,
    (total, exercise) =>
        total + exercise.sets.where((draft) => draft.isComplete).length,
  );

  Widget _exerciseSection(int index, _ExerciseDraft exercise) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Hairline(),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
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
                    exercise.snapshot.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.snapshot.metricName} · ${exercise.snapshot.metricUnit}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${exercise.sets.where((draft) => draft.isComplete).length} SETS',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 17, 6),
        child: Row(
          children: [
            const SizedBox(width: 43, child: Eyebrow('SET')),
            Expanded(child: Eyebrow('VALUE (${exercise.snapshot.metricUnit})')),
            const SizedBox(width: 10),
            const SizedBox(width: 76, child: Eyebrow('REPS')),
            const SizedBox(width: 42),
          ],
        ),
      ),
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++)
        _SetInputRow(
          index: setIndex,
          unit: exercise.snapshot.metricUnit,
          draft: exercise.sets[setIndex],
          onChanged: _onDraftChanged,
          onDelete: () => _deleteSet(exercise, exercise.sets[setIndex]),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addSet(exercise),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add set'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ),
      ),
    ],
  );

  void _addSet(_ExerciseDraft exercise) {
    setState(() => exercise.sets.add(_SetDraft()));
  }

  void _deleteSet(_ExerciseDraft exercise, _SetDraft draft) {
    setState(() => exercise.sets.remove(draft));
    draft.dispose();
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmDiscard() async {
    if (_confirmingExit || _canLeave) return;
    _confirmingExit = true;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard this workout?'),
            content: const Text(
              'Your uncompleted sets will be lost. Only finished workouts are saved to history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep working out'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
    _confirmingExit = false;
    if (!confirmed || !mounted) return;
    setState(() => _canLeave = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _finishWorkout() async {
    final incomplete = _exerciseDrafts
        .expand((exercise) => exercise.sets)
        .where((draft) => !draft.isBlank && !draft.isComplete)
        .length;
    if (incomplete > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish incomplete sets'),
          content: Text(
            '$incomplete set${incomplete == 1 ? '' : 's'} need both a metric value and reps. Complete or delete them to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to workout'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final snapshots = _exerciseDrafts
          .map(
            (exercise) => ExerciseSessionSnapshot(
              name: exercise.snapshot.name,
              metricName: exercise.snapshot.metricName,
              metricUnit: exercise.snapshot.metricUnit,
              sets: exercise.sets
                  .where((draft) => draft.isComplete)
                  .map(
                    (draft) => WorkoutSet(
                      reps: draft.repsValue!,
                      metricValue: draft.metricValue!,
                    ),
                  )
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);
      await widget.controller.completeWorkout(
        templateId: widget.templateId,
        templateName: widget.templateName,
        exercises: snapshots,
      );
      if (!mounted) return;
      setState(() => _canLeave = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) showMessage(context, 'Could not save workout: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExerciseDraft {
  _ExerciseDraft(this.snapshot);

  final ExerciseSessionSnapshot snapshot;
  final List<_SetDraft> sets = [];
}

class _SetDraft {
  final TextEditingController metricController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  double? get metricValue {
    final value = double.tryParse(metricController.text.trim());
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }

  int? get repsValue {
    final value = int.tryParse(repsController.text.trim());
    if (value == null || value < 1) return null;
    return value;
  }

  bool get isBlank =>
      metricController.text.trim().isEmpty &&
      repsController.text.trim().isEmpty;
  bool get isComplete => metricValue != null && repsValue != null;

  void dispose() {
    metricController.dispose();
    repsController.dispose();
  }
}

class _SetInputRow extends StatelessWidget {
  const _SetInputRow({
    required this.index,
    required this.unit,
    required this.draft,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final String unit;
  final _SetDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = draft.isComplete;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 3, 13, 3),
      child: Row(
        children: [
          SizedBox(
            width: 43,
            child: Text(
              '${(index + 1).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: complete ? AppColors.accent : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: draft.metricController,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      RegExp(r'^\d*\.?\d*$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue,
                ),
              ],
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unit,
                suffixStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                filled: true,
                fillColor: complete
                    ? AppColors.accent.withValues(alpha: 0.07)
                    : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: complete
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: complete
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            child: TextField(
              controller: draft.repsController,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                filled: true,
                fillColor: complete
                    ? AppColors.accent.withValues(alpha: 0.07)
                    : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: complete
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: complete
                        ? AppColors.accent.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: IconButton(
              tooltip: 'Delete set',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                complete ? Icons.check_circle_rounded : Icons.close_rounded,
                size: 19,
                color: complete ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
