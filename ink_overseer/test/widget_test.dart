import 'package:flutter_test/flutter_test.dart';
import 'package:ink_overseer/main.dart';

void main() {
  testWidgets('InkOverseerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const InkOverseerApp());
    expect(find.byType(InkOverseerApp), findsOneWidget);
  });
}
