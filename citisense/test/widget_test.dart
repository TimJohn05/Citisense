import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/services/mock_repository.dart';

void main() {
  testWidgets('App boots to login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(App(repository: MockRepository()));
    await tester.pumpAndSettle();

    expect(find.text('CitiSense'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
