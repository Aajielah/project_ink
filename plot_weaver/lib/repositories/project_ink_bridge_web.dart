import 'project_ink_bridge_summary.dart';

export 'project_ink_bridge_summary.dart';

class ProjectInkBridgeRepository {
  Future<bool> isProjectInkInstalled() async {
    // Project Ink's local SQLite database is not directly accessible from a Web sandbox.
    return false;
  }

  Future<List<ProjectInkBookSummary>> fetchAvailableInkBooks() async {
    return [];
  }

  Future<ProjectInkBookSummary?> getLinkedBookSummary(String projectId) async {
    return null;
  }
}
