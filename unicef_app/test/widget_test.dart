import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:unicef_app/main.dart';
import 'package:unicef_app/providers/app_state.dart';
import 'package:unicef_app/screens/login_screen.dart';

void main() {
  testWidgets('ComMobi-Tracker app loads successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ComMobiApp(),
      ),
    );

    // Verify it renders the login screen
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
