import 'package:flutter_test/flutter_test.dart';
import 'package:saithcommissionshop/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(onboardingDone: true));
    await tester.pump();
    // App should launch without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}