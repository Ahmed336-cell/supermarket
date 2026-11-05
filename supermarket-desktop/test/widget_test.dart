import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supermarket_desktop/api/api_client.dart';
import 'package:supermarket_desktop/app.dart';
import 'package:supermarket_desktop/models.dart';
import 'package:supermarket_desktop/state/app_state.dart';

void main() {
  test('line total matches API rounding', () {
    expect(lineTotal(2.5, 3, 10), 6.75);
    expect(orderTotal(6.75, 10), 6.08);
  });

  testWidgets('login screen shows', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(
      api: ApiClient(baseUrl: 'http://127.0.0.1:9'),
      prefs: prefs,
      startReady: true,
    );
    await tester.pumpWidget(SupermarketApp(state: state));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
