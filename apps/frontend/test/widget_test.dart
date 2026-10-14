import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hospital_frontend/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HospitalApp launches successfully smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: HospitalApp(),
      ),
    );
    expect(find.byType(HospitalApp), findsOneWidget);
  });
}
