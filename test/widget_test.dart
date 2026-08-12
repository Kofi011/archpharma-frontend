import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archpharma/main.dart';

void main() {
  testWidgets('App loads and displays login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ArchPharmaApp(),
      ),
    );

    // Verify that the login screen header is loaded.
    expect(find.text('ArchPharma'), findsOneWidget);
    expect(find.text('Wholesale Pharmacy ERP Management'), findsOneWidget);
  });
}
