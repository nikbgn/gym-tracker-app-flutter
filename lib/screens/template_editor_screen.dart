import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import 'catalog_screens.dart';
import '../widgets/common.dart';

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({
    super.key,
    required this.controller,
    this.template,
  });

  final AppController controller;
  final WorkoutTemplate? template;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late final TextEditingController _nameController;
  late List<String> _exerciseIds;
  bool _saving = false;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _exerciseIds = List.of(widget.template?.exerciseIds ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_isEditing ? 'Edit template' : 'New template'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        children: [
          const Eyebrow('WORKOUT NAME'),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: 'e.g. Push day',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Eyebrow('EXERCISE ORDER')),
              Text(
                '${_exerciseIds.length}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_exerciseIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Choose exercises and set the order you want to perform them in.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            )
          else
            ...List.generate(_exerciseIds.length, _exerciseRow),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _chooseExercises,
            icon: const Icon(Icons.add),
            label: const Text('Add or remove exercises'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _createExercise,
              icon: const Icon(Icons.fitness_center_rounded, size: 17),
              label: const Text('Create an exercise'),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Template edits affect future workouts. Completed sessions keep the exercise names and metrics recorded at the time.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _exerciseRow(int index) {
    final exerciseId = _exerciseIds[index];
    final exercise = widget.controller.exercisesById[exerciseId];
    if (exercise == null) return const SizedBox.shrink();
    final metric = widget.controller.metricsById[exercise.metricId];
    return Container(
      key: ValueKey(exercise.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 7, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  metric == null
                      ? 'Metric unavailable'
                      : '${metric.name} · ${metric.unit}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Move up',
            visualDensity: VisualDensity.compact,
            onPressed: index == 0 ? null : () => _move(index, -1),
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            tooltip: 'Move down',
            visualDensity: VisualDensity.compact,
            onPressed: index == _exerciseIds.length - 1
                ? null
                : () => _move(index, 1),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }

  void _move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _exerciseIds.length) return;
    setState(() {
      final item = _exerciseIds.removeAt(index);
      _exerciseIds.insert(target, item);
    });
  }

  Future<void> _chooseExercises() async {
    if (widget.controller.exercises.isEmpty) return _createExercise();
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _ExercisePickerSheet(
        controller: widget.controller,
        initiallySelected: _exerciseIds,
      ),
    );
    if (selected != null && mounted) setState(() => _exerciseIds = selected);
  }

  Future<void> _createExercise() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ExerciseEditorScreen(controller: widget.controller),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMessage(context, 'Give this template a name.');
      return;
    }
    if (_exerciseIds.isEmpty) {
      showMessage(context, 'Add at least one exercise.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveTemplate(
        id: widget.template?.id,
        name: name,
        exerciseIds: _exerciseIds,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, 'Could not save template: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.controller,
    required this.initiallySelected,
  });

  final AppController controller;
  final List<String> initiallySelected;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final Set<String> _selected = widget.initiallySelected.toSet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose exercises',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _orderedSelection()),
                child: const Text('Done'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.controller.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.controller.exercises[index];
                final metric = widget.controller.metricsById[exercise.metricId];
                return CheckboxListTile(
                  value: _selected.contains(exercise.id),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _selected.add(exercise.id);
                    } else {
                      _selected.remove(exercise.id);
                    }
                  }),
                  activeColor: AppColors.accent,
                  checkColor: AppColors.background,
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${metric?.name ?? 'Metric'} · ${metric?.unit ?? ''}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );

  List<String> _orderedSelection() {
    final ordered = <String>[
      ...widget.initiallySelected.where(_selected.contains),
      ...widget.controller.exercises
          .map((exercise) => exercise.id)
          .where(_selected.contains),
    ];
    return ordered.toSet().toList();
  }
}
