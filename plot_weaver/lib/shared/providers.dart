import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../repositories/book_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/arc_repository.dart';
import '../repositories/chapter_repository.dart';
import '../repositories/custom_section_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repositories
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(ref.watch(databaseProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(databaseProvider));
});

final arcRepositoryProvider = Provider<ArcRepository>((ref) {
  return ArcRepository(ref.watch(databaseProvider));
});

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepository(ref.watch(databaseProvider));
});

final customSectionRepositoryProvider = Provider<CustomSectionRepository>((ref) {
  return CustomSectionRepository(ref.watch(databaseProvider));
});

// Streams
final allBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(bookRepositoryProvider).watchAllBooks();
});

final allProjectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

final unassignedProjectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchUnassignedProjects();
});

final projectsByBookProvider = StreamProvider.family<List<Project>, String>((ref, bookId) {
  return ref.watch(projectRepositoryProvider).watchProjectsByBook(bookId);
});

final projectDetailProvider = StreamProvider.family<Project?, String>((ref, projectId) {
  return ref.watch(projectRepositoryProvider).watchProject(projectId);
});

final projectArcsProvider = StreamProvider.family<List<Arc>, String>((ref, projectId) {
  return ref.watch(arcRepositoryProvider).watchArcsByProject(projectId);
});

final projectChaptersProvider = StreamProvider.family<List<Chapter>, String>((ref, projectId) {
  return ref.watch(chapterRepositoryProvider).watchChaptersByProject(projectId);
});

final projectCustomSectionsProvider = StreamProvider.family<List<CustomSection>, String>((ref, projectId) {
  return ref.watch(customSectionRepositoryProvider).watchCustomSectionsByProject(projectId);
});
