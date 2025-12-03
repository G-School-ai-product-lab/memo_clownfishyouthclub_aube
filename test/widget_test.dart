import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pamyo_one/main.dart';

void main() {
  testWidgets('Pamyo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PamyoApp(),
      ),
    );

    expect(find.text('파묘'), findsOneWidget);
  });
}
