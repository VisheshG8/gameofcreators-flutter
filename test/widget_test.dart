// Game of Creators WebView App Tests

import 'package:flutter_test/flutter_test.dart';

import 'package:game_of_creator_mobile/main.dart';
import 'package:game_of_creator_mobile/constants/app_constants.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GameOfCreatorsApp());
    await tester.pump();

    // Verify that splash screen elements are present
    expect(find.text('GAME OF'), findsOneWidget);
    expect(find.text('CREATORS'), findsOneWidget);

    // Wait for splash duration to complete to avoid timer errors
    await tester.pumpAndSettle(AppConstants.splashDuration);
  });
}
