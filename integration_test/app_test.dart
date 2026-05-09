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

      // 1. Verify home screen loads (3 tabs: 首页, 应用, 我的)
      expect(find.text('发现优质应用'), findsOneWidget);
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('应用'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
      // AI 对话 tab 已移除
      expect(find.text('AI 对话'), findsNothing);

      // 2. Navigate to app list tab
      await tester.tap(find.text('应用'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // App list should show app cards
      expect(find.text('应用列表'), findsOneWidget);

      // 3. Navigate to home tab
      await tester.tap(find.text('首页'));
      await tester.pumpAndSettle();
      expect(find.text('发现优质应用'), findsOneWidget);

      // 4. Navigate to profile tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(find.text('未登录'), findsOneWidget);

      // 5. Scroll down to find theme setting
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final themeTile = find.text('主题设置');
      if (themeTile.evaluate().isNotEmpty) {
        await tester.tap(themeTile);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('亮色'), findsOneWidget);
        expect(find.text('暗色'), findsOneWidget);
        await tester.tap(find.text('跟随系统').last);
        await tester.pumpAndSettle();
      }
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

      // Verify search results exist (ListTile or Card)
      final results = find.byType(ListTile).hitTestable();
      final cards = find.byType(Card).hitTestable();
      expect(results.evaluate().isNotEmpty || cards.evaluate().isNotEmpty, isTrue,
          reason: 'Should have search results');
    });

    testWidgets('install download and rate flow', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Go to app list tab
      await tester.tap(find.text('应用'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Find vertical ListView (the app list)
      final verticalListViews = find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      );
      expect(verticalListViews, findsOneWidget, reason: 'Should have one vertical list');

      // Scroll down to ensure items are loaded
      await tester.drag(verticalListViews, const Offset(0, -100));
      await tester.pumpAndSettle();

      // 3. Find and tap first app Card (use hitTestable to only find visible ones)
      final appCards = find.byType(Card).hitTestable();
      expect(appCards, findsWidgets, reason: 'App cards should be visible');
      await tester.tap(appCards.first);
      await tester.pump(const Duration(seconds: 2));

      // 4. Verify we're on the detail page
      expect(find.text('应用信息'), findsOneWidget,
          reason: 'Detail page should show app info');

      // 5. Scroll down to see install button and rating section
      final scrollView = find.byType(CustomScrollView).hitTestable();
      if (scrollView.evaluate().isNotEmpty) {
        await tester.drag(scrollView, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      // 6. Find and tap install button
      final installBtn = find.text('安装').hitTestable();
      if (installBtn.evaluate().isNotEmpty) {
        await tester.tap(installBtn);
        await tester.pump(const Duration(milliseconds: 500));

        // Verify download started (cancel button appears)
        expect(find.textContaining('取消下载').hitTestable().evaluate().isNotEmpty ||
            find.text('卸载').hitTestable().evaluate().isNotEmpty, isTrue,
            reason: 'Download should start or already complete');

        // Wait for download to complete (max 20s)
        bool installDone = false;
        for (int i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.text('卸载').hitTestable().evaluate().isNotEmpty) {
            installDone = true;
            break;
          }
        }
        expect(installDone, true, reason: 'Download should complete');
        expect(find.text('卸载').hitTestable(), findsOneWidget);

        // Uninstall
        await tester.tap(find.text('卸载').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('安装').hitTestable(), findsOneWidget,
            reason: 'Back to install after uninstall');
      }

      // 7. Test rating section
      final ratingSection = find.text('评分与评论');
      if (ratingSection.evaluate().isNotEmpty) {
        // Scroll to rating section
        await tester.ensureVisible(ratingSection);
        await tester.pumpAndSettle();

        // Find and tap "写评价" button
        final rateBtn = find.text('写评价');
        if (rateBtn.evaluate().isNotEmpty) {
          await tester.tap(rateBtn);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();

          // Verify rating dialog appears with stars and comment field
          expect(find.byType(TextField), findsOneWidget,
              reason: 'Comment text field should appear');

          // Tap 4th star to set rating to 4
          final stars = find.byIcon(Icons.star_border);
          if (stars.evaluate().length >= 4) {
            await tester.tap(stars.at(3));
            await tester.pump(const Duration(milliseconds: 200));
          }

          // Enter comment
          await tester.enterText(find.byType(TextField), '自动化测试评论：非常好用！');
          await tester.pump(const Duration(milliseconds: 200));

          // Submit rating
          final submitBtn = find.text('提交');
          if (submitBtn.evaluate().isNotEmpty) {
            await tester.tap(submitBtn);
            await tester.pump(const Duration(seconds: 1));
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('download manager screen', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Navigate to profile tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      // Find and tap download manager menu item
      final downloadMenu = find.text('下载管理');
      if (downloadMenu.evaluate().isNotEmpty) {
        await tester.ensureVisible(downloadMenu);
        await tester.pumpAndSettle();
        await tester.tap(downloadMenu);
        await tester.pumpAndSettle();

        // Verify download manager screen
        expect(find.text('下载中'), findsOneWidget);
        expect(find.text('已完成'), findsOneWidget);
        expect(find.text('暂无下载任务'), findsOneWidget);

        // Switch to completed tab
        await tester.tap(find.text('已完成'));
        await tester.pumpAndSettle();
        expect(find.text('暂无已完成的下载'), findsOneWidget);
      }
    });

    testWidgets('login redirect on profile actions', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Navigate to profile tab (not logged in)
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(find.text('未登录'), findsOneWidget);

      // Scroll to find "我的评分" menu
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final myRatingsMenu = find.text('我的评分');
      if (myRatingsMenu.evaluate().isNotEmpty) {
        await tester.ensureVisible(myRatingsMenu);
        await tester.pumpAndSettle();
        await tester.tap(myRatingsMenu);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Should show login screen with TabBar (登录/注册)
        expect(find.text('登录'), findsWidgets);
      }
    });

    testWidgets('register screen has verification code and confirm password',
        (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Navigate to profile tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      // Tap login button to open login screen
      final loginBtn = find.text('登录');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      // Switch to register tab
      final registerTab = find.text('注册');
      expect(registerTab, findsWidgets);
      await tester.tap(registerTab.last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify register form fields exist
      expect(find.widgetWithText(TextField, '邮箱'), findsOneWidget);
      expect(find.text('发送验证码'), findsOneWidget);
      expect(find.widgetWithText(TextField, '验证码'), findsOneWidget);
      expect(find.widgetWithText(TextField, '密码'), findsOneWidget);
      expect(find.widgetWithText(TextField, '确认密码'), findsOneWidget);
    });

    testWidgets('feedback screen submit', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Navigate to profile tab
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      // Tap login button
      final loginBtn = find.text('登录');
      if (loginBtn.evaluate().isNotEmpty) {
        await tester.tap(loginBtn.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      // Fill login credentials
      final emailField = find.byType(TextField).at(0);
      await tester.enterText(emailField, 'playwright-test@caixy.xin');
      await tester.pump(const Duration(milliseconds: 200));

      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'TestPass123');
      await tester.pump(const Duration(milliseconds: 200));

      // Submit login — use ElevatedButton to avoid matching Tab text
      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // After login, we're back on profile screen
      // Scroll to find "意见反馈" menu
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final feedbackMenu = find.text('意见反馈');
      expect(feedbackMenu, findsOneWidget, reason: 'Should find feedback menu item');
      await tester.ensureVisible(feedbackMenu);
      await tester.pumpAndSettle();
      await tester.tap(feedbackMenu);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify feedback screen
      expect(find.text('意见反馈'), findsWidgets);
      expect(find.text('反馈类型'), findsOneWidget);
      expect(find.text('反馈内容'), findsOneWidget);
      expect(find.text('联系方式（选填）'), findsOneWidget);
      expect(find.text('提交反馈'), findsOneWidget);
    });
  });
}
