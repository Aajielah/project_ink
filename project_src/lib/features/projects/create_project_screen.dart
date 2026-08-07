import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import '../../shared/cover_matching_helper.dart';
import '../../shared/help_bottom_sheet.dart';

import '../../shared/providers.dart';
import '../../shared/date_utils.dart';
import '../../models/project.dart';
import 'project_duration_type.dart';
import 'widgets/book_cover_widget.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  ProjectType _projectType = ProjectType.fixed;

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
  String _ongoingStyle = 'daily';
  String _writingSession = 'none';

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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final pickedPath = pickedFile.path;
        final appDir = await getApplicationDocumentsDirectory();
        
        // Check if an identical image already exists to avoid duplication
        final existingPath = await findExistingMatchingCover(File(pickedPath), appDir);
        
        String finalPath;
        if (existingPath != null) {
          finalPath = existingPath;
        } else {
          // Generate unique filename preserving extension
          final extensionName = p.extension(pickedPath);
          final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}$extensionName';
          final savedFile = await File(pickedPath).copy('${appDir.path}/$fileName');
          finalPath = savedFile.path;
        }
        
        setState(() {
          _coverType = 'uploaded';
          _coverImagePath = finalPath;
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
      return getDaysDifference(cleanStart, cleanEnd) + 1;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (_durationType == DurationType.weeks) return qty * 7;
    if (_durationType == DurationType.months) return qty * 30;
    return qty; // days
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(projectsProvider.notifier);
    String? saveError;

    if (_projectType == ProjectType.fixed) {
      final targetWords = int.parse(_targetWordsController.text);
      final dailyTarget = int.parse(_dailyTargetController.text);
      final durationDays = _calculateTotalDays();

      if (durationDays <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid duration/date range.')),
        );
        return;
      }

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

      saveError = await notifier.addProject(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        projectType: ProjectType.fixed,
        targetWords: targetWords,
        dailyWordTarget: dailyTarget,
        durationDays: durationDays,
        startDate: _startDate,
        restMode: _restMode,
        fixedRestWeekdays: _fixedRestDays,
        allowedRestDays: _allowedRestDays,
        coverImagePath: _coverImagePath,
        coverType: _coverType,
        writingSession: _writingSession,
      );
    } else {
      final dailyTarget = int.parse(_dailyTargetController.text);

      saveError = await notifier.addProject(
        name: _nameController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        dailyWordTarget: dailyTarget,
        durationDays: 0,
        startDate: _startDate,
        restMode: RestMode.flexible,
        fixedRestWeekdays: const [],
        allowedRestDays: 0,
        coverImagePath: _coverImagePath,
        coverType: _coverType,
        ongoingStyle: _ongoingStyle,
        writingSession: _writingSession,
      );
    }

    if (saveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveError)),
      );
    } else {
      context.pop();
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

              // Project Type Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Project Type',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 20),
                            color: theme.colorScheme.secondary,
                            onPressed: () => showHelpBottomSheet(context, 'project_type'),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<ProjectType>(
                        segments: const [
                          ButtonSegment<ProjectType>(
                            value: ProjectType.fixed,
                            icon: Icon(Icons.flag),
                            label: Text('Fixed Goal'),
                          ),
                          ButtonSegment<ProjectType>(
                            value: ProjectType.ongoing,
                            icon: Icon(Icons.all_inclusive),
                            label: Text('Ongoing Habit'),
                          ),
                        ],
                        selected: {_projectType},
                        onSelectionChanged: (Set<ProjectType> newSelection) {
                          setState(() {
                            _projectType = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _projectType == ProjectType.fixed
                            ? 'A Fixed Goal project has a target word count, duration, and customized rest days.'
                            : 'An Ongoing Habit has no target word count or end date—only a daily target task that auto-generates.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              const SizedBox(height: 16),              // Targets Card
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
                      if (_projectType == ProjectType.fixed) ...[
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
                      ],
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
                      if (_projectType == ProjectType.fixed) ...[
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
                      ],
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        leading: const Icon(Icons.today),
                        title: Text(_projectType == ProjectType.fixed ? 'Calendar Timeline' : 'Start Date'),
                        subtitle: Text(
                          _projectType == ProjectType.fixed
                              ? (_durationType == DurationType.customRange && _endDate != null
                                  ? '${DateFormat('MMM d, yyyy').format(_startDate)} to ${DateFormat('MMM d, yyyy').format(_endDate!)} ($calculatedDays days)'
                                  : 'Starts: ${DateFormat('MMM d, yyyy').format(_startDate)} ($calculatedDays days total)')
                              : 'Starts: ${DateFormat('MMMM d, yyyy').format(_startDate)}',
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

              // Writing Schedule (Ongoing style selection) Card
              if (_projectType == ProjectType.ongoing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Writing Schedule',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              color: theme.colorScheme.secondary,
                              onPressed: () => showHelpBottomSheet(context, 'ongoing_style'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select how often you want to write for this ongoing habit.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        RadioListTile<String>(
                          title: const Text('Daily'),
                          subtitle: const Text('Write every day. Great for building a consistent daily habit.'),
                          value: 'daily',
                          groupValue: _ongoingStyle,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _ongoingStyle = val;
                              });
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Rhythm Mode'),
                          subtitle: const Text('Write every other day. Recovery days alternate automatically with writing days.'),
                          value: 'rhythm',
                          groupValue: _ongoingStyle,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _ongoingStyle = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rest Day Configuration Card
              if (_projectType == ProjectType.fixed) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rest Day Mode',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              color: theme.colorScheme.secondary,
                              onPressed: () => showHelpBottomSheet(context, 'rest_mode'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Project Ink forces rest days to avoid burnout. Choose how you want to schedule them.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final totalDays = _calculateTotalDays();
                            final showSprint = totalDays <= 10;
                            
                            // If Sprint Mode was selected but duration is now > 10, auto-switch to Flexible
                            if (!showSprint && _restMode == RestMode.sprint) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _restMode = RestMode.flexible;
                                });
                              });
                            }

                            return DropdownButtonFormField<RestMode>(
                              value: _restMode == RestMode.sprint && !showSprint ? null : _restMode,
                              decoration: const InputDecoration(
                                labelText: 'Select Rest Mode',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: RestMode.fixed,
                                  child: Text('Fixed Rest Days'),
                                ),
                                const DropdownMenuItem(
                                  value: RestMode.flexible,
                                  child: Text('Flexible Rest Days'),
                                ),
                                const DropdownMenuItem(
                                  value: RestMode.adaptive,
                                  child: Text('Adaptive Rest Days'),
                                ),
                                if (showSprint)
                                  const DropdownMenuItem(
                                    value: RestMode.sprint,
                                    child: Text('Sprint Mode'),
                                  ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _restMode = val;
                                    if (val == RestMode.sprint) {
                                      _allowedRestDays = 0;
                                    }
                                  });
                                }
                              },
                            );
                          }
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
                        ] else if (_restMode == RestMode.flexible || _restMode == RestMode.adaptive) ...[
                          TextFormField(
                            key: ValueKey('rest_days_${_restMode.name}'),
                            initialValue: _allowedRestDays.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Rest Days',
                              helperText: 'Choose how many rest days you want throughout this entire project. Project Ink will distribute them automatically across your writing schedule.',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required.';
                              final val = int.tryParse(value);
                              if (val == null || val < 0) return 'Must be 0 or greater.';
                              if (val == 0) {
                                return '${_restMode == RestMode.flexible ? 'Flexible' : 'Adaptive'} Rest Days must be at least 1.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final val = int.tryParse(value);
                              if (val != null && val >= 0) {
                                _allowedRestDays = val;
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Writing Session (Optional)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              color: theme.colorScheme.secondary,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Writing Sessions',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Writing Sessions help organize your daily writing routine.\n\n'
                                              'Assign projects to either:\n'
                                              '🌅 Morning Session\n'
                                              'or\n'
                                              '🌙 Evening Session\n\n'
                                              'Projects assigned to a session appear only during that time on the Home screen.\n\n'
                                              'Choosing No Preference makes the project appear all day.\n\n'
                                              'Writing Sessions do NOT affect deadlines, backlog, reminders, or statistics. They are purely an organizational tool.',
                                            ),
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              child: FilledButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Got it'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Organize when this project appears on your Home screen.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        RadioListTile<String>(
                          title: const Text('No Preference'),
                          subtitle: const Text('Appears on Home screen all day'),
                          value: 'none',
                          groupValue: _writingSession,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _writingSession = val;
                              });
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Morning Session'),
                          subtitle: const Text('Appears on Home screen 5:00 AM – 4:59 PM'),
                          value: 'morning',
                          groupValue: _writingSession,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _writingSession = val;
                              });
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Evening Session'),
                          subtitle: const Text('Appears on Home screen 5:00 PM – 4:59 AM'),
                          value: 'evening',
                          groupValue: _writingSession,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _writingSession = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Writing Sessions are optional. They only control where this project appears on the Home screen. Deadlines, logging, backlog, statistics, and reminders continue working normally.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
