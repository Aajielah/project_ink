import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../shared/providers.dart';
import '../../shared/help_bottom_sheet.dart';
import '../../models/project.dart';
import '../../models/schedule.dart';
import '../../models/daily_log.dart';
import '../../services/ongoing_sync_service.dart';
import 'project_duration_type.dart';
import '../../shared/completion_messages.dart';
import '../../shared/date_utils.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({required this.projectId, super.key});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _logController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTodayLog();
  }

  Future<void> _loadTodayLog() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final log = await ref.read(dailyLogRepositoryProvider).getLogForDate(widget.projectId, today);
    if (log != null && mounted) {
      _logController.text = log.actualWords.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logController.dispose();
    super.dispose();
  }

  void _showCompletionDialog(BuildContext context, String projectName) {
    final message = CompletionMessages.getRandomMessage();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Today\'s Goal Complete!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You finished writing for "$projectName" today.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '"$message"',
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  Future<void> _logWords(int planned) async {
    final text = _logController.text.trim();
    if (text.isEmpty) return;

    final actual = int.tryParse(text);
    if (actual == null || actual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive word count.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Today's Log"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Words entered: $actual"),
            const SizedBox(height: 12),
            const Text("Are you sure these are today's words?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final loggingService = ref.read(loggingServiceProvider);
    try {
      final wasCompleted = await loggingService.logWords(
        projectId: widget.projectId,
        date: DateTime.now(),
        actualWords: actual,
      );
      
      _logController.clear();
      _loadTodayLog();

      String? projectName;
      ref.read(projectsProvider).whenOrNull(
        data: (projects) {
          try {
            projectName = projects.firstWhere((p) => p.id == widget.projectId).name;
          } catch (_) {}
        },
      );

      ref.invalidate(projectsProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(homeQuoteProvider(widget.projectId));
      ref.invalidate(homeEncouragementProvider(widget.projectId));
      setState(() {});

      if (wasCompleted && projectName != null) {
        if (mounted) {
          _showCompletionDialog(context, projectName!);
        }
      } else if (!wasCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Words logged successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEditProjectDialog(ProjectModel project) async {
    final isOngoing = project.projectType == ProjectType.ongoing;
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description ?? '');
    final targetWordsController = TextEditingController(text: project.targetWords.toString());
    final dailyTargetController = TextEditingController(text: project.dailyWordTarget.toString());
    
    RestMode editRestMode = project.restMode;
    int editAllowedRestDays = project.allowedRestDays;
    DateTime editStartDate = project.startDate;
    DateTime editExpectedFinishDate = project.expectedFinishDate;
    
    // Calculate initial duration days
    final int initialDurationDays = getDaysDifference(project.startDate, project.expectedFinishDate) + 1;
    final qtyController = TextEditingController(text: initialDurationDays.toString());
    DurationType editDurationType = DurationType.days;
    DateTime? editEndDate = project.expectedFinishDate;
    
    final schedRepo = ref.read(scheduleRepositoryProvider);
    final existingScheds = await schedRepo.getSchedulesForProject(project.id);
    
    final List<int> editFixedRestDays = [];
    if (!isOngoing && project.restMode == RestMode.fixed) {
      for (final s in existingScheds) {
        if (s.isRestDay) {
          final wd = s.date.weekday;
          if (!editFixedRestDays.contains(wd)) {
            editFixedRestDays.add(wd);
          }
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int getCalculatedDays() {
              if (editDurationType == DurationType.customRange) {
                if (editEndDate == null) return 1;
                return getDaysDifference(editStartDate, editEndDate!) + 1;
              }
              final qty = int.tryParse(qtyController.text) ?? 30;
              if (editDurationType == DurationType.days) return qty;
              if (editDurationType == DurationType.weeks) return qty * 7;
              if (editDurationType == DurationType.months) return qty * 30;
              return qty;
            }

            final finalEndDate = !isOngoing
                ? (editDurationType == DurationType.customRange && editEndDate != null
                    ? editEndDate!
                    : editStartDate.add(Duration(days: getCalculatedDays() - 1)))
                : editStartDate;

            return AlertDialog(
              title: const Text('Edit Project Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    
                    // Start Date Picker (Always Editable)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMMM d, yyyy').format(editStartDate)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: editStartDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              editStartDate = picked;
                            });
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (!isOngoing) ...[
                      // Total Target Words (Fixed Only)
                      TextField(
                        controller: targetWordsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Target Words', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      
                      // Duration pickers (Fixed Only)
                      const Text('Duration & Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<DurationType>(
                              value: editDurationType,
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
                                  setDialogState(() {
                                    editDurationType = val;
                                    if (val == DurationType.days) qtyController.text = '30';
                                    if (val == DurationType.weeks) qtyController.text = '4';
                                    if (val == DurationType.months) qtyController.text = '1';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: editDurationType == DurationType.customRange
                                ? OutlinedButton(
                                    onPressed: () async {
                                      final pickedRange = await showDateRangePicker(
                                        context: context,
                                        initialDateRange: DateTimeRange(
                                          start: editStartDate,
                                          end: editEndDate ?? editStartDate.add(const Duration(days: 30)),
                                        ),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (pickedRange != null) {
                                        setDialogState(() {
                                          editStartDate = pickedRange.start;
                                          editEndDate = pickedRange.end;
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                                    ),
                                    child: const Text('Range'),
                                  )
                                : TextFormField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Qty',
                                      border: const OutlineInputBorder(),
                                      suffixText: editDurationType == DurationType.days
                                          ? 'days'
                                          : editDurationType == DurationType.weeks
                                              ? 'wks'
                                              : 'mos',
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.today),
                        title: const Text('New Timeline'),
                        subtitle: Text(
                          'Ends: ${DateFormat('MMM d, yyyy').format(finalEndDate)} (${getCalculatedDays()} days)',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: dailyTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Word Target', border: OutlineInputBorder()),
                    ),
                    if (!isOngoing) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<RestMode>(
                              value: editRestMode,
                              decoration: const InputDecoration(labelText: 'Rest Mode', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: RestMode.fixed, child: Text('Fixed Rest Days')),
                                DropdownMenuItem(value: RestMode.flexible, child: Text('Flexible Rest Days')),
                                DropdownMenuItem(value: RestMode.adaptive, child: Text('Adaptive Rest Days')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    editRestMode = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.info_outline, size: 20),
                            color: Theme.of(context).colorScheme.secondary,
                            onPressed: () => showHelpBottomSheet(context, 'rest_mode'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (editRestMode == RestMode.fixed) ...[
                        const Text('Choose Rest Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            FilterChip(
                              label: const Text('Mon'),
                              selected: editFixedRestDays.contains(1),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(1) : editFixedRestDays.remove(1)),
                            ),
                            FilterChip(
                              label: const Text('Tue'),
                              selected: editFixedRestDays.contains(2),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(2) : editFixedRestDays.remove(2)),
                            ),
                            FilterChip(
                              label: const Text('Wed'),
                              selected: editFixedRestDays.contains(3),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(3) : editFixedRestDays.remove(3)),
                            ),
                            FilterChip(
                              label: const Text('Thu'),
                              selected: editFixedRestDays.contains(4),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(4) : editFixedRestDays.remove(4)),
                            ),
                            FilterChip(
                              label: const Text('Fri'),
                              selected: editFixedRestDays.contains(5),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(5) : editFixedRestDays.remove(5)),
                            ),
                            FilterChip(
                              label: const Text('Sat'),
                              selected: editFixedRestDays.contains(6),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(6) : editFixedRestDays.remove(6)),
                            ),
                            FilterChip(
                              label: const Text('Sun'),
                              selected: editFixedRestDays.contains(7),
                              onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(7) : editFixedRestDays.remove(7)),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          initialValue: editAllowedRestDays.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Rest Days',
                            helperText: 'Choose how many rest days you want throughout this entire project. Project Ink will distribute them automatically across your writing schedule.',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed >= 0) {
                              editAllowedRestDays = parsed;
                            }
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                 FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    final dailyTarget = int.tryParse(dailyTargetController.text) ?? project.dailyWordTarget;
                    final startDate = DateTime(editStartDate.year, editStartDate.month, editStartDate.day);

                    if (name.isEmpty || dailyTarget <= 0) {
                      _showValidationErrorDialog(
                        context,
                        title: 'Invalid Fields',
                        message: 'Project name cannot be empty and daily target must be greater than zero.',
                      );
                      return;
                    }

                    if (!isOngoing) {
                      final targetWords = int.tryParse(targetWordsController.text) ?? project.targetWords;
                      final calcDays = getCalculatedDays();
                      if (editRestMode == RestMode.flexible || editRestMode == RestMode.adaptive) {
                        final writingDays = calcDays - editAllowedRestDays;
                        if (writingDays <= 0 || writingDays * dailyTarget < targetWords) {
                          _showValidationErrorDialog(
                            context,
                            title: 'Schedule Not Possible',
                            message: 'This configuration cannot complete your project. Reduce your total rest days, increase your daily target, or extend the project duration.',
                          );
                          return;
                        }
                      }
                    }

                    final today = DateTime.now();
                    final cleanToday = DateTime(today.year, today.month, today.day);

                    if (isOngoing) {
                      // Delete unlocked future and today's schedules
                      await schedRepo.deleteUnlockedFutureSchedules(project.id, cleanToday);

                      final updated = project.copyWith(
                        name: name,
                        description: desc.isNotEmpty ? desc : null,
                        dailyWordTarget: dailyTarget,
                        startDate: startDate,
                        expectedFinishDate: startDate,
                        updatedAt: DateTime.now(),
                      );
                      await ref.read(projectsProvider.notifier).updateProject(updated);

                      // Run catch-up sync immediately
                      await ref.read(ongoingSyncServiceProvider).syncOngoingSchedules([updated]);
                    } else {
                      final targetWords = int.tryParse(targetWordsController.text) ?? project.targetWords;
                      if (targetWords <= project.writtenWords) {
                        _showValidationErrorDialog(
                          context,
                          title: 'Target Too Small',
                          message: 'Target words ($targetWords) must exceed currently written words (${project.writtenWords}).',
                        );
                        return;
                      }

                      final calcDays = getCalculatedDays();
                      final newEndDate = startDate.add(Duration(days: calcDays - 1));

                      if (newEndDate.isBefore(cleanToday)) {
                        _showValidationErrorDialog(
                          context,
                          title: 'Timeline Ends in Past',
                          message: 'The new timeline ends in the past on ${DateFormat('MMM d, yyyy').format(newEndDate)}. Please select a longer duration or a different start date.',
                        );
                        return;
                      }

                      final List<ScheduleModel> recalculated = [];

                      // 1. Keep history intact (locked or past)
                      for (final s in existingScheds) {
                        if (s.locked || s.date.isBefore(cleanToday)) {
                          recalculated.add(s);
                        }
                      }

                      // 2. Identify future dates
                      final List<DateTime> futureDates = [];
                      var tempDate = startDate.isAfter(cleanToday) ? startDate : cleanToday;
                      while (tempDate.isBefore(newEndDate) || tempDate.isAtSameMomentAs(newEndDate)) {
                        futureDates.add(tempDate);
                        tempDate = tempDate.add(const Duration(days: 1));
                      }

                      // 3. Determine rest days for future dates
                      final List<bool> restDayMap = List.filled(futureDates.length, false);
                      int futureRestDaysCount = 0;
                      
                      if (editRestMode == RestMode.fixed) {
                        for (int i = 0; i < futureDates.length; i++) {
                          if (editFixedRestDays.contains(futureDates[i].weekday)) {
                            restDayMap[i] = true;
                            futureRestDaysCount++;
                          }
                        }
                      } else if (editRestMode == RestMode.adaptive) {
                        // Adaptive: initially no rest days pre-assigned
                      }

                      final futureWritingDays = futureDates.length - futureRestDaysCount;
                      final remainingWordsToPlan = max(0, targetWords - project.writtenWords);
                      final maxPossibleFutureWords = futureWritingDays * dailyTarget;

                      // 4. Validate that the schedule is possible
                      if (maxPossibleFutureWords < remainingWordsToPlan) {
                        final requiredDaily = futureWritingDays > 0 ? (remainingWordsToPlan / futureWritingDays).ceil() : 0;
                        _showValidationErrorDialog(
                          context,
                          title: 'Schedule Not Possible',
                          message: 'Your current plan cannot be completed.\n\n'
                              'Remaining Words: $remainingWordsToPlan\n'
                              'Remaining Days: ${futureDates.length} ($futureWritingDays writing days)\n'
                              'Daily Target Required: $requiredDaily words/day\n\n'
                              'You currently set: $dailyTarget words/day.\n\n'
                              'Please increase your daily target or extend the duration.',
                        );
                        return;
                      }

                      // 5. Distribute remaining words
                      int remainingWordsLeft = remainingWordsToPlan;
                      final uuid = const Uuid();

                      for (int i = 0; i < futureDates.length; i++) {
                        final date = futureDates[i];
                        final isRest = restDayMap[i];
                        int planned = 0;

                        if (!isRest) {
                          planned = min(dailyTarget, remainingWordsLeft);
                          remainingWordsLeft -= planned;
                        }

                        recalculated.add(ScheduleModel(
                          id: uuid.v4(),
                          projectId: project.id,
                          date: date,
                          plannedWords: planned,
                          isRestDay: isRest,
                          completed: false,
                          automaticRestDay: false,
                          locked: false,
                        ));
                      }

                      // 6. Delete unlocked future/today schedules and insert newly recalculated ones
                      await schedRepo.deleteUnlockedFutureSchedules(project.id, cleanToday);
                      await schedRepo.insertSchedules(recalculated.where((s) => !s.locked && !s.date.isBefore(cleanToday)).toList());

                      final updated = project.copyWith(
                        name: name,
                        description: desc.isNotEmpty ? desc : null,
                        targetWords: targetWords,
                        dailyWordTarget: dailyTarget,
                        restMode: editRestMode,
                        allowedRestDays: editAllowedRestDays,
                        startDate: startDate,
                        expectedFinishDate: recalculated.isNotEmpty ? recalculated.last.date : newEndDate,
                        remainingWords: max(0, targetWords - project.writtenWords),
                        updatedAt: DateTime.now(),
                      );
                      await ref.read(projectsProvider.notifier).updateProject(updated);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project settings updated!')),
                      );
                    }
                    _refreshAll();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showValidationErrorDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(projectsProvider);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return projectsAsync.when(
      data: (projects) {
        ProjectModel? project;
        try {
          project = projects.firstWhere((p) => p.id == widget.projectId);
        } catch (_) {}

        if (project == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final logRepo = ref.watch(dailyLogRepositoryProvider);
        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'This Week'),
                Tab(text: 'History'),
                Tab(text: 'Manage'),
              ],
            ),
          ),
          body: FutureBuilder<List<DailyLogModel>>(
            future: logRepo.getLogsForProject(project.id),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              bool isAutoPaused = false;
              if (project!.status == ProjectStatus.paused) {
                final successfulLogs = logs.where((l) => l.actualWords > 0).toList();
                DateTime lastActivity;
                if (successfulLogs.isNotEmpty) {
                  lastActivity = successfulLogs.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
                } else {
                  final createdAt = project.createdAt;
                  lastActivity = project.startDate.isAfter(createdAt) ? project.startDate : createdAt;
                }
                final gap = getDaysDifference(lastActivity, project.updatedAt);
                if (gap >= 7) {
                  isAutoPaused = true;
                }
              }

              return Column(
                children: [
                  if (project.status == ProjectStatus.paused)
                    Container(
                      color: isAutoPaused ? Colors.amber.withOpacity(0.12) : theme.colorScheme.primaryContainer.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            isAutoPaused ? Icons.hourglass_disabled : Icons.pause_circle_outline,
                            color: isAutoPaused ? Colors.orange[800] : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isAutoPaused
                                  ? 'This project was paused automatically due to 7+ days of inactivity.'
                                  : 'This project is paused manually.',
                              style: TextStyle(
                                color: isAutoPaused ? Colors.orange[900] : theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(project: project),
                        _ThisWeekTab(
                          project: project,
                          logController: _logController,
                          onLogSubmitted: _logWords,
                        ),
                        _HistoryTab(projectId: project.id),
                        _ManageTab(
                          project: project,
                          onEditConfiguration: _showEditProjectDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final ProjectModel project;

  const _OverviewTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quoteAsync = ref.watch(homeQuoteProvider(project.id));
    final isOngoing = project.projectType == ProjectType.ongoing;
    final progress = project.targetWords > 0 ? project.writtenWords / project.targetWords : 0.0;
    final logRepo = ref.watch(dailyLogRepositoryProvider);

    return FutureBuilder<List<DailyLogModel>>(
      future: logRepo.getLogsForProject(project.id),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalWritingDays = logs.where((l) => l.actualWords > 0).length;
        final avgWords = totalWritingDays > 0 ? project.writtenWords ~/ totalWritingDays : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Quote
              quoteAsync.when(
                data: (quote) => quote != null
                    ? Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '"${quote.text}"\n— ${quote.author}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Main Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(
                            label: 'Project Streak',
                            value: '${project.projectStreak} days',
                            icon: Icons.local_fire_department,
                            color: theme.colorScheme.primary,
                          ),
                          _StatColumn(
                            label: isOngoing ? 'Longest Streak' : 'Remaining',
                            value: isOngoing
                                ? '${project.longestProjectStreak} days'
                                : '${project.remainingWords} words',
                            icon: isOngoing ? Icons.workspace_premium : Icons.hourglass_empty,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(
                            label: isOngoing ? 'Lifetime Words' : 'Target Goal',
                            value: '${project.writtenWords} words',
                            icon: isOngoing ? Icons.book : Icons.outlined_flag,
                            color: theme.colorScheme.primary,
                          ),
                          _StatColumn(
                            label: isOngoing ? 'Daily Target' : 'Estimated Finish',
                            value: isOngoing
                                ? '${project.dailyWordTarget} words'
                                : DateFormat('MMM d, yyyy').format(project.expectedFinishDate),
                            icon: isOngoing ? Icons.mode_edit : Icons.calendar_today,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      if (!isOngoing && (project.restMode == RestMode.flexible || project.restMode == RestMode.adaptive)) ...[
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(
                              label: project.restMode == RestMode.flexible
                                  ? 'Flexible Rest Days Used'
                                  : 'Adaptive Rest Days Used',
                              value: '${project.allowedRestDays - project.remainingRestDays} days',
                              icon: Icons.check_circle_outline,
                              color: theme.colorScheme.primary,
                            ),
                            _StatColumn(
                              label: project.restMode == RestMode.flexible
                                  ? 'Remaining Flexible Rest Days'
                                  : 'Remaining Adaptive Rest Days',
                              value: '${project.remainingRestDays} days',
                              icon: Icons.hourglass_full,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                project.restMode == RestMode.flexible ? 'Rest Days Remaining' : 'Adaptive Rest Budget',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(project.allowedRestDays, (i) {
                                  final isRemaining = i < project.remainingRestDays;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Text(
                                      isRemaining ? '■' : '□',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isRemaining ? theme.colorScheme.primary : theme.colorScheme.outline,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${project.remainingRestDays} of ${project.allowedRestDays} remaining',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isOngoing) ...[
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(
                              label: 'Total Writing Days',
                              value: '$totalWritingDays days',
                              icon: Icons.calendar_month,
                              color: theme.colorScheme.primary,
                            ),
                            _StatColumn(
                              label: 'Average Words/Day',
                              value: '$avgWords words',
                              icon: Icons.analytics,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Progress Card
              if (!isOngoing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: min(1.0, progress),
                          minHeight: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${project.writtenWords} words written'),
                            Text('${(progress * 100).toInt()}%'),
                          ],
                        ),
                        if (project.backlogWords > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                              const SizedBox(width: 4),
                              Text(
                                'Backlog: ${project.backlogWords} words missed.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ThisWeekTab extends ConsumerWidget {
  final ProjectModel project;
  final TextEditingController logController;
  final Function(int) onLogSubmitted;

  const _ThisWeekTab({
    required this.project,
    required this.logController,
    required this.onLogSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);

    // Calculate current week date bounds
    final weekdayOffset = today.weekday - 1; // days since Monday
    final monday = cleanToday.subtract(Duration(days: weekdayOffset));
    final sunday = monday.add(const Duration(days: 6));

    final schedRepo = ref.watch(scheduleRepositoryProvider);
    final logRepo = ref.watch(dailyLogRepositoryProvider);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        schedRepo.getSchedulesForProject(project.id),
        logRepo.getLogsForProject(project.id),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSchedules = snapshot.data![0] as List<ScheduleModel>;
        final allLogs = snapshot.data![1] as List<DailyLogModel>;

        final weekSchedules = allSchedules.where((s) =>
          (s.date.isAtSameMomentAs(monday) || s.date.isAfter(monday)) &&
          (s.date.isAtSameMomentAs(sunday) || s.date.isBefore(sunday))
        ).toList();

        ScheduleModel? todaySchedule;
        try {
          todaySchedule = weekSchedules.firstWhere((s) => s.date.day == cleanToday.day);
        } catch (_) {}

        DailyLogModel? todayLog;
        if (todaySchedule != null) {
          try {
            todayLog = allLogs.firstWhere(
              (l) => l.date.year == todaySchedule!.date.year &&
                     l.date.month == todaySchedule.date.month &&
                     l.date.day == todaySchedule.date.day,
            );
          } catch (_) {}
        }
        final loggedToday = todayLog?.actualWords ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Log words block
              if (project.status == ProjectStatus.active && todaySchedule != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Today\'s Progress',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todaySchedule.isRestDay
                              ? 'Today is scheduled as a REST DAY. Writing is optional!'
                              : (() {
                                  final sched = todaySchedule!;
                                  final remaining = sched.plannedWords - loggedToday;
                                  if (remaining > 0) {
                                    if (loggedToday > 0) {
                                      return 'Progress: $loggedToday / ${sched.plannedWords} words.\n✨ $remaining words remaining. You can do it!';
                                    } else {
                                      return '$remaining words left today.\nKeep going—you\'ve almost made it!';
                                    }
                                  }
                                  return 'Progress: $loggedToday / ${sched.plannedWords} words.';
                                })(),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        if (todaySchedule.completed) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '✓ Completed Today',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: logController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Words written today',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => onLogSubmitted(todaySchedule?.plannedWords ?? 0),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                ),
                                child: const Text('Log'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Weekly Calendar Targets
              Text(
                'This Week\'s Schedule',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weekSchedules.length,
                itemBuilder: (context, index) {
                  final s = weekSchedules[index];
                  final isToday = s.date.day == cleanToday.day;

                  DailyLogModel? dayLog;
                  try {
                    dayLog = allLogs.firstWhere(
                      (l) => l.date.year == s.date.year &&
                             l.date.month == s.date.month &&
                             l.date.day == s.date.day,
                    );
                  } catch (_) {}
                  final logged = dayLog?.actualWords ?? 0;

                  final isOngoing = project.projectType == ProjectType.ongoing;
                  final isFlex = project.restMode == RestMode.flexible;

                  bool hasAvailableRestDay() {
                    if (isOngoing) return true;
                    if (!isFlex) return false;
                    final available = ref.read(schedulingServiceProvider).getAvailableRestDays(
                      project: project,
                      schedules: allSchedules,
                      logicalToday: getLogicalToday(),
                    );
                    return available > 0;
                  }

                  return GestureDetector(
                    onLongPress: () {
                      if ((isFlex || isOngoing) && isToday && !s.isRestDay) {
                        if (isOngoing) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Convert today into a Rest Day?"),
                              content: const Text("This will mark today as a rest day."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ref.read(projectsProvider.notifier).convertDayToRestDay(project, s);
                                  },
                                  child: const Text("Confirm"),
                                ),
                              ],
                            ),
                          );
                        } else {
                          final hasRest = hasAvailableRestDay();
                          if (!hasRest) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("No Flexible Rest Days remaining."),
                                content: const Text("Today's writing must be completed or it will become backlog."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Convert today into a Rest Day?"),
                                content: const Text("This will consume one of your remaining Flexible Rest Days."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ref.read(projectsProvider.notifier).convertDayToRestDay(project, s);
                                    },
                                    child: const Text("Confirm"),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Card(
                      color: isToday ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                      shape: isToday
                          ? RoundedRectangleBorder(
                              side: BorderSide(color: theme.colorScheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: ListTile(
                        leading: Icon(
                          s.isRestDay
                              ? Icons.coffee
                              : s.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                          color: s.completed
                              ? theme.colorScheme.primary
                              : s.isRestDay
                                  ? theme.colorScheme.outline
                                  : null,
                        ),
                        title: Text(
                          DateFormat('EEEE, MMM d').format(s.date),
                          style: isToday ? const TextStyle(fontWeight: FontWeight.bold) : null,
                        ),
                        subtitle: Text(
                          s.isRestDay ? 'Rest Day' : '$logged / ${s.plannedWords} words',
                        ),
                        trailing: isToday
                            ? Card(
                                elevation: 0,
                                color: theme.colorScheme.primary,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    'TODAY',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerStatefulWidget {
  final String projectId;

  const _HistoryTab({super.key, required this.projectId});

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  bool _showRestDays = false;

  @override
  Widget build(BuildContext context) {
    final logRepo = ref.watch(dailyLogRepositoryProvider);
    final schedRepo = ref.watch(scheduleRepositoryProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        logRepo.getLogsForProject(widget.projectId),
        schedRepo.getSchedulesForProject(widget.projectId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = (snapshot.data![0] as List<DailyLogModel>).reversed.toList();
        final schedules = snapshot.data![1] as List<ScheduleModel>;

        final scheduleMap = {
          for (final s in schedules)
            DateTime(s.date.year, s.date.month, s.date.day): s
        };

        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No writing logs recorded yet. Start writing and log today!'),
                ],
              ),
            ),
          );
        }

        final filteredLogs = logs.where((l) {
          final s = scheduleMap[DateTime(l.date.year, l.date.month, l.date.day)];
          final isRest = s?.isRestDay ?? (l.plannedWords == 0);
          if (isRest) {
            return _showRestDays;
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History Timeline',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.coffee_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Show Rest Days',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: _showRestDays,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          setState(() {
                            _showRestDays = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            const Text('No writing events to display. Enable "Show Rest Days" to view rest periods.'),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final l = filteredLogs[index];
                        final s = scheduleMap[DateTime(l.date.year, l.date.month, l.date.day)];
                        final isRest = s?.isRestDay ?? (l.plannedWords == 0);
                        final logicalToday = getLogicalToday();

                        Widget leadingIcon;
                        Color accentColor;
                        String statusTitle;
                        String statusSubtitle;
                        String? extraText;
                        bool isEditable = !isRest && (l.actualWords < l.plannedWords);

                        if (isRest) {
                          leadingIcon = const Icon(Icons.coffee, color: Colors.teal, size: 28);
                          accentColor = Colors.teal;
                          statusTitle = s?.automaticRestDay == true ? 'Rest Day (Adaptive)' : 'Rest Day (Manual)';
                          statusSubtitle = s?.automaticRestDay == true
                              ? 'Adaptive rest day automatically assigned.\nRecovery is part of consistency.'
                              : 'You took a planned rest day.\nRecovery is part of consistency.';
                        } else if (l.plannedWords > 0 && l.actualWords == 0) {
                          leadingIcon = Icon(Icons.error_outline, color: theme.colorScheme.error, size: 28);
                          accentColor = theme.colorScheme.error;
                          statusTitle = 'Missed Day';
                          statusSubtitle = '0 / ${l.plannedWords} words\n${l.plannedWords} words added to backlog';
                        } else if (l.plannedWords > 0 && l.actualWords < l.plannedWords) {
                          leadingIcon = const Icon(Icons.hourglass_bottom, color: Colors.orange, size: 28);
                          accentColor = Colors.orange;
                          statusTitle = 'Backlog Remaining';
                          statusSubtitle = '${l.actualWords} / ${l.plannedWords} words\n${l.plannedWords - l.actualWords} words remaining';
                          if (l.backlogCreated == -1) {
                            extraText = 'All backlog resolved!';
                          }
                        } else {
                          leadingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 28);
                          accentColor = Colors.green;
                          statusTitle = 'Completed';
                          statusSubtitle = '${l.actualWords} / ${l.plannedWords} words';
                          if (l.backlogCreated == -1) {
                            extraText = 'All backlog resolved!';
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            leading: leadingIcon,
                            title: Text(
                              DateFormat('EEEE, MMM d, yyyy').format(l.date),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  statusTitle,
                                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(statusSubtitle),
                                if (extraText != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    extraText,
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ]
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (l.backlogCreated > 0) ...[
                                  IconButton(
                                    icon: const Icon(Icons.playlist_add_check, color: Colors.orange, size: 24),
                                    tooltip: "Resolve backlog",
                                    onPressed: () {
                                      _showResolveBacklogDialog(context, ref, l);
                                    },
                                  ),
                                ] else if (l.backlogCreated == -1) ...[
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        "Resolved",
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                                if (isEditable &&
                                    l.date.year == logicalToday.year &&
                                    l.date.month == logicalToday.month &&
                                    l.date.day == logicalToday.day) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: "Edit today's log",
                                    onPressed: () {
                                      _showEditLogDialog(context, ref, l);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showResolveBacklogDialog(BuildContext context, WidgetRef ref, DailyLogModel log) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Resolve Backlog"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Backlog remaining: ${log.backlogCreated} words"),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Words written to resolve backlog',
                  suffixText: 'words',
                  helperText: 'Max allowed: ${log.backlogCreated} words',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final words = int.tryParse(text) ?? 0;
                if (words <= 0 || words > log.backlogCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a value between 1 and ${log.backlogCreated}')),
                  );
                  return;
                }

                Navigator.pop(context);
                
                final db = ref.read(dbProvider);
                final logRepo = ref.read(dailyLogRepositoryProvider);
                final schedRepo = ref.read(scheduleRepositoryProvider);
                final projRepo = ref.read(projectRepositoryProvider);
                final statsRepo = ref.read(statisticsRepositoryProvider);
                
                final project = await projRepo.getProjectById(log.projectId);
                if (project == null) return;

                final schedule = await schedRepo.getScheduleForDate(log.projectId, log.date);

                await db.transaction(() async {
                  final newActual = log.actualWords + words;
                  int newBacklog = log.backlogCreated - words;
                  if (newBacklog == 0) {
                    newBacklog = -1; // Special flag for fully resolved
                  }
                  final isCompleted = newActual >= log.plannedWords;
                  
                  await logRepo.insertLog(log.copyWith(
                    actualWords: newActual,
                    backlogCreated: newBacklog,
                    completed: isCompleted,
                  ));

                  if (schedule != null) {
                    await schedRepo.updateSchedule(schedule.copyWith(
                      completed: isCompleted,
                    ));
                  }

                  final newWritten = project.writtenWords + words;
                  final newBacklogWords = max(0, project.backlogWords - words);
                  final newRemaining = max(0, project.targetWords - newWritten);
                  
                  await projRepo.updateProject(project.copyWith(
                    writtenWords: newWritten,
                    backlogWords: newBacklogWords,
                    remainingWords: newRemaining,
                    updatedAt: DateTime.now(),
                  ));
                });

                await statsRepo.recalculateStatistics();
                
                ref.invalidate(projectsProvider);
                ref.invalidate(statisticsProvider);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Resolved $words words of backlog!')),
                );
              },
              child: const Text('Submit'),
            )
          ],
        );
      },
    );
  }

  void _showEditLogDialog(BuildContext context, WidgetRef ref, DailyLogModel log) {
    final controller = TextEditingController(text: log.actualWords.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Today's Log"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Words Written Today',
              suffixText: 'words',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final words = int.tryParse(text) ?? 0;
                if (words < 0) return;

                Navigator.pop(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Today's Log Edit"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("New words entered: $words"),
                        const SizedBox(height: 12),
                        const Text("Are you sure you want to update today's log?"),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ref.read(loggingServiceProvider).logWords(
                      projectId: log.projectId,
                      date: DateTime.now(),
                      actualWords: words,
                      isAdditive: false,
                    );
                    
                    ref.invalidate(projectsProvider);
                    ref.invalidate(statisticsProvider);
                    ref.invalidate(homeQuoteProvider(log.projectId));
                    ref.invalidate(homeEncouragementProvider(log.projectId));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log updated successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update log: $e')),
                    );
                  }
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _ManageTab extends ConsumerWidget {
  final ProjectModel project;
  final Function(ProjectModel) onEditConfiguration;

  const _ManageTab({
    required this.project,
    required this.onEditConfiguration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Configuration edit panel
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Project Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adjust writing goals, timeline, or rest day setups. Project Ink will recalculate future days while preserving your logs.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onEditConfiguration(project),
                  icon: const Icon(Icons.settings),
                  label: const Text('Edit Project Configuration'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Pause/Resume actions
        Card(
          child: Column(
            children: [
              if (project.status == ProjectStatus.active)
                ListTile(
                  leading: const Icon(Icons.pause),
                  title: const Text('Pause Project'),
                  subtitle: const Text('Temporarily freezes streaks and scheduled calendar days.'),
                  onTap: () async {
                    await ref.read(projectsProvider.notifier).pauseProject(project.id);
                  },
                ),
              if (project.status == ProjectStatus.paused)
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Resume Project'),
                  subtitle: const Text('Extend schedule and resume daily targets.'),
                  onTap: () async {
                    await ref.read(projectsProvider.notifier).resumeProject(project.id);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                title: Text(
                  'Delete Project',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Permanently deletes the project, history logs, and schedule.'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                          'Are you sure you want to permanently delete this writing project and all associated logs? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    context.pop(); // Go back to listings immediately
                    ref.read(projectsProvider.notifier).deleteProject(project.id);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
