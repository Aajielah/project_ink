import 'package:drift/drift.dart';
import '../database/app_database.dart';

class ExportService {
  final AppDatabase _db;

  ExportService(this._db);

  Future<String> generateMarkdownBible(String universeId) async {
    final universe = await (_db.select(_db.universes)..where((u) => u.id.equals(universeId))).getSingleOrNull();
    if (universe == null) {
      throw Exception('Universe not found');
    }

    final chapters = await (_db.select(_db.chapters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([(c) => OrderingTerm(expression: c.orderIndex, mode: OrderingMode.asc)]))
        .get();

    final scenes = await (_db.select(_db.scenes)
          ..where((s) => s.universeId.equals(universeId))
          ..orderBy([(s) => OrderingTerm(expression: s.orderIndex, mode: OrderingMode.asc)]))
        .get();

    final characters = await (_db.select(_db.characters)
          ..where((c) => c.universeId.equals(universeId))
          ..orderBy([(c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc)]))
        .get();

    final relationships = await (_db.select(_db.characterRelationships)
          ..where((r) => r.universeId.equals(universeId)))
        .get();

    final loreEntries = await (_db.select(_db.loreEntries)
          ..where((l) => l.universeId.equals(universeId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.category, mode: OrderingMode.asc),
            (l) => OrderingTerm(expression: l.title, mode: OrderingMode.asc),
          ]))
        .get();

    final sparks = await (_db.select(_db.ideaSparks)
          ..where((s) => s.universeId.equals(universeId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.isPinned, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ]))
        .get();

    // Map character ID to name for easy lookup
    final charMap = {for (final c in characters) c.id: c.name};

    // Group scenes by chapter
    final scenesByChapter = <String, List<Scene>>{};
    for (final s in scenes) {
      scenesByChapter.putIfAbsent(s.chapterId, () => []).add(s);
    }

    // Group lore by category
    final loreByCategory = <String, List<LoreEntry>>{};
    for (final l in loreEntries) {
      loreByCategory.putIfAbsent(l.category, () => []).add(l);
    }

    final buffer = StringBuffer();

    // Title & Metadata
    buffer.writeln('# Story Bible: ${universe.title}');
    buffer.writeln('**Genre:** ${universe.genre}  ');
    if (universe.logline != null && universe.logline!.isNotEmpty) {
      buffer.writeln('**Logline:** *${universe.logline}*  ');
    }
    buffer.writeln('**Exported:** ${DateTime.now().toLocal().toString().split('.').first}  ');
    buffer.writeln();

    if (universe.synopsis != null && universe.synopsis!.isNotEmpty) {
      buffer.writeln('## Synopsis');
      buffer.writeln(universe.synopsis);
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    // SECTION 1: OUTLINE & CHAPTERS
    buffer.writeln('## 1. Chapter & Scene Outline');
    buffer.writeln();
    if (chapters.isEmpty) {
      buffer.writeln('*No chapters outlined yet.*');
    } else {
      for (final ch in chapters) {
        buffer.writeln('### Chapter ${ch.chapterNumber}: ${ch.title}');
        buffer.writeln('**Act:** ${ch.act} | **Status:** ${ch.status} | **Target Words:** ${ch.estimatedWordCount}');
        if (ch.objective != null && ch.objective!.isNotEmpty) {
          buffer.writeln('**Chapter Objective:** ${ch.objective}');
        }
        buffer.writeln();

        final chScenes = scenesByChapter[ch.id] ?? [];
        if (chScenes.isNotEmpty) {
          buffer.writeln('| Scene # | Title | POV Character | Location | Tension | Status | Summary |');
          buffer.writeln('| :---: | :--- | :--- | :--- | :---: | :---: | :--- |');
          for (final sc in chScenes) {
            final povName = sc.povCharacterId != null ? (charMap[sc.povCharacterId] ?? 'Unknown') : '-';
            final loc = sc.locationName ?? '-';
            final tensionBar = '${sc.tensionLevel}/10';
            final summaryClean = (sc.summary ?? '-').replaceAll('\n', ' ').replaceAll('|', '/');
            buffer.writeln('| ${sc.sceneNumber} | ${sc.title} | $povName | $loc | $tensionBar | ${sc.status} | $summaryClean |');
          }
          buffer.writeln();
        }
      }
    }

    buffer.writeln('---');
    buffer.writeln();

    // SECTION 2: CHARACTERS
    buffer.writeln('## 2. Character Dossiers');
    buffer.writeln();
    if (characters.isEmpty) {
      buffer.writeln('*No character dossiers created yet.*');
    } else {
      for (final char in characters) {
        buffer.writeln('### ${char.name}${char.alias != null && char.alias!.isNotEmpty ? ' ("${char.alias}")' : ''}');
        buffer.writeln('- **Role:** ${char.role}');
        if (char.archetype != null && char.archetype!.isNotEmpty) {
          buffer.writeln('- **Archetype:** ${char.archetype}');
        }
        if (char.age != null && char.age!.isNotEmpty) {
          buffer.writeln('- **Age:** ${char.age}');
        }
        if (char.occupation != null && char.occupation!.isNotEmpty) {
          buffer.writeln('- **Occupation:** ${char.occupation}');
        }
        if (char.arcStage.isNotEmpty) {
          buffer.writeln('- **Arc Stage:** ${char.arcStage}');
        }

        // Psychological Profile
        if ((char.motivation != null && char.motivation!.isNotEmpty) ||
            (char.flaw != null && char.flaw!.isNotEmpty) ||
            (char.internalConflict != null && char.internalConflict!.isNotEmpty)) {
          buffer.writeln();
          buffer.writeln('#### Psychological Depth');
          if (char.motivation != null && char.motivation!.isNotEmpty) {
            buffer.writeln('- **Core Motivation / Desire:** ${char.motivation}');
          }
          if (char.flaw != null && char.flaw!.isNotEmpty) {
            buffer.writeln('- **Fatal Flaw / Blindspot:** ${char.flaw}');
          }
          if (char.internalConflict != null && char.internalConflict!.isNotEmpty) {
            buffer.writeln('- **Internal Conflict:** ${char.internalConflict}');
          }
        }

        // Backstory
        if (char.backstory != null && char.backstory!.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('#### Backstory');
          buffer.writeln(char.backstory);
        }

        // Relationships for this character
        final charRels = relationships.where((r) => r.sourceCharacterId == char.id).toList();
        if (charRels.isNotEmpty) {
          buffer.writeln();
          buffer.writeln('#### Key Relationships');
          for (final rel in charRels) {
            final targetName = charMap[rel.targetCharacterId] ?? 'Unknown Character';
            final desc = rel.description != null && rel.description!.isNotEmpty ? ' — *${rel.description}*' : '';
            buffer.writeln('- **${rel.relationType}** with **$targetName**$desc');
          }
        }

        buffer.writeln();
      }
    }

    buffer.writeln('---');
    buffer.writeln();

    // SECTION 3: WORLD LORE CODEX
    buffer.writeln('## 3. World Lore Codex');
    buffer.writeln();
    if (loreEntries.isEmpty) {
      buffer.writeln('*No codex entries recorded yet.*');
    } else {
      for (final cat in loreByCategory.keys) {
        buffer.writeln('### Category: $cat');
        buffer.writeln();
        for (final entry in loreByCategory[cat]!) {
          buffer.writeln('#### ${entry.title}');
          if (entry.tags != null && entry.tags!.isNotEmpty) {
            buffer.writeln('**Tags:** `${entry.tags}`  ');
          }
          if (entry.summary != null && entry.summary!.isNotEmpty) {
            buffer.writeln('> ${entry.summary}');
            buffer.writeln();
          }
          if (entry.content != null && entry.content!.isNotEmpty) {
            buffer.writeln(entry.content);
            buffer.writeln();
          }
        }
      }
    }

    buffer.writeln('---');
    buffer.writeln();

    // SECTION 4: IDEA SPARKS
    buffer.writeln('## 4. Idea Sparks & Scratchpad');
    buffer.writeln();
    if (sparks.isEmpty) {
      buffer.writeln('*No unprocessed sparks.*');
    } else {
      for (final spark in sparks) {
        final pinMark = spark.isPinned ? '📌 ' : '';
        final statusMark = spark.isConverted ? ' [WEAVED]' : '';
        buffer.writeln('- $pinMark**[${spark.category.toUpperCase()}]$statusMark**: ${spark.content}');
      }
    }

    return buffer.toString();
  }
}
