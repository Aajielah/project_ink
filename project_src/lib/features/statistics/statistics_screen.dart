import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/statistics.dart';
import '../../models/project.dart';
import '../projects/widgets/book_cover_widget.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedStrategy = 'smart';

  Map<String, dynamic> _computeRecommendation(List<ProjectModel> activeProjects) {
    if (activeProjects.isEmpty) {
      return {
        'name': 'No Active Projects',
        'reason': 'Create or resume a writing project to receive custom advisor recommendations.',
        'confidence': 0,
        'project': null,
      };
    }

    // Helper: calculate progress ratio
    double getProgress(ProjectModel p) => p.targetWords > 0 ? p.writtenWords / p.targetWords : 0.0;

    switch (_selectedStrategy) {
      case 'near':
        // Sort by progress descending (but not 1.0 completed)
        final unfinished = activeProjects.where((p) => getProgress(p) < 1.0).toList();
        if (unfinished.isEmpty) break;
        unfinished.sort((a, b) => getProgress(b).compareTo(getProgress(a)));
        final p = unfinished.first;
        return {
          'name': p.name,
          'reason': 'This book is nearest to completion (${(getProgress(p)*100).toInt()}%). Focus here to cross the finish line!',
          'confidence': 90,
          'project': p,
        };

      case 'deadline':
        // Sort by expectedFinishDate ascending
        final list = List<ProjectModel>.from(activeProjects);
        list.sort((a, b) => a.expectedFinishDate.compareTo(b.expectedFinishDate));
        final p = list.first;
        return {
          'name': p.name,
          'reason': 'This manuscript has the earliest expected finish date (${DateFormat('MMM d').format(p.expectedFinishDate)}). Stay on schedule!',
          'confidence': 85,
          'project': p,
        };

      case 'target':
        // Sort by daily target descending
        final list = List<ProjectModel>.from(activeProjects);
        list.sort((a, b) => b.dailyWordTarget.compareTo(a.dailyWordTarget));
        final p = list.first;
        return {
          'name': p.name,
          'reason': 'This project requires the highest daily output (${p.dailyWordTarget} words/day) to stay on path.',
          'confidence': 80,
          'project': p,
        };

      case 'rotate':
        // Sort by updatedAt ascending (least recently edited)
        final list = List<ProjectModel>.from(activeProjects);
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        final p = list.first;
        return {
          'name': p.name,
          'reason': 'You haven\'t logged words here recently. Rotate back to keep the narrative draft fresh!',
          'confidence': 75,
          'project': p,
        };

      case 'smart':
      default:
        // Heuristic smart recommendation:
        // 1. Backlog first
        final backlogged = activeProjects.where((p) => p.backlogWords > 0).toList();
        if (backlogged.isNotEmpty) {
          backlogged.sort((a, b) => b.backlogWords.compareTo(a.backlogWords));
          final p = backlogged.first;
          return {
            'name': p.name,
            'reason': 'Urgent: This book has a backlog of ${p.backlogWords} words. Clean this first to secure your writing schedule!',
            'confidence': 98,
            'project': p,
          };
        }
        // 2. Near finish (progress > 80%)
        final highProgress = activeProjects.where((p) => getProgress(p) >= 0.8 && getProgress(p) < 1.0).toList();
        if (highProgress.isNotEmpty) {
          highProgress.sort((a, b) => getProgress(b).compareTo(getProgress(a)));
          final p = highProgress.first;
          return {
            'name': p.name,
            'reason': 'Highly Recommended: Crossed the 80% mark (${(getProgress(p)*100).toInt()}% done). Focus on final drafting!',
            'confidence': 92,
            'project': p,
          };
        }
        // 3. Closest deadline
        final list = List<ProjectModel>.from(activeProjects);
        list.sort((a, b) => a.expectedFinishDate.compareTo(b.expectedFinishDate));
        final p = list.first;
        return {
          'name': p.name,
          'reason': 'Priority schedule: Closest upcoming deadline (${DateFormat('MMM d').format(p.expectedFinishDate)}).',
          'confidence': 88,
          'project': p,
        };
    }

    final p = activeProjects.first;
    return {
      'name': p.name,
      'reason': 'Keep your daily writing streak active on this book!',
      'confidence': 70,
      'project': p,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Insights'),
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(statisticsProvider);
              ref.invalidate(projectsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Writing Advisor Section
                  projectsAsync.when(
                    data: (projects) {
                      final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();
                      final rec = _computeRecommendation(activeProjects);
                      final ProjectModel? recProject = rec['project'];

                      return Card(
                        color: theme.colorScheme.tertiaryContainer.withOpacity(0.2),
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
                                      Icon(Icons.auto_awesome, color: theme.colorScheme.tertiary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Writing Advisor',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedStrategy,
                                    dropdownColor: theme.colorScheme.surface,
                                    underline: const SizedBox(),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'smart', child: Text('🧠 Smart Recommendation')),
                                      DropdownMenuItem(value: 'near', child: Text('🏁 Finish Near Completion')),
                                      DropdownMenuItem(value: 'deadline', child: Text('📅 Earliest Deadline')),
                                      DropdownMenuItem(value: 'target', child: Text('🚀 Highest Daily Target')),
                                      DropdownMenuItem(value: 'rotate', child: Text('🔄 Rotate Projects')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedStrategy = val;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              if (recProject != null)
                                Row(
                                  children: [
                                    // Mini procedural cover of recommended project
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
                                            'RECOMMENDED FOCUS:',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.tertiary,
                                            ),
                                          ),
                                          Text(
                                            rec['name'] as String,
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            rec['reason'] as String,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Confidence score gauge
                                    Column(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 46,
                                              height: 46,
                                              child: CircularProgressIndicator(
                                                value: (rec['confidence'] as int) / 100.0,
                                                color: theme.colorScheme.tertiary,
                                                backgroundColor: theme.colorScheme.tertiary.withOpacity(0.15),
                                                strokeWidth: 4,
                                              ),
                                            ),
                                            Text(
                                              '${rec['confidence']}%',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onTertiaryContainer,
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
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),

                  // Lifetime Overview Card
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 44, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Lifetime Words Written',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat('#,###').format(stats.lifetimeWords),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Highlights Grid (Harmonious color-coded cards)
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Daily Average',
                          value: '${stats.averageWordsPerDay.toStringAsFixed(0)} words',
                          icon: Icons.trending_up,
                          backgroundColor: Colors.blue.withOpacity(0.08),
                          borderColor: Colors.blue.withOpacity(0.2),
                          iconColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Writing Days',
                          value: '${stats.writingDays} days',
                          icon: Icons.edit_calendar,
                          backgroundColor: Colors.teal.withOpacity(0.08),
                          borderColor: Colors.teal.withOpacity(0.2),
                          iconColor: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Global Streak',
                          value: '${stats.currentGlobalStreak} days',
                          icon: Icons.local_fire_department,
                          backgroundColor: Colors.orange.withOpacity(0.08),
                          borderColor: Colors.orange.withOpacity(0.2),
                          iconColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Longest Streak',
                          value: '${stats.longestGlobalStreak} days',
                          icon: Icons.workspace_premium,
                          backgroundColor: Colors.purple.withOpacity(0.08),
                          borderColor: Colors.purple.withOpacity(0.2),
                          iconColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Completed Books',
                          value: '${stats.projectsCompleted}',
                          icon: Icons.task_alt,
                          backgroundColor: Colors.green.withOpacity(0.08),
                          borderColor: Colors.green.withOpacity(0.2),
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Current Backlog',
                          value: '${stats.currentBacklog} words',
                          icon: Icons.assignment_late_outlined,
                          backgroundColor: Colors.red.withOpacity(0.08),
                          borderColor: Colors.red.withOpacity(0.2),
                          iconColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 7-day activity chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Writing Activity (Last 7 Days)',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: _WeeklyChart(ref: ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading stats: $err')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final WidgetRef ref;

  const _WeeklyChart({required this.ref});

  Future<List<Map<String, dynamic>>> _fetchWeeklyData() async {
    final db = ref.read(dbProvider);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);
    
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = cleanToday.subtract(Duration(days: i));
      
      final query = db.select(db.dailyLogs)..where((t) => t.date.equals(date));
      final logs = await query.get();
      
      int wordsOnDate = 0;
      for (final log in logs) {
        wordsOnDate += log.actualWords;
      }
      
      data.add({
        'dayLabel': DateFormat('E').format(date),
        'words': wordsOnDate,
      });
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchWeeklyData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chartData = snapshot.data!;
        
        int maxWords = 500;
        for (final item in chartData) {
          if (item['words'] > maxWords) {
            maxWords = item['words'] as int;
          }
        }
        final double maxY = ((maxWords / 500).ceil() * 500).toDouble();

        return BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxY || value == maxY / 2) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < chartData.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          chartData[index]['dayLabel'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(chartData.length, (index) {
              final words = (chartData[index]['words'] as int).toDouble();
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: words,
                    color: theme.colorScheme.primary,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
