import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/motivation_utils.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/pause.dart';
import '../../../shared/models/target_change_log.dart';

class EditProjectPage extends ConsumerStatefulWidget {
  final String projectId;
  const EditProjectPage({super.key, required this.projectId});

  @override
  ConsumerState<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends ConsumerState<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _motivationController;
  late TextEditingController _targetDaysController;

  Project? _project;
  bool _isLoading = true;
  String _selectedCategory = 'Fitness';
  String _selectedMode = 'strict';
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _motivationController = TextEditingController();
    _targetDaysController = TextEditingController();
    _loadProject();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    final id = int.tryParse(widget.projectId);
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final db = ref.read(databaseServiceProvider);
    final project = await db.getProject(id);
    if (project != null && mounted) {
      setState(() {
        _project = project;
        _titleController.text = project.title;
        _motivationController.text = project.motivation;
        _targetDaysController.text = project.targetDays.toString();
        _selectedCategory = project.category;
        _selectedMode = project.trackingMode;
        _reminderEnabled = project.reminderEnabled;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _parsedTargetDays {
    return int.tryParse(_targetDaysController.text) ?? (_project?.targetDays ?? 1);
  }

  DateTime get _calculatedEndDate {
    if (_project == null) return DateTime.now();
    return DurationUtils.calculateEndDate(_project!.startDate, _parsedTargetDays);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _project == null) return;

    final db = ref.read(databaseServiceProvider);
    final newTarget = _parsedTargetDays;
    final oldTarget = _project!.targetDays;

    // Log target revision if target days changed
    if (newTarget != oldTarget) {
      final changeLog = TargetChangeLog()
        ..projectId = _project!.id
        ..oldTarget = oldTarget
        ..newTarget = newTarget
        ..dateChanged = DateTime.now();
      await db.saveTargetChangeLog(changeLog);
    }

    _project!
      ..title = _titleController.text.trim()
      ..category = _selectedCategory
      ..motivation = _motivationController.text.trim()
      ..targetDays = newTarget
      ..endDate = _calculatedEndDate
      ..trackingMode = _selectedMode
      ..reminderEnabled = _reminderEnabled
      ..updatedAt = DateTime.now();

    await db.saveProject(_project!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  Future<void> _togglePause() async {
    if (_project == null) return;
    final db = ref.read(databaseServiceProvider);

    if (_project!.status == 'active') {
      final reasonController = TextEditingController();
      final shouldPause = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pause Goal?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Daily tracking and notifications will be paused until you resume.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'e.g., Vacation, Sick leave',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pause'),
            ),
          ],
        ),
      );

      if (shouldPause == true) {
        final pause = Pause()
          ..projectId = _project!.id
          ..startDate = DateTime.now()
          ..reason = reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null;
        await db.savePause(pause);

        _project!.status = 'paused';
        await db.saveProject(_project!);
        _loadProject();
      }
    } else if (_project!.status == 'paused') {
      // Resume project
      final pauses = await db.getPausesForProject(_project!.id);
      final activePause = pauses.cast<Pause?>().firstWhere(
            (p) => p?.endDate == null,
            orElse: () => null,
          );

      if (activePause != null) {
        activePause.endDate = DateTime.now();
        await db.savePause(activePause);

        // Extend project end date by paused days
        final pausedDays = activePause.endDate!.difference(activePause.startDate).inDays;
        if (pausedDays > 0) {
          _project!.endDate = _project!.endDate.add(Duration(days: pausedDays));
        }
      }

      _project!.status = 'active';
      await db.saveProject(_project!);
      _loadProject();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal resumed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _restartProject() async {
    if (_project == null) return;
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart Goal?'),
        content: const Text(
          'This will reset your completed days to 0 and restart tracking from today. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (shouldRestart == true) {
      final db = ref.read(databaseServiceProvider);
      await db.clearProjectRecords(_project!.id);

      final now = DurationUtils.normalizeDate(DateTime.now());
      _project!
        ..completedDays = 0
        ..status = 'active'
        ..startDate = now
        ..endDate = DurationUtils.calculateEndDate(now, _project!.targetDays)
        ..updatedAt = DateTime.now();

      await db.saveProject(_project!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal restarted from today!'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _archiveProject() async {
    if (_project == null) return;
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Goal?'),
        content: const Text('Archived goals are hidden from daily tracking but preserved in your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (shouldArchive == true) {
      final db = ref.read(databaseServiceProvider);
      _project!.status = 'archived';
      await db.saveProject(_project!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal archived.')),
        );
        context.go('/');
      }
    }
  }

  Future<void> _deleteProject() async {
    if (_project == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text(
          'Are you sure you want to permanently delete this goal? All records, history, and progress will be deleted forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteProject(_project!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal deleted.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Goal')),
        body: const Center(child: Text('Goal not found.')),
      );
    }

    final theme = Theme.of(context);
    final isPaused = _project!.status == 'paused';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status banner if paused
            if (isPaused) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pause_circle_filled_rounded, color: Colors.amber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This goal is currently paused. Daily tracking is on hold.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                prefixIcon: const Icon(Icons.flag_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 20),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(
                  CategoryUtils.getIcon(_selectedCategory),
                  color: CategoryUtils.getColor(_selectedCategory, context),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: MotivationUtils.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(CategoryUtils.getIcon(cat), size: 20, color: CategoryUtils.getColor(cat, context)),
                      const SizedBox(width: 12),
                      Text(cat),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),

            // Motivation
            TextFormField(
              controller: _motivationController,
              decoration: InputDecoration(
                labelText: 'Motivation Message',
                prefixIcon: const Icon(Icons.format_quote_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Target Days
            TextFormField(
              controller: _targetDaysController,
              decoration: InputDecoration(
                labelText: 'Target Days',
                prefixIcon: const Icon(Icons.timelapse_rounded),
                helperText: 'Changing target days will update end date and log the revision.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final p = int.tryParse(v ?? '');
                if (p == null || p <= 0) return 'Enter a valid target';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Calculated End Date Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Calculated End Date:', style: TextStyle(color: Colors.grey)),
                  Text(
                    DurationUtils.formatDate(_calculatedEndDate),
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tracking Mode Switcher
            Text(
              'Accountability Mode',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedMode = 'strict'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'strict'
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedMode == 'strict'
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: _selectedMode == 'strict'
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Strict Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                  'Manual daily check-ins required.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: () => setState(() => _selectedMode = 'trust'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'trust'
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedMode == 'trust'
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: _selectedMode == 'trust'
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Trust Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(
                                  'Auto-completes days for you.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),

            // Project Management Section
            Text(
              'Management & Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  // Pause / Resume
                  ListTile(
                    leading: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: isPaused ? Colors.green : Colors.amber,
                    ),
                    title: Text(isPaused ? 'Resume Goal' : 'Pause Goal'),
                    subtitle: Text(isPaused ? 'Resume daily tracking' : 'Temporarily freeze tracking'),
                    onTap: _togglePause,
                  ),
                  const Divider(height: 1),
                  // Restart
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                    title: const Text('Restart Goal'),
                    subtitle: const Text('Reset progress to Day 0 and start from today'),
                    onTap: _restartProject,
                  ),
                  const Divider(height: 1),
                  // Archive
                  ListTile(
                    leading: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
                    title: const Text('Archive Goal'),
                    subtitle: const Text('Hide from active list without losing history'),
                    onTap: _archiveProject,
                  ),
                  const Divider(height: 1),
                  // Delete
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently erase goal and all tracking history'),
                    onTap: _deleteProject,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
