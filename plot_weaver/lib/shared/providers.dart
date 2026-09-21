import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../repositories/universe_repository.dart';
import '../repositories/project_ink_bridge_repository.dart';
import '../repositories/outline_repository.dart';
import '../repositories/character_repository.dart';
import '../repositories/lore_repository.dart';
import '../repositories/spark_repository.dart';
import '../services/export_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final universeRepositoryProvider = Provider<UniverseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UniverseRepository(db);
});

final projectInkBridgeProvider = Provider<ProjectInkBridgeRepository>((ref) {
  return ProjectInkBridgeRepository();
});

final allUniversesProvider = StreamProvider<List<Universe>>((ref) {
  final repo = ref.watch(universeRepositoryProvider);
  return repo.watchAllUniverses();
});

final activeUniverseIdProvider = StateProvider<String?>((ref) => null);

final activeUniverseProvider = FutureProvider<Universe?>((ref) async {
  final activeId = ref.watch(activeUniverseIdProvider);
  if (activeId == null) return null;
  final repo = ref.watch(universeRepositoryProvider);
  return repo.getUniverse(activeId);
});

final universeStatsProvider =
    FutureProvider.family<UniverseStats, String>((ref, universeId) async {
  final repo = ref.watch(universeRepositoryProvider);
  return repo.getUniverseStats(universeId);
});

final linkedInkBookProvider =
    FutureProvider.family<ProjectInkBookSummary?, String>((ref, inkBookId) async {
  final bridge = ref.watch(projectInkBridgeProvider);
  return bridge.getLinkedBookSummary(inkBookId);
});

final outlineRepositoryProvider = Provider<OutlineRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return OutlineRepository(db);
});

final universeChaptersProvider =
    StreamProvider.family<List<Chapter>, String>((ref, universeId) {
  final repo = ref.watch(outlineRepositoryProvider);
  return repo.watchChapters(universeId);
});

final chapterScenesProvider =
    StreamProvider.family<List<Scene>, String>((ref, chapterId) {
  final repo = ref.watch(outlineRepositoryProvider);
  return repo.watchScenesForChapter(chapterId);
});

final allUniverseScenesProvider =
    StreamProvider.family<List<Scene>, String>((ref, universeId) {
  final repo = ref.watch(outlineRepositoryProvider);
  return repo.watchAllScenes(universeId);
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CharacterRepository(db);
});

final universeCharactersProvider =
    StreamProvider.family<List<Character>, String>((ref, universeId) {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.watchCharacters(universeId);
});

final universeRelationshipsProvider =
    StreamProvider.family<List<CharacterRelationship>, String>((ref, universeId) {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.watchRelationships(universeId);
});

final characterRelationshipsDetailProvider =
    FutureProvider.family<List<CharacterRelationshipWithTarget>, String>((ref, characterId) async {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.getRelationshipsForCharacter(characterId);
});

final loreRepositoryProvider = Provider<LoreRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LoreRepository(db);
});

final universeLoreEntriesProvider =
    StreamProvider.family<List<LoreEntry>, String>((ref, universeId) {
  final repo = ref.watch(loreRepositoryProvider);
  return repo.watchLoreEntries(universeId);
});

final sparkRepositoryProvider = Provider<SparkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SparkRepository(db);
});

final universeSparksProvider =
    StreamProvider.family<List<IdeaSpark>, String>((ref, universeId) {
  final repo = ref.watch(sparkRepositoryProvider);
  return repo.watchSparks(universeId);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return ExportService(db);
});


