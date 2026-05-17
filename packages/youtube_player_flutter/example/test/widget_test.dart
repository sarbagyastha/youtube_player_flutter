import 'package:flutter_test/flutter_test.dart';
import 'package:ypf_example/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('YouTube Player Flutter'), findsOneWidget);
  });
}
