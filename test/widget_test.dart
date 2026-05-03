import 'package:flutter_test/flutter_test.dart';
import 'package:silent_zone/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SilentZoneApp());
  });
}