import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/services/day_finalizer_service.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/motivation_utils.dart';
import '../../../shared/models/project.dart';
import '../../home/presentation/home_controller.dart';
import 'projects_hub_page.dart';

class CreateProjectPage extends ConsumerStatefulWidget {
  const CreateProjectPage({super.key});

  @override
  ConsumerState<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends ConsumerState<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _motivationController = TextEditingController();
  final _durationValueController = TextEditingController(text: '30');

  String _selectedCategory = 'Fitness';
  String _selectedUnit = 'Days';
  String _selectedMode = 'strict'; // 'strict' or 'trust'
  late DateTime _startDate;
  DateTime? _customEndDate;
  bool _isCustomMotivation = false;

  @override
  void initState() {
    super.initState();
    _startDate = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    _motivationController.text = MotivationUtils.getDefaultMotivation(_selectedCategory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  int get _calculatedTotalDays {
    final val = int.tryParse(_durationValueController.text) ?? 1;
    return DurationUtils.calculateTotalDays(
      unit: _selectedUnit,
      value: val,
      startDate: _startDate,
      customEndDate: _customEndDate,
    );
  }

  DateTime get _calculatedEndDate {
    return DurationUtils.calculateEndDate(_startDate, _calculatedTotalDays);
  }

  Future<void> _selectStartDate() async {
    final today = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DurationUtils.normalizeDate(picked);
      });
    }
  }

  Future<void> _selectCustomEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _customEndDate = DurationUtils.normalizeDate(picked);
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final motivation = _motivationController.text.trim();
    final totalDays = _calculatedTotalDays;
    final endDate = _calculatedEndDate;

    final project = Project()
      ..title = title
      ..category = _selectedCategory
      ..motivation = motivation.isNotEmpty
          ? motivation
          : MotivationUtils.getDefaultMotivation(_selectedCategory)
      ..targetDays = totalDays
      ..completedDays = 0
      ..trackingMode = _selectedMode
      ..status = 'active'
      ..startDate = _startDate
      ..endDate = endDate
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..reminderEnabled = true;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.saveProject(project);

      ref.read(homeControllerProvider.notifier).refresh();
      ref.invalidate(allProjectsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal "$title" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getColor(_selectedCategory, context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Write My Novel, 100 Days of Code',
                prefixIcon: const Icon(Icons.flag_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(
                  CategoryUtils.getIcon(_selectedCategory),
                  color: categoryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                    if (!_isCustomMotivation) {
                      _motivationController.text = MotivationUtils.getDefaultMotivation(val);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Motivation Message Input
            TextFormField(
              controller: _motivationController,
              decoration: InputDecoration(
                labelText: 'Motivation Message',
                hintText: 'Why is this commitment important to you?',
                prefixIcon: const Icon(Icons.format_quote_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              onChanged: (_) => _isCustomMotivation = true,
            ),
            const SizedBox(height: 24),

            // Target Duration Section
            Text(
              'Target Duration',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_selectedUnit != 'Custom Range') ...[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _durationValueController,
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (_selectedUnit == 'Custom Range') return null;
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: DurationUtils.units.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedUnit = val;
                          if (val == 'Days' && _durationValueController.text == '12') {
                            _durationValueController.text = '30';
                          } else if (val == 'Weeks' && _durationValueController.text == '30') {
                            _durationValueController.text = '12';
                          } else if (val == 'Months' && _durationValueController.text == '12') {
                            _durationValueController.text = '3';
                          } else if (val == 'Years') {
                            _durationValueController.text = '1';
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_selectedUnit == 'Custom Range') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectCustomEndDate,
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  _customEndDate == null
                      ? 'Select End Date'
                      : 'End Date: ${DurationUtils.formatDate(_customEndDate!)}',
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Start Date Selector
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Start Date'),
              subtitle: Text(DurationUtils.formatDate(_startDate)),
              trailing: TextButton(
                onPressed: _selectStartDate,
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Live Calculation Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Total Target', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '$_calculatedTotalDays Days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                  Column(
                    children: [
                      const Text('Target End Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        DurationUtils.formatDate(_calculatedEndDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tracking Mode Selection
            Text(
              'Accountability Mode',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                                Text(
                                  'Strict Mode',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Requires daily manual check-ins. Missed days are permanent.',
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
                                Text(
                                  'Trust Mode',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Auto-completes days for you. You can honestly mark missed days.',
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
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _saveGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Goal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
