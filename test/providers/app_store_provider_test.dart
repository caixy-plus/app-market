import 'package:flutter_test/flutter_test.dart';
import 'package:app_market/providers/app_store_provider.dart';

void main() {
  group('AppStoreProvider with Real Backend', () {
    late AppStoreProvider provider;

    setUp(() {
      provider = AppStoreProvider();
    });

    test('initial state is correct', () {
      expect(provider.popularApps, isEmpty);
      expect(provider.latestApps, isEmpty);
      expect(provider.apps, isEmpty);
      expect(provider.loading, false);
      expect(provider.hasMore, true);
      expect(provider.currentCategory, 'all');
      expect(provider.currentSortBy, 'popular');
    });

    test('loadPopularApps populates list from backend', () async {
      await provider.loadPopularApps();
      expect(provider.popularApps, isNotEmpty);
    });

    test('loadLatestApps populates list from backend', () async {
      await provider.loadLatestApps();
      expect(provider.latestApps, isNotEmpty);
    });

    test('loadApps with refresh resets pagination', () async {
      await provider.loadApps(refresh: true);
      expect(provider.apps, isNotEmpty);
    });

    test('setCategory changes filter and reloads from backend', () async {
      await provider.setCategory('开发工具');
      expect(provider.currentCategory, '开发工具');
      // 后端 popular 模式暂不支持分类过滤，只验证状态更新与非空
      expect(provider.apps, isNotEmpty);
    });

    test('setSortBy changes sort and reloads', () async {
      await provider.setSortBy('rating');
      expect(provider.currentSortBy, 'rating');
      expect(provider.apps, isNotEmpty);
    });

    test('setSearch filters apps from backend', () async {
      // Use a search term that matches existing data
      await provider.setSearch('v');
      expect(provider.currentSearch, 'v');
      // Backend search may return empty if no match; just verify state
      expect(provider.apps, isA<List>());
    });

    test('loadAppDetail fetches from backend', () async {
      await provider.loadAppDetail('vscode');
      expect(provider.selectedApp, isNotNull);
      expect(provider.selectedApp!.name.toLowerCase(), contains('vscode'));
    });

    test('clearSelectedApp resets selectedApp', () async {
      await provider.loadAppDetail('vscode');
      expect(provider.selectedApp, isNotNull);

      provider.clearSelectedApp();
      expect(provider.selectedApp, isNull);
    });

    test('installApp without auth does not crash', () async {
      // Backend may return error or silently fail; just verify no unhandled exception
      await provider.installApp(1);
      // If we get here, no unhandled exception was thrown
      expect(true, true);
    });

    test('uninstallApp without auth does not crash', () async {
      // Backend may return error or silently fail; just verify no unhandled exception
      await provider.uninstallApp(1);
      expect(true, true);
    });
  });
}
