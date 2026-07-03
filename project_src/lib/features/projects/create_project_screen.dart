import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

import '../../shared/providers.dart';
import '../../models/project.dart';
import 'widgets/book_cover_widget.dart';

enum DurationType { days, weeks, months, customRange }

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
  final _qtyController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DurationType _durationType = DurationType.days;
  
  RestMode _restMode = RestMode.flexible;
  int _allowedRestDays = 1; // rest days per week
  final List<int> _fixedRestDays = []; // 1 = Mon, 7 = Sun

  // Book Cover State
  String? _coverType;
  String? _coverImagePath;

  @override
  void initState() {
    super.initState();
    _qtyController.text = '30'; // default duration in days
    
    // Assign a random default cover initially
    final random = Random();
    final chosen = defaultCovers[random.nextInt(defaultCovers.length)];
    _coverType = 'default';
    _coverImagePath = chosen.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetWordsController.dispose();
    _dailyTargetController.dispose();
    _qtyController.dispose();
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
        // Reset custom range end date if it precedes start date
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
      initialDateRange: _endDate != null
          ? DateTimeRange(start: _startDate, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _pickCustomCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final pickedPath = result.files.single.path!;
        final appDir = await getApplicationDocumentsDirectory();
        
        // Generate unique filename preserving extension
        final extensionName = p.extension(pickedPath);
        final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}$extensionName';
        final savedFile = await File(pickedPath).copy('${appDir.path}/$fileName');
        
        setState(() {
          _coverType = 'uploaded';
          _coverImagePath = savedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  void _rollRandomCover() {
    final random = Random();
    final chosen = defaultCovers[random.nextInt(defaultCovers.length)];
    setState(() {
      _coverType = 'default';
      _coverImagePath = chosen.id;
    });
  }

  void _removeCover() {
    setState(() {
      _coverType = null;
      _coverImagePath = null;
    });
  }

  int _calculateTotalDays() {
    if (_durationType == DurationType.customRange) {
      if (_endDate == null) return 0;
      final cleanStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final cleanEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      return cleanEnd.difference(cleanStart).inDays + 1;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (_durationType == DurationType.weeks) return qty * 7;
    if (_durationType == DurationType.months) return qty * 30;
    return qty; // days
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetWords = int.parse(_targetWordsController.text);
    final dailyTarget = int.parse(_dailyTargetController.text);
    final durationDays = _calculateTotalDays();

    if (durationDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid duration/date range.')),
      );
      return;
    }

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
      coverImagePath: _coverImagePath,
      coverType: _coverType,
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
    final calculatedDays = _calculateTotalDays();

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
              // Cover Picker Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Book Cover Preview
                      BookCoverWidget(
                        title: _nameController.text.isNotEmpty ? _nameController.text : 'Manuscript Title',
                        coverImagePath: _coverImagePath,
                        coverType: _coverType,
                        width: 90,
                        height: 120,
                        borderRadius: 8.0,
                        showTitle: true,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Cover',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _pickCustomCover,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Upload Cover'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _rollRandomCover,
                                  icon: const Icon(Icons.casino),
                                  label: const Text('Roll'),
                                ),
                                if (_coverType != null) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _removeCover,
                                    child: const Text('Reset', style: TextStyle(color: Colors.red)),
                                  )
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        onChanged: (_) => setState(() {}),
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
                      const SizedBox(height: 16),
                      
                      // Flexible Duration Picker Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<DurationType>(
                              value: _durationType,
                              decoration: const InputDecoration(
                                labelText: 'Duration Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: DurationType.days, child: Text('Days')),
                                DropdownMenuItem(value: DurationType.weeks, child: Text('Weeks')),
                                DropdownMenuItem(value: DurationType.months, child: Text('Months')),
                                DropdownMenuItem(value: DurationType.customRange, child: Text('Custom Range')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _durationType = val;
                                    // Reset values depending on selections
                                    if (val == DurationType.days) _qtyController.text = '30';
                                    if (val == DurationType.weeks) _qtyController.text = '4';
                                    if (val == DurationType.months) _qtyController.text = '1';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _durationType == DurationType.customRange
                                ? OutlinedButton(
                                    onPressed: _selectDateRange,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                                    ),
                                    child: const Text('Select Range'),
                                  )
                                : TextFormField(
                                    controller: _qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Qty',
                                      border: const OutlineInputBorder(),
                                      suffixText: _durationType == DurationType.days
                                          ? 'days'
                                          : _durationType == DurationType.weeks
                                              ? 'wks'
                                              : 'mos',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Required.';
                                      final val = int.tryParse(value);
                                      if (val == null || val <= 0) return 'Invalid.';
                                      return null;
                                    },
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Duration calculations preview
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        leading: const Icon(Icons.today),
                        title: const Text('Calendar Timeline'),
                        subtitle: Text(
                          _durationType == DurationType.customRange && _endDate != null
                              ? '${DateFormat('MMM d, yyyy').format(_startDate)} to ${DateFormat('MMM d, yyyy').format(_endDate!)} ($calculatedDays days)'
                              : 'Starts: ${DateFormat('MMM d, yyyy').format(_startDate)} ($calculatedDays days total)',
                        ),
                        trailing: TextButton(
                          onPressed: _selectStartDate,
                          child: const Text('Start Date'),
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
