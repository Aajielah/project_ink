import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/universe_repository.dart';
import 'package:plot_weaver/repositories/spark_repository.dart';

void main() {
  late AppDatabase db;
  late UniverseRepository universeRepo;
  late SparkRepository sparkRepo;
  late Universe universe;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    universeRepo = UniverseRepository(db);
    sparkRepo = SparkRepository(db);

    universe = await universeRepo.createUniverse(
      title: 'Neon Odyssey',
      genre: 'Cyberpunk Thriller',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SparkRepository Tests (Phase 4)', () {
    test('Can create and retrieve sparks with proper ordering', () async {
      final spark1 = await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'What if the AI is not rogue, but grief-stricken?',
        category: 'Scene Idea',
      );

      final spark2 = await sparkRepo.createSpark(
        universeId: universe.id,
        content: '"You cannot bargain with a ghost, detective."',
        category: 'Dialogue',
        isPinned: true, // Pinned should float to top
      );

      final sparks = await sparkRepo.getSparks(universe.id);
      expect(sparks.length, 2);
      expect(sparks.first.id, spark2.id, reason: 'Pinned spark should appear first');
      expect(sparks.last.id, spark1.id);
    });

    test('Can toggle pin on spark', () async {
      final spark = await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Cyberware glitch triggers whenever protagonist lies',
        category: 'Character Quirk',
        isPinned: false,
      );

      expect(spark.isPinned, isFalse);

      await sparkRepo.togglePin(spark.id, true);
      var fetched = await sparkRepo.getSpark(spark.id);
      expect(fetched!.isPinned, isTrue);

      await sparkRepo.togglePin(spark.id, false);
      fetched = await sparkRepo.getSpark(spark.id);
      expect(fetched!.isPinned, isFalse);
    });

    test('Can mark spark as converted to story element', () async {
      final spark = await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Underground black-market memory exchange',
        category: 'World Lore',
      );

      expect(spark.isConverted, isFalse);

      await sparkRepo.markConverted(spark.id, true);
      final fetched = await sparkRepo.getSpark(spark.id);
      expect(fetched!.isConverted, isTrue);
    });

    test('Can update spark note and category', () async {
      final spark = await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Old text note',
        category: 'General',
      );

      await sparkRepo.updateSpark(
        id: spark.id,
        content: 'Updated high stakes confrontation at the neon docks',
        category: 'Scene Idea',
      );

      final fetched = await sparkRepo.getSpark(spark.id);
      expect(fetched!.content, 'Updated high stakes confrontation at the neon docks');
      expect(fetched.category, 'Scene Idea');
    });

    test('Can delete spark', () async {
      final spark = await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Temporary spark',
      );

      var list = await sparkRepo.getSparks(universe.id);
      expect(list.length, 1);

      await sparkRepo.deleteSpark(spark.id);

      list = await sparkRepo.getSparks(universe.id);
      expect(list.isEmpty, isTrue);
    });

    test('watchSparks emits stream updates dynamically', () async {
      final stream = sparkRepo.watchSparks(universe.id);

      final expectation = expectLater(
        stream,
        emitsThrough(hasLength(2)),
      );

      await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Spark 1',
      );

      await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Spark 2',
      );

      await expectation;
    });

    test('Sparks cascade delete when Universe is deleted', () async {
      await sparkRepo.createSpark(
        universeId: universe.id,
        content: 'Orphaned spark',
      );

      await universeRepo.deleteUniverse(universe.id);

      final sparks = await db.select(db.ideaSparks).get();
      expect(sparks.isEmpty, isTrue);
    });
  });
}
