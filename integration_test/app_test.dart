import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_market/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Market Test', () {
    testWidgets('full user journey', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 1. Verify home screen loads
      expect(find.text('发现优质应用'), findsOneWidget);

      // 2. Tap on a popular app (VS Code)
      final firstApp = find.text('VS Code');
      if (firstApp.evaluate().isNotEmpty) {
        await tester.tap(firstApp);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Verify detail screen
        expect(find.text('VS Code'), findsOneWidget);
        expect(find.text('应用介绍'), findsOneWidget);

        // Go back
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }

      // 3. Navigate to app list tab
      await tester.tap(find.text('应用'));
      await tester.pumpAndSettle();

      expect(find.text('应用列表'), findsOneWidget);

      // 4. Tap a category filter (first occurrence in the filter chips)
      await tester.tap(find.text('开发工具').first);
      await tester.pumpAndSettle();

      // 5. Navigate to profile tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      expect(find.text('未登录'), findsOneWidget);

      // 6. Verify theme setting exists
      await tester.ensureVisible(find.widgetWithText(ListTile, '主题设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '主题设置'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('亮色'), findsOneWidget);
      expect(find.text('暗色'), findsOneWidget);
      expect(find.text('跟随系统').last, findsOneWidget);
      await tester.tap(find.text('跟随系统').last);
      await tester.pumpAndSettle();
    });

    testWidgets('search flow', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Tap search bar
      await tester.tap(find.text('搜索应用...'));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(find.byType(TextField), 'a');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify search results (at least one result card exists)
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
