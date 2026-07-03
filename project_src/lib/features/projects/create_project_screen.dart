import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers.dart';
import '../../models/project.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetWordsController = TextEditingController();
  final _dailyTargetController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  RestMode _restMode = RestMode.flexible;
  int _allowedRestDays = 1; // rest days per week
  final List<int> _fixedRestDays = []; // 1 = Mon, 7 = Sun

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetWordsController.dispose();
    _dailyTargetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetWords = int.parse(_targetWordsController.text);
    final dailyTarget = int.parse(_dailyTargetController.text);
    final durationDays = int.parse(_durationController.text);

    // Call service to validate scheduling viability
    final schedulingService = ref.read(schedulingServiceProvider);
    final validationError = schedulingService.validateInputs(
      targetWords: targetWords,
      dailyWordTarget: dailyTarget,
      durationDays: durationDays,
      restMode: _restMode,
      fixedRestWeekdays: _fixedRestDays,
      allowedRestDays: _allowedRestDays,
    );

    if (validationError != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Schedule Plan'),
          content: Text(validationError),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Save project
    final notifier = ref.read(projectsProvider.notifier);
    final saveError = await notifier.addProject(
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      targetWords: targetWords,
      dailyWordTarget: dailyTarget,
      durationDays: durationDays,
      startDate: _startDate,
      restMode: _restMode,
      fixedRestWeekdays: _fixedRestDays,
      allowedRestDays: _allowedRestDays,
    );

    if (saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveError)),
      );
    } else {
      context.pop(); // Go back to projects screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Information',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          prefixIcon: Icon(Icons.book),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter a project name.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Targets Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Writing Goals & Timeline',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetWordsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Target Words',
                          prefixIcon: Icon(Icons.bar_chart),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter target words.';
                          final val = int.tryParse(value);
                          if (val == null || val <= 0) return 'Must be a positive integer.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dailyTargetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Daily Writing Word Target',
                          prefixIcon: Icon(Icons.mode_edit),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter daily target.';
                          final val = int.tryParse(value);
                          if (val == null || val <= 0) return 'Must be a positive integer.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Plan Duration (days)',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter plan duration.';
                          final val = int.tryParse(value);
                          if (val == null || val <= 0) return 'Must be a positive integer.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        leading: const Icon(Icons.today),
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_startDate)),
                        trailing: TextButton(
                          onPressed: _selectStartDate,
                          child: const Text('Change'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rest Day Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rest Day Mode',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Project Ink forces rest days to avoid burnout. Choose how you want to schedule them.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RestMode>(
                        value: _restMode,
                        decoration: const InputDecoration(
                          labelText: 'Select Rest Mode',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: RestMode.fixed,
                            child: Text('Fixed (Specific days of the week)'),
                          ),
                          DropdownMenuItem(
                            value: RestMode.flexible,
                            child: Text('Flexible (Budget allowed per week)'),
                          ),
                          DropdownMenuItem(
                            value: RestMode.random,
                            child: Text('Random (Distributed by system per week)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _restMode = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_restMode == RestMode.fixed) ...[
                        Text(
                          'Choose Rest Days:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            _RestDayChip(label: 'Mon', dayValue: 1, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Tue', dayValue: 2, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Wed', dayValue: 3, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Thu', dayValue: 4, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Fri', dayValue: 5, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Sat', dayValue: 6, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                            _RestDayChip(label: 'Sun', dayValue: 7, selectedList: _fixedRestDays, onChanged: (v) => setState(() {})),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          initialValue: _allowedRestDays.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Rest Days Allowed Per Week',
                            helperText: _restMode == RestMode.random
                                ? 'The scheduling engine will randomly assign these rest days in your calendar.'
                                : 'You can manually activate up to this many rest days each week.',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required.';
                            final val = int.tryParse(value);
                            if (val == null || val < 0 || val > 6) return 'Must be between 0 and 6 days.';
                            return null;
                          },
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed >= 0 && parsed <= 6) {
                              _allowedRestDays = parsed;
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Create Writing Project'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestDayChip extends StatelessWidget {
  final String label;
  final int dayValue;
  final List<int> selectedList;
  final ValueChanged<bool> onChanged;

  const _RestDayChip({
    required this.label,
    required this.dayValue,
    required this.selectedList,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedList.contains(dayValue);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          selectedList.add(dayValue);
        } else {
          selectedList.remove(dayValue);
        }
        onChanged(selected);
      },
    );
  }
}
