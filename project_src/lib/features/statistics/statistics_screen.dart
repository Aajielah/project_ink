import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/statistics.dart';
import '../../models/project.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);
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
