import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/quotes_seed.dart';
import '../models/quote.dart';

class QuoteRepository {
  final AppDatabase _db;

  QuoteRepository(this._db);

  QuoteModel _mapToModel(Quote data) {
    return QuoteModel(
      id: data.id,
      text: data.textContent,
      author: data.author,
      category: data.category,
      mood: data.mood,
    );
  }

  QuotesCompanion _mapToCompanion(QuoteModel model) {
    return QuotesCompanion(
      id: Value(model.id),
      textContent: Value(model.text),
      author: Value(model.author),
      category: Value(model.category),
      mood: Value(model.mood),
    );
  }

  Future<List<QuoteModel>> getAllQuotes() async {
    final query = _db.select(_db.quotes);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<QuoteModel?> getRandomQuote() async {
    final quotes = await getAllQuotes();
    if (quotes.isEmpty) return null;
    return quotes[Random().nextInt(quotes.length)];
  }

  Future<List<QuoteModel>> getQuotesByMood(String mood) async {
    final query = _db.select(_db.quotes)..where((t) => t.mood.equals(mood));
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<QuoteModel?> getRandomQuoteByFilter({String? category, String? mood}) async {
    var query = _db.select(_db.quotes);
    if (category != null && mood != null) {
      query.where((t) => t.category.equals(category) & t.mood.equals(mood));
    } else if (category != null) {
      query.where((t) => t.category.equals(category));
    } else if (mood != null) {
      query.where((t) => t.mood.equals(mood));
    }

    final results = await query.get();
    if (results.isEmpty) {
      // Fallback to absolute random quote
      return getRandomQuote();
    }
    return _mapToModel(results[Random().nextInt(results.length)]);
  }

  Future<void> seedDatabaseQuotes() async {
    final countQuery = _db.select(_db.quotes);
    final existing = await countQuery.get();
    if (existing.isEmpty) {
      final List<QuotesCompanion> companions = [];
      const uuid = Uuid();
      for (final quoteMap in seedQuotes) {
        companions.add(QuotesCompanion(
          id: Value(uuid.v4()),
          textContent: Value(quoteMap['text']!),
          author: Value(quoteMap['author']!),
          category: Value(quoteMap['category']!),
          mood: Value(quoteMap['mood']!),
        ));
      }
      await _db.batch((batch) {
        batch.insertAll(_db.quotes, companions);
      });
    }
  }
}
