import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/project.dart';
import '../../models/schedule.dart';
import '../../models/daily_log.dart';
import '../../models/quote.dart';
import '../projects/widgets/book_cover_widget.dart';
import '../../shared/completion_messages.dart';
import '../../shared/date_utils.dart';

class _ProjectWithScore {
  final ProjectModel project;
  final double score;
  final String reason;
  final int confidence;

  const _ProjectWithScore({
    required this.project,
    required this.score,
    required this.reason,
    required this.confidence,
  });
}

class TodayWritingTask {
  final ProjectModel project;
  final ScheduleModel schedule;
  final DailyLogModel? log;
  final DateTime? lastSuccessfulLogDate;

  const TodayWritingTask({
    required this.project,
    required this.schedule,
    this.log,
    this.lastSuccessfulLogDate,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  String _selectedStrategy = 'smart';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(projectsProvider.notifier).loadProjects(silent: true);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<List<TodayWritingTask>> _fetchTodayTasks(List<ProjectModel> activeProjects) async {
    final schedRepo = ref.read(scheduleRepositoryProvider);
    final logRepo = ref.read(dailyLogRepositoryProvider);
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);

    final List<TodayWritingTask> tasks = [];
    for (final p in activeProjects) {
      final sched = await schedRepo.getScheduleForDate(p.id, cleanToday);
      if (sched != null) {
        final log = await logRepo.getLogForDate(p.id, cleanToday);
        final logs = await logRepo.getLogsForProject(p.id);
        final successfulLogs = logs.where((l) => l.actualWords > 0).toList();
        DateTime? lastSuccessfulLogDate;
        if (successfulLogs.isNotEmpty) {
          lastSuccessfulLogDate = successfulLogs.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
        }

        tasks.add(TodayWritingTask(
          project: p,
          schedule: sched,
          log: log,
          lastSuccessfulLogDate: lastSuccessfulLogDate,
        ));
      }
    }
    return tasks;
  }

  Map<String, dynamic> _computeRecommendation(
    List<ProjectModel> activeProjects,
    List<TodayWritingTask> todayTasks,
  ) {
    if (activeProjects.isEmpty) {
      return {
        'name': 'No Active Projects',
        'reason': 'Create or resume a writing project to receive custom advisor recommendations.',
        'confidence': 0,
        'project': null,
      };
    }

    final today = getLogicalToday();
    double getProgress(ProjectModel p) => p.targetWords > 0 ? p.writtenWords / p.targetWords : 0.0;

    final List<_ProjectWithScore> scored = [];

    switch (_selectedStrategy) {
      case 'near':
        final unfinished = activeProjects.where((p) => getProgress(p) < 1.0).toList();
        final list = unfinished.isEmpty ? activeProjects : unfinished;
        for (final p in list) {
          final progress = getProgress(p);
          scored.add(_ProjectWithScore(
            project: p,
            score: progress,
            reason: 'This book is nearest to completion (${(progress * 100).toInt()}% done). Focus here to cross the finish line!',
            confidence: 90,
          ));
        }
        break;

      case 'deadline':
        for (final p in activeProjects) {
          if (p.projectType == ProjectType.ongoing) {
            scored.add(_ProjectWithScore(
              project: p,
              score: 0.0,
              reason: 'Ongoing project "${p.name}" has no fixed deadline.',
              confidence: 50,
            ));
          } else {
            final daysToDeadline = getDaysDifference(today, p.expectedFinishDate);
            final score = (365 - daysToDeadline).clamp(0, 365).toDouble();
            scored.add(_ProjectWithScore(
              project: p,
              score: score,
              reason: 'This manuscript has the earliest expected finish date (${DateFormat('MMM d').format(p.expectedFinishDate)}). Stay on schedule!',
              confidence: 85,
            ));
          }
        }
        break;

      case 'target':
        for (final p in activeProjects) {
          scored.add(_ProjectWithScore(
            project: p,
            score: p.dailyWordTarget.toDouble(),
            reason: 'This project requires the highest daily output (${p.dailyWordTarget} words/day) to stay on path.',
            confidence: 80,
          ));
        }
        break;

      case 'rotate':
        for (final p in activeProjects) {
          final task = todayTasks.firstWhere((t) => t.project.id == p.id, orElse: () => TodayWritingTask(
            project: p,
            schedule: ScheduleModel(
              id: '', projectId: p.id, date: today, plannedWords: 0,
              isRestDay: true, completed: false, automaticRestDay: false, locked: false,
            ),
          ));
          final lastWorked = task.lastSuccessfulLogDate ?? p.startDate;
          final daysSinceLastWorked = getDaysDifference(lastWorked, today);
          scored.add(_ProjectWithScore(
            project: p,
            score: daysSinceLastWorked.toDouble(),
            reason: 'You haven\'t logged words here recently. Rotate back to keep the narrative draft fresh!',
            confidence: 75,
          ));
        }
        break;

      case 'smart':
      default:
        for (final p in activeProjects) {
          final task = todayTasks.firstWhere((t) => t.project.id == p.id, orElse: () => TodayWritingTask(
            project: p,
            schedule: ScheduleModel(
              id: '', projectId: p.id, date: today, plannedWords: 0,
              isRestDay: true, completed: false, automaticRestDay: false, locked: false,
            ),
          ));
          int rem = 0;
          if (!task.schedule.isRestDay && !task.schedule.completed) {
            rem = max(0, task.schedule.plannedWords - (task.log?.actualWords ?? 0));
          }

          final double score1 = rem > 0 ? (10000 - rem).clamp(0, 10000) / 10000.0 : 0.0;
          final double score3 = p.backlogWords.clamp(0, 10000) / 10000.0;

          final lastWorked = task.lastSuccessfulLogDate ?? p.startDate;
          final daysSinceLastWorked = getDaysDifference(lastWorked, today);
          final double score4 = daysSinceLastWorked.clamp(0, 30) / 30.0;

          final double score5 = p.dailyWordTarget.clamp(0, 5000) / 5000.0;

          double totalScore;
          if (p.projectType == ProjectType.ongoing) {
            // Urgency weight redistribution for ongoing projects
            totalScore = (score1 * 120.0) + (score3 * 100.0) + (score4 * 60.0) + (score5 * 20.0);
          } else {
            final daysToDeadline = getDaysDifference(today, p.expectedFinishDate);
            final double score2 = (365 - daysToDeadline).clamp(0, 365) / 365.0;
            totalScore = (score1 * 100.0) + (score2 * 80.0) + (score3 * 60.0) + (score4 * 40.0) + (score5 * 20.0);
          }

          if (rem > 0) {
            totalScore += 1000.0; // Incomplete daily target boost
          }

          String reason = "Keep your writing streak active on this book!";
          int confidence = 70;

          if (rem > 0) {
            reason = 'Finish today\'s target: only $rem words remaining on "${p.name}" today!';
            confidence = 95;
          } else if (p.backlogWords > 0) {
            reason = 'Urgent backlog: "${p.name}" has ${p.backlogWords} words of backlog to catch up.';
            confidence = 90;
          } else if (p.projectType != ProjectType.ongoing && getDaysDifference(today, p.expectedFinishDate) < 7) {
            reason = 'Approaching deadline: "${p.name}" is due on ${DateFormat('MMM d').format(p.expectedFinishDate)}.';
            confidence = 85;
          } else if (daysSinceLastWorked >= 3) {
            reason = 'Keep it fresh: rotate back to "${p.name}" as you haven\'t logged words here recently.';
            confidence = 75;
          } else {
            reason = 'Consistent output: maintain your daily momentum on "${p.name}" with a target of ${p.dailyWordTarget} words.';
            confidence = 70;
          }

          scored.add(_ProjectWithScore(
            project: p,
            score: totalScore,
            reason: reason,
            confidence: confidence,
          ));
        }
        break;
    }

    if (scored.isEmpty) {
      final p = activeProjects.first;
      return {
        'name': p.name,
        'reason': 'Keep your daily writing streak active on this book!',
        'confidence': 70,
        'project': p,
      };
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final maxScore = scored.first.score;
    final candidates = scored.where((s) => (maxScore - s.score).abs() < 0.01).toList();

    final rotationIndex = (today.day + DateTime.now().hour) % candidates.length;
    final chosen = candidates[rotationIndex];

    return {
      'name': chosen.project.name,
      'reason': chosen.reason,
      'confidence': chosen.confidence,
      'project': chosen.project,
    };
  }

  void _triggerQuickLog(List<TodayWritingTask> tasks) {
    final writingTasks = tasks.where((t) => !t.schedule.isRestDay && !t.schedule.completed).toList();

    if (writingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All scheduled projects are already completed for today!')),
      );
      return;
    }

    if (writingTasks.length == 1) {
      _showSingleLogDialog(writingTasks.first);
    } else {
      _showSplitLogDialog(writingTasks);
    }
  }

  void _showSingleLogDialog(TodayWritingTask task) {
    final controller = TextEditingController(
      text: task.log != null ? task.log!.actualWords.toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Words for "${task.project.name}"'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Words Written Today',
              hintText: 'e.g. 500',
              suffixText: 'words',
              helperText: 'Target today: ${task.schedule.plannedWords} words',
              border: const OutlineInputBorder(),
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
                if (words <= 0) return;

                Navigator.pop(context);
                
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Confirm Today's Log"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Book: ${task.project.name}"),
                        const SizedBox(height: 8),
                        Text("Words entered: $words"),
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

                if (confirmed == true) {
                  await _submitLog(task.project.id, words);
                }
              },
              child: const Text('Continue'),
            )
          ],
        );
      },
    );
  }

  void _showSplitLogDialog(List<TodayWritingTask> tasks) {
    final totalController = TextEditingController();
    String selectedMethod = 'even'; // 'even', 'proportional', 'smart', 'manual'
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Global Quick Log'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Words Written Today',
                      hintText: 'Enter total words written across all books',
                      suffixText: 'words',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Split Method:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  
                  // Even Split Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'even';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedMethod == 'even'
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedMethod == 'even'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'even',
                            groupValue: selectedMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                selectedMethod = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚖️ Even Split',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Distribute words equally among all active books today.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Proportional Split Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'proportional';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedMethod == 'proportional'
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedMethod == 'proportional'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'proportional',
                            groupValue: selectedMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                selectedMethod = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📊 By Today\'s Targets',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Distribute words proportionally based on today\'s targets.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Smart Split Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'smart';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedMethod == 'smart'
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedMethod == 'smart'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'smart',
                            groupValue: selectedMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                selectedMethod = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🧠 Smart Split',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Fills backlogs first, then targets.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Manual Card
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedMethod = 'manual';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedMethod == 'manual'
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedMethod == 'manual'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'manual',
                            groupValue: selectedMethod,
                            onChanged: (val) {
                              setDialogState(() {
                                selectedMethod = val!;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✍️ Manual Allocation',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Enter custom words for each project individually.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final val = int.tryParse(totalController.text) ?? 0;
                    if (selectedMethod != 'manual' && val <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid word count.')),
                      );
                      return;
                    }
                    
                    if (selectedMethod == 'manual') {
                      Navigator.pop(context);
                      _showManualAllocationDialog(tasks);
                      return;
                    }

                    Map<String, int> allocations = {};
                    String strategyLabel = '';
                    if (selectedMethod == 'even') {
                      allocations = _calculateEvenSplit(tasks, val);
                      strategyLabel = 'Even Split';
                    } else if (selectedMethod == 'proportional') {
                      allocations = _calculateProportionalSplit(tasks, val);
                      strategyLabel = 'By Today\'s Targets';
                    } else if (selectedMethod == 'smart') {
                      allocations = _calculateSmartSplit(tasks, val);
                      strategyLabel = 'Smart Split';
                    }

                    Navigator.pop(context);
                    
                    final confirmed = await _showSplitPreviewConfirmDialog(tasks, val, strategyLabel, allocations);
                    if (confirmed == true) {
                      await _applyAllocations(tasks, allocations, val, strategyLabel);
                    }
                  },
                  child: const Text('Log Words'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManualAllocationDialog(List<TodayWritingTask> tasks) {
    final controllers = {
      for (var t in tasks)
        t.project.id: TextEditingController(
          text: t.log != null ? t.log!.actualWords.toString() : '',
        )
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Word Allocation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tasks.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: controllers[t.project.id],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.project.name,
                      suffixText: 'words',
                      helperText: 'Target today: ${t.schedule.plannedWords} words',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final Map<String, int> allocations = {};
                int totalManual = 0;
                for (final t in tasks) {
                  final text = controllers[t.project.id]!.text.trim();
                  final words = int.tryParse(text) ?? 0;
                  if (words > 0) {
                    allocations[t.project.id] = words;
                    totalManual += words;
                  }
                }
                
                if (allocations.isEmpty) return;

                Navigator.pop(context);

                final confirmed = await _showSplitPreviewConfirmDialog(tasks, totalManual, 'Manual Allocation', allocations);
                if (confirmed == true) {
                  await _applyAllocations(tasks, allocations, totalManual, 'Manual Allocation');
                }
              },
              child: const Text('Continue'),
            )
          ],
        );
      },
    );
  }

  Future<void> _submitLog(String projectId, int words, {bool isAdditive = true}) async {
    try {
      final project = ref.read(projectsProvider).value?.firstWhere((p) => p.id == projectId);
      
      final wasCompleted = await ref.read(loggingServiceProvider).logWords(
            projectId: projectId,
            date: DateTime.now(),
            actualWords: words,
            isAdditive: isAdditive,
          );
      _refreshAll();
      if (wasCompleted && project != null) {
        if (context.mounted) {
          _showCompletionDialog(context, project.name);
        }
      } else if (!wasCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully logged $words words!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log words: $e')),
      );
    }
  }

  Future<void> _applyAllocations(
    List<TodayWritingTask> tasks,
    Map<String, int> allocations,
    int totalWords,
    String strategyLabel,
  ) async {
    final loggingService = ref.read(loggingServiceProvider);
    final List<String> newlyCompletedBooks = [];

    for (final entry in allocations.entries) {
      if (entry.value > 0) {
        try {
          final wasCompleted = await loggingService.logWords(
            projectId: entry.key,
            date: DateTime.now(),
            actualWords: entry.value,
          );
          if (wasCompleted) {
            final task = tasks.firstWhere((t) => t.project.id == entry.key);
            newlyCompletedBooks.add(task.project.name);
          }
        } catch (_) {}
      }
    }

    _refreshAll();
    
    if (newlyCompletedBooks.isNotEmpty) {
      if (context.mounted) {
        _showCompletionDialog(context, newlyCompletedBooks.join(', '));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully logged $totalWords words via $strategyLabel!')),
      );
    }
  }

  Map<String, int> _calculateEvenSplit(List<TodayWritingTask> tasks, int totalWords) {
    final count = tasks.length;
    final splitWords = totalWords ~/ count;
    final remainder = totalWords % count;
    final Map<String, int> allocations = {};
    for (int i = 0; i < count; i++) {
      allocations[tasks[i].project.id] = i == 0 ? splitWords + remainder : splitWords;
    }
    return allocations;
  }

  Map<String, int> _calculateProportionalSplit(List<TodayWritingTask> tasks, int totalWords) {
    final totalPlanned = tasks.fold<int>(0, (sum, t) => sum + t.schedule.plannedWords);
    if (totalPlanned <= 0) {
      return _calculateEvenSplit(tasks, totalWords);
    }
    final Map<String, int> allocations = {};
    int remainingToLog = totalWords;
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      int wordsToLog = 0;
      if (i == tasks.length - 1) {
        wordsToLog = remainingToLog;
      } else {
        wordsToLog = (task.schedule.plannedWords / totalPlanned * totalWords).round();
        remainingToLog -= wordsToLog;
      }
      allocations[task.project.id] = wordsToLog;
    }
    return allocations;
  }

  Map<String, int> _calculateSmartSplit(List<TodayWritingTask> tasks, int totalWords) {
    int remainingWords = totalWords;
    final Map<String, int> allocations = {for (var t in tasks) t.project.id: 0};

    // 1. Fill backlogs
    for (final t in tasks) {
      if (remainingWords <= 0) break;
      final backlog = t.project.backlogWords;
      if (backlog > 0) {
        final fill = min(backlog, remainingWords);
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + fill;
        remainingWords -= fill;
      }
    }

    // 2. Fill planned targets
    for (final t in tasks) {
      if (remainingWords <= 0) break;
      final target = t.schedule.plannedWords;
      if (target > 0) {
        final fill = min(target, remainingWords);
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + fill;
        remainingWords -= fill;
      }
    }

    // 3. Even split of remainder
    if (remainingWords > 0) {
      final split = remainingWords ~/ tasks.length;
      final rem = remainingWords % tasks.length;
      for (int i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        final add = i == 0 ? split + rem : split;
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + add;
      }
    }
    return allocations;
  }

  Future<bool?> _showSplitPreviewConfirmDialog(
    List<TodayWritingTask> tasks,
    int totalWords,
    String strategyLabel,
    Map<String, int> allocations,
  ) async {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Global Log"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Total Words: $totalWords",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                strategyLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...tasks.map((t) {
                final allocated = allocations[t.project.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.project.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "$allocated words",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: allocated > 0 ? theme.colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                "These words will be distributed as shown above.\n\nAre you sure?",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
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
  }

  void _showEditTodayLogDialog(TodayWritingTask task) {
    final controller = TextEditingController(
      text: task.log != null ? task.log!.actualWords.toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Today\'s Log for "${task.project.name}"'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Words Written Today',
              hintText: 'e.g. 500',
              suffixText: 'words',
              helperText: 'Target today: ${task.schedule.plannedWords} words',
              border: const OutlineInputBorder(),
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
                        Text("Book: ${task.project.name}"),
                        const SizedBox(height: 8),
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
                  await _submitLog(task.project.id, words, isAdditive: false);
                }
              },
              child: const Text('Continue'),
            )
          ],
        );
      },
    );
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

  void _refreshAll() {
    ref.invalidate(projectsProvider);
    ref.invalidate(statisticsProvider);
    ref.invalidate(homeQuoteProvider(null));
    ref.invalidate(homeEncouragementProvider(null));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final statsAsync = ref.watch(statisticsProvider);
    final quoteAsync = ref.watch(homeQuoteProvider(null));
    final encouragementAsync = ref.watch(homeEncouragementProvider(null));

    final String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Mission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
        },
        child: projectsAsync.when(
          data: (projects) {
            final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();
            if (activeProjects.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: _NoActiveProjectsCard(),
                  ),
                ),
              );
            }

            return FutureBuilder<List<TodayWritingTask>>(
              future: _fetchTodayTasks(activeProjects),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todayTasks = snapshot.data!;
                final rec = _computeRecommendation(activeProjects, todayTasks);
                final ProjectModel? recProject = rec['project'];

                final completedTasks = todayTasks.where((t) => t.schedule.completed).toList();
                final uncompletedTasks = todayTasks.where((t) => !t.schedule.completed).toList();

                int totalPlannedToday = 0;
                int totalLoggedToday = 0;
                for (final t in todayTasks) {
                  if (!t.schedule.isRestDay) {
                    totalPlannedToday += t.schedule.plannedWords;
                    totalLoggedToday += t.log?.actualWords ?? 0;
                  }
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grace period countdown card
                      _GracePeriodCountdownCard(todayTasks: todayTasks),

                      // Greeting & Streak row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          statsAsync.when(
                            data: (stats) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${stats.currentGlobalStreak} DAYS',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Writing Advisor Section
                      Card(
                        color: theme.colorScheme.tertiaryContainer.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.tertiary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.psychology, color: theme.colorScheme.tertiary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Writing Advisor',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Dropdown selector for strategy
                                  DropdownButton<String>(
                                    value: _selectedStrategy,
                                    items: const [
                                      DropdownMenuItem(value: 'smart', child: Text('Smart Strategy')),
                                      DropdownMenuItem(value: 'near', child: Text('Finish Near')),
                                      DropdownMenuItem(value: 'deadline', child: Text('Closest Deadline')),
                                      DropdownMenuItem(value: 'target', child: Text('High Target')),
                                      DropdownMenuItem(value: 'rotate', child: Text('Rotate Book')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedStrategy = val;
                                        });
                                      }
                                    },
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (recProject != null)
                                Row(
                                  children: [
                                    BookCoverWidget(
                                      title: recProject.name,
                                      coverImagePath: recProject.coverImagePath,
                                      coverType: recProject.coverType,
                                      width: 60,
                                      height: 80,
                                      borderRadius: 6.0,
                                      showTitle: false,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recProject.name,
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            rec['reason'] as String,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              context.go('/projects/${recProject.id}');
                                            },
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Start Writing'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.colorScheme.tertiary,
                                              foregroundColor: theme.colorScheme.onTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 56,
                                              height: 56,
                                              child: CircularProgressIndicator(
                                                value: (rec['confidence'] as int) / 100.0,
                                                backgroundColor: theme.colorScheme.surfaceVariant,
                                                color: theme.colorScheme.tertiary,
                                                strokeWidth: 6.0,
                                              ),
                                            ),
                                            Text(
                                              '${rec['confidence']}%',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.tertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'CONFIDENCE',
                                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.0),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  rec['reason'] as String,
                                  style: theme.textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Motivational Quote Card
                      quoteAsync.when(
                        data: (quote) => quote != null ? _QuoteCard(quote: quote) : const SizedBox(),
                        loading: () => const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 24),

                      // Today's Missions List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TODAY\'S MISSIONS',
                            style: theme.textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (totalPlannedToday > 0 && uncompletedTasks.isNotEmpty)
                            FilledButton.icon(
                              onPressed: () => _triggerQuickLog(todayTasks),
                              icon: const Icon(Icons.bolt, size: 16),
                              label: const Text('Quick Log'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (todayTasks.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No projects scheduled for today! Take a well-deserved break.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else if (uncompletedTasks.isEmpty)
                        Card(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 32),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Everything for today is complete.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        if (completedTasks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  completedTasks.length == 1
                                      ? '✓ 1 Project Completed Today'
                                      : '✓ ${completedTasks.length} Projects Completed Today',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: uncompletedTasks.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = uncompletedTasks[index];
                            final isRest = task.schedule.isRestDay;
                            final logged = task.log?.actualWords ?? 0;
                            final target = task.schedule.plannedWords;
                            final progress = target > 0 ? min(1.0, logged / target) : 0.0;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    BookCoverWidget(
                                      title: task.project.name,
                                      coverImagePath: task.project.coverImagePath,
                                      coverType: task.project.coverType,
                                      width: 60,
                                      height: 80,
                                      borderRadius: 6.0,
                                      showTitle: false,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.project.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (isRest)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.secondaryContainer,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                task.schedule.automaticRestDay
                                                    ? '🏝 REST DAY\n(Adaptive)'
                                                    : '🏝 REST DAY\n(Manual)',
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onSecondaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else ...[
                                            Text(
                                              task.project.projectType == ProjectType.ongoing
                                                  ? "Today's Habit"
                                                  : "Today's Goal",
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$logged / $target words',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (task.project.projectType != ProjectType.ongoing) ...[
                                              const SizedBox(height: 6),
                                              LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ],
                                          ]
                                        ],
                                      ),
                                    ),
                                    if (!isRest) ...[
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: () => _showSingleLogDialog(task),
                                        icon: const Icon(Icons.add),
                                        tooltip: 'Log words',
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 20),

                      if (totalPlannedToday > 0 && uncompletedTasks.isNotEmpty)
                        Card(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Today\'s Combined Total:',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '$totalLoggedToday / $totalPlannedToday words',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      Text(
                        'Personal Insights & Progress',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      encouragementAsync.when(
                        data: (messages) => ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: messages.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: theme.colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      messages[index].startsWith('🔥')
                                          ? Icons.local_fire_department
                                          : messages[index].startsWith('🏁')
                                              ? Icons.flag
                                              : messages[index].startsWith('🌓')
                                                  ? Icons.star_half
                                                  : messages[index].startsWith('💾')
                                                      ? Icons.save
                                                      : Icons.info_outline,
                                      color: theme.colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        messages[index],
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteModel quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${quote.text}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${quote.author}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  quote.category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontSize: 8.0,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveProjectsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.edit_note, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No Active Writing Projects',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new project to start scheduling your daily targets and writing streak!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/projects/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GracePeriodCountdownCard extends StatefulWidget {
  final List<TodayWritingTask> todayTasks;

  const _GracePeriodCountdownCard({required this.todayTasks});

  @override
  State<_GracePeriodCountdownCard> createState() => _GracePeriodCountdownCardState();
}

class _GracePeriodCountdownCardState extends State<_GracePeriodCountdownCard> {
  Timer? _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final expiration = DateTime(now.year, now.month, now.day, 5, 0, 0);
    _timeRemaining = expiration.difference(now);
    if (_timeRemaining.isNegative) {
      _timeRemaining = Duration.zero;
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Grace period is active between 12:00 AM and 5:00 AM (hour < 5)
    final isGraceActive = now.hour < 5;
    if (!isGraceActive) return const SizedBox();

    // Check if any writing task is scheduled today and not completed
    final hasUnfinished = widget.todayTasks.any((t) => !t.schedule.isRestDay && !t.schedule.completed);
    if (!hasUnfinished) return const SizedBox();

    final theme = Theme.of(context);
    return Card(
      color: Colors.amber.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Yesterday's writing has not been finalized.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Please enter your writing log.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Time Remaining: ",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        _formatDuration(_timeRemaining),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
