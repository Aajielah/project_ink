import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/daily_record.dart';
import '../../../shared/models/pause.dart';
import '../../../shared/models/target_change_log.dart';

class ProjectHistoryPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectHistoryPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectHistoryPage> createState() => _ProjectHistoryPageState();
}

class _ProjectHistoryPageState extends ConsumerState<ProjectHistoryPage> {
  Project? _project;
  List<DailyRecord> _records = [];
  List<Pause> _pauses = [];
  List<TargetChangeLog> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final id = int.tryParse(widget.projectId);
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final db = ref.read(databaseServiceProvider);
    final project = await db.getProject(id);
    if (project != null && mounted) {
      final records = await db.getRecordsForProject(id);
      records.sort((a, b) => b.date.compareTo(a.date)); // Newest first

      final pauses = await db.getPausesForProject(id);
      pauses.sort((a, b) => b.startDate.compareTo(a.startDate));

      final logs = await db.getLogsForProject(id);
      logs.sort((a, b) => b.dateChanged.compareTo(a.dateChanged));

      setState(() {
        _project = project;
        _records = records;
        _pauses = pauses;
        _logs = logs;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DailyRecord> get _filteredRecords {
    if (_selectedFilter == 'Completed') {
      return _records.where((r) => r.status == 'completed').toList();
    } else if (_selectedFilter == 'Missed') {
      return _records.where((r) => r.status == 'missed').toList();
    }
    return _records;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal History')),
        body: const Center(child: Text('Goal not found.')),
      );
    }

    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getColor(_project!.category, context);
    final completedCount = _records.where((r) => r.status == 'completed').length;
    final missedCount = _records.where((r) => r.status == 'missed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal History & Log'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(CategoryUtils.getIcon(_project!.category), color: categoryColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_project!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount Completed  •  $missedCount Missed',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Target Revisions Section (if any)
          if (_logs.isNotEmpty) ...[
            Text('Target Revisions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final log = _logs[i];
                  return ListTile(
                    leading: const Icon(Icons.edit_calendar_rounded, color: Colors.blue),
                    title: Text('Changed target from ${log.oldTarget} to ${log.newTarget} days'),
                    subtitle: Text(DurationUtils.formatDate(log.dateChanged)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Pauses Section (if any)
          if (_pauses.isNotEmpty) ...[
            Text('Pause Intervals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pauses.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final pause = _pauses[i];
                  final endStr = pause.endDate != null ? DurationUtils.formatDate(pause.endDate!) : 'Ongoing';
                  return ListTile(
                    leading: const Icon(Icons.pause_circle_outline_rounded, color: Colors.amber),
                    title: Text('${DurationUtils.formatDate(pause.startDate)} – $endStr'),
                    subtitle: pause.reason != null ? Text('Reason: ${pause.reason}') : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Timeline', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Records')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed Only')),
                  DropdownMenuItem(value: 'Missed', child: Text('Missed Only')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedFilter = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Daily Records List
          if (_filteredRecords.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No daily records recorded yet.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ] else ...[
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRecords.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final r = _filteredRecords[i];
                  final isCompleted = r.status == 'completed';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.close_rounded,
                        color: isCompleted ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(DurationUtils.formatDate(r.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: r.automatic
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('AUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
