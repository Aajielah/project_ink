import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class BookRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  BookRepository(this._db);

  Stream<List<Book>> watchAllBooks() {
    return (_db.select(_db.books)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Book>> getAllBooks() {
    return (_db.select(_db.books)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<Book> createBook({
    required String name,
    required String genre,
  }) async {
    final book = Book(
      id: _uuid.v4(),
      name: name.trim(),
      genre: genre.trim(),
      createdAt: DateTime.now(),
    );
    await _db.into(_db.books).insert(book);
    return book;
  }

  Future<void> updateBook({
    required String id,
    required String name,
    required String genre,
  }) async {
    await (_db.update(_db.books)..where((t) => t.id.equals(id))).write(
      BooksCompanion(
        name: Value(name.trim()),
        genre: Value(genre.trim()),
      ),
    );
  }

  Future<void> deleteBook(String id) async {
    await (_db.delete(_db.books)..where((t) => t.id.equals(id))).go();
  }
}
