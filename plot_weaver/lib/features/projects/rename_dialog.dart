import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RenameDialog extends StatefulWidget {
  final String currentTitle;
  final String headingType; // e.g. "Chapter", "Arc", "Custom Section", "Project"

  const RenameDialog({
    required this.currentTitle,
    required this.headingType,
    super.key,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentTitle,
    required String headingType,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => RenameDialog(
        currentTitle: currentTitle,
        headingType: headingType,
      ),
    );
  }

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.amberGold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Rename ${widget.headingType}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '${widget.headingType} Title',
                  hintText: 'Enter new title...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _controller.clear(),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amberGold,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _submit,
                    child: const Text('Save Title'),
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
