import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';

// Exposed as unimplemented. Overridden in main.dart upon startup initialization.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseServiceProvider has not been overridden');
});
