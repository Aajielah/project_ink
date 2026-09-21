import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'project_ink_bridge_summary.dart';

export 'project_ink_bridge_summary.dart';

class ProjectInkBridgeRepository {
  Future<bool> isProjectInkInstalled() async {
    try {
      final dbFile = await _getInkDatabaseFile();
      return dbFile != null && await dbFile.exists();
    } catch (_) {
      return false;
    }
  }

  Future<File?> _getInkDatabaseFile() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(p.join(docs.path, 'project_ink.sqlite'));
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<List<ProjectInkBookSummary>> fetchAvailableInkBooks() async {
    try {
      final file = await _getInkDatabaseFile();
      if (file == null || !await file.exists()) {
        return [];
      }

      final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
      try {
        final ResultSet result = db.select(
          'SELECT id, name, target_words, written_words, project_streak, status FROM projects ORDER BY updated_at DESC',
        );

        final books = <ProjectInkBookSummary>[];
        for (final row in result) {
          books.add(
            ProjectInkBookSummary(
              id: row['id'] as String,
              name: row['name'] as String,
              targetWords: (row['target_words'] as int?) ?? 0,
              writtenWords: (row['written_words'] as int?) ?? 0,
              streak: (row['project_streak'] as int?) ?? 0,
              status: (row['status'] as String?) ?? 'Active',
            ),
          );
        }
        return books;
      } finally {
        db.dispose();
      }
    } catch (_) {
      return [];
    }
  }

  Future<ProjectInkBookSummary?> getLinkedBookSummary(String projectId) async {
    try {
      final books = await fetchAvailableInkBooks();
      for (final book in books) {
        if (book.id == projectId) return book;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
