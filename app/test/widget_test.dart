// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bemyguide/main.dart';

void main() {
  testWidgets('BeMyGuide app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present
    expect(find.text('BeMyGuide'), findsOneWidget);

    // Verify welcome message is present
    expect(find.text('Welcome to BeMyGuide!'), findsOneWidget);

    // Verify search hint text is present
    expect(find.text('What would you like to explore?'), findsOneWidget);

    // Verify search button is present
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('Search input accepts text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Find the search text field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter text in the search field
    await tester.enterText(searchField, 'restaurants near me');
    await tester.pump();

    // Verify the text was entered
    expect(find.text('restaurants near me'), findsOneWidget);
  });

  testWidgets('Example queries are displayed', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify example queries section is present
    expect(find.text('Try asking:'), findsOneWidget);

    // Verify at least one example query is present
    expect(
      find.text('Find nearby restaurants that serve vegan food'),
      findsOneWidget,
    );
  });
}
