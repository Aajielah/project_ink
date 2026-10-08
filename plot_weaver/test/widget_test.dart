import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:plot_weaver/main.dart';
import 'package:plot_weaver/shared/providers.dart';
import 'package:plot_weaver/database/app_database.dart';

void main() {
  testWidgets('PlotWeaverApp smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const PlotWeaverApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and clean empty state render
    expect(find.text('PlotWeaver'), findsOneWidget);
    expect(find.text('New Project'), findsWidgets);
    expect(find.text('Ready to Begin Your Story?'), findsOneWidget);

    await testDb.close();
  });
}
