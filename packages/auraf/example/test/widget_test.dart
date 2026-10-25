import 'package:flutter_test/flutter_test.dart';
import 'package:auraf_example/main.dart';

void main() {
  testWidgets('Renders AURAF Real Hardware Telemetry app', (WidgetTester tester) async {
    await tester.pumpWidget(const AurafExampleApp());
    expect(find.text('AURAF Telemetry & Model Verification'), findsOneWidget);
  });
}
