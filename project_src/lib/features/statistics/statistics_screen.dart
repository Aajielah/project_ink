import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/statistics.dart';
import '../../models/project.dart';
import '../../database/database.dart';

class MonthlySummary {
  final String monthLabel;
  final DateTime dateKey;
  final int wordsWritten;
  final int writingDays;
  final int restDays;
  final int bestDay;
  final int longestStreak;

  const MonthlySummary({
    required this.monthLabel,
    required this.dateKey,
    required this.wordsWritten,
    required this.writingDays,
    required this.restDays,
    required this.bestDay,
    required this.longestStreak,
  });
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  Future<Map<String, dynamic>> _fetchExtendedStats() async {
    final db = ref.read(dbProvider);
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentYearStart = DateTime(now.year, 1, 1);

    // 1. Monthly Words Written
    final monthlyLogsQuery = db.select(db.dailyLogs)
      ..where((t) => t.date.greaterOrEquals(currentMonthStart));
    final monthlyLogs = await monthlyLogsQuery.get();
    final monthlyWords = monthlyLogs.fold<int>(0, (sum, l) => sum + l.actualWords);

    // 2. Yearly Words Written
    final yearlyLogsQuery = db.select(db.dailyLogs)
      ..where((t) => t.date.greaterOrEquals(currentYearStart));
    final yearlyLogs = await yearlyLogsQuery.get();
    final yearlyWords = yearlyLogs.fold<int>(0, (sum, l) => sum + l.actualWords);

    // 3. Automatic Rest Days count
    final autoRestQuery = db.select(db.schedules)
      ..where((t) => t.isRestDay.equals(true) & t.automaticRestDay.equals(true));
    final autoRestRows = await autoRestQuery.get();
    final autoRestDays = autoRestRows.length;

    // 4. Compile Monthly summaries reports list
    final allLogs = await db.select(db.dailyLogs).get();
    final allSchedules = await db.select(db.schedules).get();

    final Map<DateTime, List<DailyLog>> logsByMonth = {};
    for (final log in allLogs) {
      final key = DateTime(log.date.year, log.date.month);
      logsByMonth.putIfAbsent(key, () => []).add(log);
    }

    final Map<DateTime, List<Schedule>> schedsByMonth = {};
    for (final sched in allSchedules) {
      final key = DateTime(sched.date.year, sched.date.month);
      schedsByMonth.putIfAbsent(key, () => []).add(sched);
    }

    final List<MonthlySummary> summaries = [];

    logsByMonth.forEach((key, logs) {
      final label = DateFormat('MMMM yyyy').format(key);
      final words = logs.fold<int>(0, (sum, l) => sum + l.actualWords);
      final writingDays = logs.where((l) => l.actualWords > 0).length;

      int best = 0;
      for (final l in logs) {
        if (l.actualWords > best) best = l.actualWords;
      }

      final scheds = schedsByMonth[key] ?? [];
      final restDays = scheds.where((s) => s.isRestDay).length;

      // Calculate longest streak in this month
      logs.sort((a, b) => a.date.compareTo(b.date));
      int currentStreak = 0;
      int maxStreak = 0;
      DateTime? prevDate;

      for (final l in logs) {
        if (l.completed) {
          if (prevDate == null) {
            currentStreak = 1;
          } else {
            final diff = l.date.difference(prevDate).inDays;
            if (diff == 1) {
              currentStreak++;
            } else if (diff > 1) {
              currentStreak = 1;
            }
          }
          prevDate = l.date;
          if (currentStreak > maxStreak) maxStreak = currentStreak;
        } else {
          final scheduleForLog = scheds.firstWhere(
            (s) => s.id == l.scheduleId,
            orElse: () => scheds.firstWhere((s) => s.date.day == l.date.day),
          );
          if (scheduleForLog.isRestDay) {
            prevDate = l.date;
          } else {
            currentStreak = 0;
            prevDate = null;
          }
        }
      }

      summaries.add(MonthlySummary(
        monthLabel: label,
        dateKey: key,
        wordsWritten: words,
        writingDays: writingDays,
        restDays: restDays,
        bestDay: best,
        longestStreak: maxStreak,
      ));
    });

    summaries.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    return {
      'monthlyWords': monthlyWords,
      'yearlyWords': yearlyWords,
      'autoRestDays': autoRestDays,
      'summaries': summaries,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Insights'),
      ),
      body: statsAsync.when(
        data: (stats) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchExtendedStats(),
            builder: (context, snapshot) {
              final dynamicStats = snapshot.data ?? {
                'monthlyWords': 0,
                'yearlyWords': 0,
                'autoRestDays': 0,
                'summaries': <MonthlySummary>[],
              };

              final monthlyWords = dynamicStats['monthlyWords'] as int;
              final yearlyWords = dynamicStats['yearlyWords'] as int;
              final summaries = dynamicStats['summaries'] as List<MonthlySummary>;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(statisticsProvider);
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lifetime Overview Card
                      Card(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 40, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Lifetime Words Written',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                NumberFormat('#,###').format(stats.lifetimeWords),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        NumberFormat('#,###').format(monthlyWords),
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'This Month',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        NumberFormat('#,###').format(yearlyWords),
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'This Year',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Highlights Grid
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Automatic Rest Days',
                          value: '${dynamicStats['autoRestDays']} days',
                          icon: Icons.hotel_class_outlined,
                          backgroundColor: Colors.indigo.withOpacity(0.08),
                          borderColor: Colors.indigo.withOpacity(0.2),
                          iconColor: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Manual Rest Days',
                          value: '${stats.restDaysUsed} days',
                          icon: Icons.beach_access,
                          backgroundColor: Colors.cyan.withOpacity(0.08),
                          borderColor: Colors.cyan.withOpacity(0.2),
                          iconColor: Colors.cyan,
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
                  const SizedBox(height: 24),

                  // Monthly Summaries list
                  if (summaries.isNotEmpty) ...[
                    Text(
                      'Monthly Summaries',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      summary.monthLabel,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${NumberFormat('#,###').format(summary.wordsWritten)} words',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _SummaryMiniStat(label: 'Writing Days', value: '${summary.writingDays}d'),
                                    _SummaryMiniStat(label: 'Rest Days', value: '${summary.restDays}d'),
                                    _SummaryMiniStat(label: 'Best Day', value: '${NumberFormat('#,###').format(summary.bestDay)}w'),
                                    _SummaryMiniStat(label: 'Streak', value: '${summary.longestStreak}d'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
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

class _SummaryMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
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
