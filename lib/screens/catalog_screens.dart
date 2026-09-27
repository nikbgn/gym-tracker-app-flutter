import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../app_theme.dart';
import '../models.dart';
import '../widgets/common.dart';

class ExerciseListScreen extends StatelessWidget {
  const ExerciseListScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exercises')),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.exercises.isEmpty
          ? EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No exercises yet',
              message: 'Create an exercise and choose the one metric you want to track.',
              action: SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Create exercise',
                  icon: Icons.add,
                  onPressed: () => _edit(context),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                PageHeading(
                  eyebrow: 'EXERCISE LIBRARY',
                  title: '${controller.exercises.length} movements',
                  action: IconButton.filledTonal(
                    onPressed: () => _edit(context),
                    tooltip: 'Create exercise',
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                  ),
                ),
                for (final exercise in controller.exercises)
                  _ExerciseListItem(
                    exercise: exercise,
                    metric: controller.metricsById[exercise.metricId],
                    onEdit: () => _edit(context, exercise: exercise),
                    onDelete: () => _delete(context, exercise),
                  ),
              ],
            ),
    ),
  );

  Future<void> _edit(BuildContext context, {Exercise? exercise}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ExerciseEditorScreen(controller: controller, exercise: exercise),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Exercise exercise) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete ${exercise.name}?',
      message: 'It will be removed from workout templates. Completed workout history will be kept.',
    );
    if (!confirmed) return;
    await controller.removeExercise(exercise.id);
  }
}

class _ExerciseListItem extends StatelessWidget {
  const _ExerciseListItem({
    required this.exercise,
    required this.metric,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final Metric? metric;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${metric?.name ?? 'Metric unavailable'} · ${metric?.unit ?? ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        onTap: onEdit,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
      const Hairline(),
    ],
  );
}

class ExerciseEditorScreen extends StatefulWidget {
  const ExerciseEditorScreen({
    super.key,
    required this.controller,
    this.exercise,
  });

  final AppController controller;
  final Exercise? exercise;

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  late final TextEditingController _nameController;
  String? _metricId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    final metrics = widget.controller.metrics;
    _metricId =
        widget.exercise?.metricId ??
        (metrics.isEmpty ? null : metrics.first.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.exercise == null ? 'New exercise' : 'Edit exercise'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      children: [
        const Eyebrow('EXERCISE NAME'),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 48,
          decoration: const InputDecoration(
            hintText: 'e.g. Bench press',
            counterText: '',
          ),
        ),
        const SizedBox(height: 26),
        const Eyebrow('PRIMARY METRIC'),
        const SizedBox(height: 10),
        if (widget.controller.metrics.isEmpty)
          const Text(
            'Add a metric before creating an exercise.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          DropdownButtonFormField<String>(
            value: _metricId,
            decoration: const InputDecoration(
              labelText: 'Track one value per set',
            ),
            items: widget.controller.metrics
                .map(
                  (metric) => DropdownMenuItem(
                    value: metric.id,
                    child: Text('${metric.name} · ${metric.unit}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _metricId = value),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _createMetric,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a metric'),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Reps are recorded independently for every set. This exercise has one primary metric.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ],
    ),
  );

  Future<void> _createMetric() async {
    final before = widget.controller.metrics.map((metric) => metric.id).toSet();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MetricEditorScreen(controller: widget.controller),
      ),
    );
    if (!mounted) return;
    final createdMetrics = widget.controller.metrics
        .where((metric) => !before.contains(metric.id))
        .toList();
    final created = createdMetrics.isEmpty ? null : createdMetrics.first;
    if (created != null) setState(() => _metricId = created.id);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMessage(context, 'Enter an exercise name.');
      return;
    }
    if (_metricId == null) {
      showMessage(context, 'Choose a metric.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveExercise(
        id: widget.exercise?.id,
        name: name,
        metricId: _metricId!,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, 'Could not save exercise: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class MetricListScreen extends StatelessWidget {
  const MetricListScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Metrics')),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PageHeading(
            eyebrow: 'MEASUREMENT TYPES',
            title: '${controller.metrics.length} metrics',
            subtitle: 'Each exercise uses one metric.',
            action: IconButton.filledTonal(
              onPressed: () => _edit(context),
              tooltip: 'Add metric',
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
          for (final metric in controller.metrics)
            _MetricListItem(
              metric: metric,
              onEdit: metric.isDefault
                  ? null
                  : () => _edit(context, metric: metric),
              onDelete: metric.isDefault
                  ? null
                  : () => _delete(context, metric),
            ),
        ],
      ),
    ),
  );

  Future<void> _edit(BuildContext context, {Metric? metric}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            MetricEditorScreen(controller: controller, metric: metric),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Metric metric) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete ${metric.name}?',
      message: 'Metrics used by an exercise cannot be removed. Completed history keeps its original metric label.',
    );
    if (!confirmed) return;
    try {
      await controller.removeMetric(metric.id);
    } on StateError catch (error) {
      if (context.mounted) showMessage(context, error.message.toString());
    }
  }
}

class _MetricListItem extends StatelessWidget {
  const _MetricListItem({required this.metric, this.onEdit, this.onDelete});

  final Metric metric;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                metric.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (metric.isDefault)
              const Eyebrow('DEFAULT', color: AppColors.accent),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Unit · ${metric.unit}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        onTap: onEdit,
        trailing: onEdit == null
            ? const Icon(Icons.lock_outline, color: AppColors.muted, size: 18)
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? onEdit?.call() : onDelete?.call(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
      ),
      const Hairline(),
    ],
  );
}

class MetricEditorScreen extends StatefulWidget {
  const MetricEditorScreen({super.key, required this.controller, this.metric});

  final AppController controller;
  final Metric? metric;

  @override
  State<MetricEditorScreen> createState() => _MetricEditorScreenState();
}

class _MetricEditorScreenState extends State<MetricEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.metric?.name ?? '');
    _unitController = TextEditingController(text: widget.metric?.unit ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.metric == null ? 'New metric' : 'Edit metric'),
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      children: [
        const Eyebrow('METRIC NAME'),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          maxLength: 32,
          decoration: const InputDecoration(
            hintText: 'e.g. Distance',
            counterText: '',
          ),
        ),
        const SizedBox(height: 24),
        const Eyebrow('DISPLAY UNIT'),
        const SizedBox(height: 10),
        TextField(
          controller: _unitController,
          textCapitalization: TextCapitalization.none,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: 'e.g. km, lb, sec',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Values are entered as numbers. Reps are stored separately for each set.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    if (name.isEmpty || unit.isEmpty) {
      showMessage(context, 'Enter both a metric name and its unit.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveMetric(
        id: widget.metric?.id,
        name: name,
        unit: unit,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, 'Could not save metric: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
