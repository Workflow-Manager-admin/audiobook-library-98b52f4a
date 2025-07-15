import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Main tabs present and titles are correct', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Audiobook Store'), findsOneWidget);
    expect(find.byIcon(Icons.store), findsOneWidget);
    expect(find.byIcon(Icons.library_books), findsOneWidget);
    expect(find.byIcon(Icons.headphones), findsOneWidget);
  });

  testWidgets('Store displays sample book', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('The Art of Flutter'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Buy'), findsWidgets); // There will be several Buy buttons
  });

  testWidgets('Library shows message if empty', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();
    // Switch to Library tab
    await tester.tap(find.byIcon(Icons.library_books));
    await tester.pumpAndSettle();
    expect(find.textContaining('No audiobooks purchased'), findsOneWidget);
  });
}
