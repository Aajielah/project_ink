import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers.dart';

class ExportDialog extends ConsumerStatefulWidget {
  final String universeId;
  final String universeTitle;

  const ExportDialog({
    required this.universeId,
    required this.universeTitle,
    super.key,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExport();
  }

  Future<void> _loadExport() async {
    try {
      final service = ref.read(exportServiceProvider);
      final md = await service.generateMarkdownBible(widget.universeId);
      if (mounted) {
        setState(() {
          _markdownContent = md;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_markdownContent == null) return;
    Clipboard.setData(ClipboardData(text: _markdownContent!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story Bible copied to clipboard! Ready for Obsidian, Scrivener, or Notion.'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: AppColors.amberGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Story Bible',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.universeTitle} • Markdown Format',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text('Error generating export: $_error'))
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _markdownContent!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _markdownContent != null
                        ? '${_markdownContent!.split('\n').length} lines • ${_markdownContent!.length} characters'
                        : '',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _markdownContent == null ? null : _copyToClipboard,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Markdown'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.amberGold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
