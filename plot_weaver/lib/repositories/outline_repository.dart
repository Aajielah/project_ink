import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class OutlineRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  OutlineRepository(this._db);

  Stream<List<Chapter>> watchChapters(String universeId) {
    return (_db.select(_db.chapters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([(c) => OrderingTerm(expression: c.orderIndex, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<Chapter>> getChapters(String universeId) {
    return (_db.select(_db.chapters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([(c) => OrderingTerm(expression: c.orderIndex, mode: OrderingMode.asc)]))
        .get();
  }

  Stream<List<Scene>> watchScenesForChapter(String chapterId) {
    return (_db.select(_db.scenes)
          ..where((s) => s.chapterId.equals(chapterId))
          ..orderBy([(s) => OrderingTerm(expression: s.orderIndex, mode: OrderingMode.asc)]))
        .watch();
  }

  Stream<List<Scene>> watchAllScenes(String universeId) {
    return (_db.select(_db.scenes)
          ..where((s) => s.universeId.equals(universeId))
          ..orderBy([(s) => OrderingTerm(expression: s.orderIndex, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<Chapter> createChapter({
    required String universeId,
    required String title,
    String act = 'Act I',
    String? objective,
    int estimatedWordCount = 2500,
    String status = 'Outlined',
    String? notes,
  }) async {
    final chapters = await getChapters(universeId);
    final nextOrder = chapters.length;
    final chapterNumber = chapters.length + 1;
    final now = DateTime.now();

    final companion = ChaptersCompanion(
      id: Value(_uuid.v4()),
      universeId: Value(universeId),
      chapterNumber: Value(chapterNumber),
      act: Value(act),
      title: Value(title.trim()),
      objective: Value(objective?.trim()),
      estimatedWordCount: Value(estimatedWordCount),
      status: Value(status),
      orderIndex: Value(nextOrder),
      notes: Value(notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    return await _db.into(_db.chapters).insertReturning(companion);
  }

  Future<void> updateChapter({
    required String id,
    required String title,
    required String act,
    String? objective,
    required int estimatedWordCount,
    required String status,
    String? notes,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.chapters)..where((c) => c.id.equals(id))).write(
      ChaptersCompanion(
        title: Value(title.trim()),
        act: Value(act),
        objective: Value(objective?.trim()),
        estimatedWordCount: Value(estimatedWordCount),
        status: Value(status),
        notes: Value(notes?.trim()),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteChapter(String id) async {
    await (_db.delete(_db.chapters)..where((c) => c.id.equals(id))).go();
  }

  Future<void> reorderChapters(String universeId, List<String> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.chapters)..where((c) => c.id.equals(orderedIds[i]))).write(
          ChaptersCompanion(
            orderIndex: Value(i),
            chapterNumber: Value(i + 1),
          ),
        );
      }
    });
  }

  Future<Scene> createScene({
    required String chapterId,
    required String universeId,
    required String title,
    String? summary,
    String? povCharacterId,
    String? locationName,
    int tensionLevel = 5,
    String status = 'Outlined',
  }) async {
    final existingScenes = await (_db.select(_db.scenes)
          ..where((s) => s.chapterId.equals(chapterId))
          ..orderBy([(s) => OrderingTerm(expression: s.orderIndex, mode: OrderingMode.asc)]))
        .get();

    final nextOrder = existingScenes.length;
    final sceneNumber = existingScenes.length + 1;
    final now = DateTime.now();

    final companion = ScenesCompanion(
      id: Value(_uuid.v4()),
      chapterId: Value(chapterId),
      universeId: Value(universeId),
      sceneNumber: Value(sceneNumber),
      title: Value(title.trim()),
      summary: Value(summary?.trim()),
      povCharacterId: Value(povCharacterId),
      locationName: Value(locationName?.trim()),
      tensionLevel: Value(tensionLevel.clamp(1, 10)),
      status: Value(status),
      orderIndex: Value(nextOrder),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    return await _db.into(_db.scenes).insertReturning(companion);
  }

  Future<void> updateScene({
    required String id,
    required String title,
    String? summary,
    String? povCharacterId,
    String? locationName,
    required int tensionLevel,
    required String status,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.scenes)..where((s) => s.id.equals(id))).write(
      ScenesCompanion(
        title: Value(title.trim()),
        summary: Value(summary?.trim()),
        povCharacterId: Value(povCharacterId),
        locationName: Value(locationName?.trim()),
        tensionLevel: Value(tensionLevel.clamp(1, 10)),
        status: Value(status),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteScene(String id) async {
    await (_db.delete(_db.scenes)..where((s) => s.id.equals(id))).go();
  }

  Future<void> reorderScenes(String chapterId, List<String> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.scenes)..where((s) => s.id.equals(orderedIds[i]))).write(
          ScenesCompanion(
            orderIndex: Value(i),
            sceneNumber: Value(i + 1),
          ),
        );
      }
    });
  }

  /// Populates classic story beat templates with chapters & scenes
  Future<void> applyTemplate(String universeId, String templateName) async {
    final templates = _getTemplateDefinitions(templateName);
    for (final beat in templates) {
      final chapter = await createChapter(
        universeId: universeId,
        act: beat.act,
        title: beat.title,
        objective: beat.objective,
        estimatedWordCount: beat.words,
      );

      for (final sceneTitle in beat.initialScenes) {
        await createScene(
          chapterId: chapter.id,
          universeId: universeId,
          title: sceneTitle,
          tensionLevel: beat.defaultTension,
        );
      }
    }
  }

  List<_TemplateBeat> _getTemplateDefinitions(String templateName) {
    if (templateName == 'save_the_cat') {
      return [
        _TemplateBeat('Act I', 'Opening Image', 'Establish the "before" snapshot of the protagonist and their world.', 2000, 3, ['The Ordinary World snapshot', 'A glimpse of the internal flaw']),
        _TemplateBeat('Act I', 'Theme Stated', 'A secondary character mentions the moral truth or life lesson.', 2500, 4, ['Encounter with a mentor or truth-teller']),
        _TemplateBeat('Act I', 'The Set-Up', 'Explore protagonist daily stakes, goals, and reluctance.', 3000, 4, ['Show what is at risk if nothing changes']),
        _TemplateBeat('Act I', 'The Catalyst (Inciting Incident)', 'An external event shatters the status quo beyond repair.', 2500, 7, ['The disruptive event strikes', 'Initial reaction and shock']),
        _TemplateBeat('Act I', 'The Debate', 'Protagonist hesitates or attempts to resist the call to adventure.', 2500, 6, ['Weighing the cost of taking action']),
        _TemplateBeat('Act IIA', 'Break into Two', 'Protagonist crosses the threshold into the unfamiliar upside-down world.', 3000, 7, ['Crossing the point of no return']),
        _TemplateBeat('Act IIA', 'B Story Introduction', 'Introduction of love interest, rival, or companion who embodies the theme.', 2500, 5, ['Meeting the foil or unexpected ally']),
        _TemplateBeat('Act IIA', 'Fun & Games (The Promise of the Premise)', 'The core hook of the genre plays out in full force.', 4000, 6, ['Navigating the new territory', 'First small taste of victory']),
        _TemplateBeat('Act IIB', 'The Midpoint', 'A false victory or false defeat shifts the stakes from want to need.', 3500, 8, ['The stakes are dramatically raised', 'The clock starts ticking']),
        _TemplateBeat('Act IIB', 'Bad Guys Close In', 'Antagonistic forces regroup; internal doubts threaten the team.', 3500, 8, ['Doubt within the ranks', 'External pressure tightens']),
        _TemplateBeat('Act IIB', 'All Hope is Lost', 'A devastating loss (literal or figurative death); darkest moment.', 2500, 9, ['The mentor or plan falls apart']),
        _TemplateBeat('Act IIB', 'Dark Night of the Soul', 'Grieving the loss and discovering the true internal transformation.', 2500, 7, ['Staring into the abyss before revelation']),
        _TemplateBeat('Act III', 'Break into Three', 'A newly realized truth sparks an inspired, unconventional solution.', 2500, 8, ['The epiphany and rallying cry']),
        _TemplateBeat('Act III', 'The Finale', 'Executing the final plan, confronting the antagonist, sacrificing the flaw.', 4500, 10, ['The final assault', 'Facing the shadow', 'Triumph through truth']),
        _TemplateBeat('Act III', 'Final Image', 'The "after" snapshot showing how the hero and world are forever transformed.', 2000, 3, ['A new dawn in the changed world']),
      ];
    } else {
      // Classic Three-Act Structure (Default)
      return [
        _TemplateBeat('Act I', 'The Hook & Normal World', 'Introduce the protagonist and the world before disruption.', 3000, 4, ['Everyday status quo', 'Seeds of unrest']),
        _TemplateBeat('Act I', 'Inciting Incident', 'The call to adventure disrupts everything.', 3000, 7, ['The unexpected call']),
        _TemplateBeat('Act I', 'Plot Point 1', 'The commitment to the journey; leaving the comfort zone.', 3000, 7, ['Crossing the threshold']),
        _TemplateBeat('Act IIA', 'Rising Action & Tests', 'First encounters with obstacles and allies.', 4000, 6, ['Gathering clues/resources', 'First clash with the enemy']),
        _TemplateBeat('Act IIB', 'The Midpoint Reversal', 'Major plot twist changes the nature of the quest.', 4000, 8, ['The twist revealed', 'A new strategy is required']),
        _TemplateBeat('Act IIB', 'Crisis & Low Point', 'The defeat that tests resolve.', 3500, 9, ['The worst-case scenario unfolds']),
        _TemplateBeat('Act III', 'The Climax', 'The final showdown where the core conflict is decided.', 5000, 10, ['Direct confrontation', 'Sacrifice and resolution']),
        _TemplateBeat('Act III', 'Resolution & Denouement', 'The aftermath and new baseline.', 2500, 3, ['Tying up loose threads', 'The path forward']),
      ];
    }
  }
}

class _TemplateBeat {
  final String act;
  final String title;
  final String objective;
  final int words;
  final int defaultTension;
  final List<String> initialScenes;

  _TemplateBeat(
    this.act,
    this.title,
    this.objective,
    this.words,
    this.defaultTension,
    this.initialScenes,
  );
}
