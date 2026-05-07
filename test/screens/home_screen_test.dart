import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_market/providers/app_store_provider.dart';
import 'package:app_market/providers/auth_provider.dart';
import 'package:app_market/screens/main_screen.dart';
import 'package:app_market/screens/search_screen.dart';

Widget createTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AppStoreProvider(),
      ),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(
      title: '应用商城',
      home: const MainScreen(),
    ),
  );
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  HttpOverrides.global = _RealHttpOverrides();
  group('HomeScreen Widget Tests with Real Backend', () {
    testWidgets('renders app banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('发现优质应用'), findsOneWidget);
    });

    testWidgets('bottom navigation has 3 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('应用'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('can switch tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('应用'));
      await tester.pump();

      expect(find.text('应用列表'), findsOneWidget);

      await tester.tap(find.text('我的'));
      await tester.pump();

      expect(find.text('未登录'), findsOneWidget);
    });

    testWidgets('search bar navigates to search', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('搜索应用...'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
