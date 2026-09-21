import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/main.dart';
import 'package:plot_weaver/shared/providers.dart';
import 'package:plot_weaver/database/app_database.dart';

void main() {
  testWidgets('PlotWeaverApp smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const PlotWeaverApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and empty state render
    expect(find.text('PlotWeaver'), findsOneWidget);
    expect(find.text('STORY BIBLE'), findsOneWidget);
    expect(find.text('Your Story Bible is Empty'), findsOneWidget);

    await testDb.close();
  });
}
