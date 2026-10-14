import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_frontend/main.dart';

void main() {
  testWidgets('HospitalApp launches successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HospitalApp(),
      ),
    );
    expect(find.byType(HospitalApp), findsOneWidget);
  });
}
