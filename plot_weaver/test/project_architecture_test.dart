import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/database/app_database.dart';
import 'package:plot_weaver/repositories/book_repository.dart';
import 'package:plot_weaver/repositories/project_repository.dart';
import 'package:plot_weaver/repositories/arc_repository.dart';
import 'package:plot_weaver/repositories/chapter_repository.dart';
import 'package:plot_weaver/repositories/custom_section_repository.dart';

void main() {
  late AppDatabase db;
  late BookRepository bookRepo;
  late ProjectRepository projectRepo;
  late ArcRepository arcRepo;
  late ChapterRepository chapterRepo;
  late CustomSectionRepository customRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bookRepo = BookRepository(db);
    projectRepo = ProjectRepository(db);
    arcRepo = ArcRepository(db);
    chapterRepo = ChapterRepository(db);
    customRepo = CustomSectionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlotWeaver Core Architecture Tests', () {
    test('Can create a Book folder and update it', () async {
      final book = await bookRepo.createBook(
        name: 'The Solaria Saga',
        genre: 'Epic Fantasy',
      );

      expect(book.name, 'The Solaria Saga');
      expect(book.genre, 'Epic Fantasy');

      await bookRepo.updateBook(
        id: book.id,
        name: 'The Solaria Chronicles',
        genre: 'High Fantasy',
      );

      final all = await bookRepo.getAllBooks();
      expect(all.length, 1);
      expect(all.first.name, 'The Solaria Chronicles');
      expect(all.first.genre, 'High Fantasy');
    });

    test('Creating a project automatically generates Arc 1 and Chapter 1 with 3-beat template', () async {
      final project = await projectRepo.createProject(
        name: 'The Starlight Heist',
        genre: 'Sci-Fi / Thriller',
      );

      expect(project.name, 'The Starlight Heist');
      expect(project.genre, 'Sci-Fi / Thriller');
      expect(project.generalIdea, '');

      // Verify starter Arc 1 exists
      final arcs = await arcRepo.getArcsByProject(project.id);
      expect(arcs.length, 1);
      expect(arcs.first.title, 'Arc 1');

      // Verify starter Chapter 1 exists with 3-beat template
      final chapters = await chapterRepo.getChaptersByProject(project.id);
      expect(chapters.length, 1);
      expect(chapters.first.title, 'Chapter 1');
      expect(chapters.first.startBeat, '');
      expect(chapters.first.middleBeat, '');
      expect(chapters.first.endBeat, '');
    });

    test('Can update General Idea canvas', () async {
      final project = await projectRepo.createProject(
        name: 'Neon Tokyo',
        genre: 'Cyberpunk',
      );

      const brainstorm = 'A rogue android attempts to recover forbidden memories in the lower city.';
      await projectRepo.updateGeneralIdea(project.id, brainstorm);

      final updated = await projectRepo.getProject(project.id);
      expect(updated!.generalIdea, brainstorm);
    });

    test('Can add more Arcs and rename them', () async {
      final project = await projectRepo.createProject(
        name: 'Kingdoms',
        genre: 'Fantasy',
      );

      // Arc 1 exists. Add Arc 2.
      final arc2 = await arcRepo.createArc(project.id);
      expect(arc2.title, 'Arc 2');

      // Rename Arc 1 to "The Awakening"
      final arcs = await arcRepo.getArcsByProject(project.id);
      await arcRepo.updateArcTitle(arcs.first.id, 'The Awakening');

      // Update content
      await arcRepo.updateArcContent(arcs.first.id, 'Protagonist discovers hidden magic powers.');

      final updatedArcs = await arcRepo.getArcsByProject(project.id);
      expect(updatedArcs.length, 2);
      expect(updatedArcs.first.title, 'The Awakening');
      expect(updatedArcs.first.content, 'Protagonist discovers hidden magic powers.');
      expect(updatedArcs[1].title, 'Arc 2');
    });

    test('Can add more Chapters and fill in the 3-beat template', () async {
      final project = await projectRepo.createProject(
        name: 'Mystery Manor',
        genre: 'Mystery',
      );

      // Chapter 1 exists. Update its 3 beats:
      final ch1 = (await chapterRepo.getChaptersByProject(project.id)).first;
      await chapterRepo.updateChapterBeats(
        id: ch1.id,
        startBeat: 'A scream echoes through the east wing during the thunderstorm.',
        middleBeat: 'Detective Vance finds the study locked from the inside.',
        endBeat: 'The grandfather clock stops, revealing a hidden passage!',
      );

      // Add Chapter 2
      final ch2 = await chapterRepo.createChapter(project.id);
      expect(ch2.title, 'Chapter 2');

      // Rename Chapter 1
      await chapterRepo.updateChapterTitle(ch1.id, 'Chapter 1: The Scream');

      final chapters = await chapterRepo.getChaptersByProject(project.id);
      expect(chapters.length, 2);
      expect(chapters[0].title, 'Chapter 1: The Scream');
      expect(chapters[0].startBeat, contains('scream echoes'));
      expect(chapters[0].middleBeat, contains('Detective Vance'));
      expect(chapters[0].endBeat, contains('hidden passage'));
      expect(chapters[1].title, 'Chapter 2');
    });

    test('Can add Custom Sections with user-defined headings and edit them', () async {
      final project = await projectRepo.createProject(
        name: 'Magic Realm',
        genre: 'Fantasy',
      );

      // Add Custom Section: Characters & Cast
      final sec1 = await customRepo.createCustomSection(project.id, 'Characters & Cast');
      expect(sec1.title, 'Characters & Cast');

      // Add content
      await customRepo.updateCustomSectionContent(sec1.id, 'Hero: Dylan (rebel mage)\nVillain: Lord Malakor');

      // Rename
      await customRepo.updateCustomSectionTitle(sec1.id, 'Main Cast');

      final sections = await customRepo.getCustomSectionsByProject(project.id);
      expect(sections.length, 1);
      expect(sections.first.title, 'Main Cast');
      expect(sections.first.content, contains('Hero: Dylan'));
    });

    test('Can group projects into Books and delete them cleanly', () async {
      final book = await bookRepo.createBook(
        name: 'Trilogy One',
        genre: 'Sci-Fi',
      );

      final p1 = await projectRepo.createProject(
        name: 'Book 1: Emergence',
        genre: 'Sci-Fi',
        bookId: book.id,
      );

      final p2 = await projectRepo.createProject(
        name: 'Book 2: Escalation',
        genre: 'Sci-Fi',
        bookId: book.id,
      );

      expect(p1.bookId, book.id);
      expect(p2.bookId, book.id);

      // Move p2 to standalone
      await projectRepo.assignProjectToBook(p2.id, null);
      final updatedP2 = await projectRepo.getProject(p2.id);
      expect(updatedP2!.bookId, isNull);

      // Delete project p1
      await projectRepo.deleteProject(p1.id);
      final remaining = await projectRepo.getProject(p1.id);
      expect(remaining, isNull);
    });
  });
}
