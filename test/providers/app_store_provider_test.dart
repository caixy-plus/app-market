import 'package:flutter_test/flutter_test.dart';
import 'package:app_market/providers/app_store_provider.dart';

void main() {
  group('AppStoreProvider with Real Backend', () {
    late AppStoreProvider provider;

    setUp(() {
      provider = AppStoreProvider();
      provider.setMockMode(false);
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
      await provider.setSearch('VS');
      expect(provider.currentSearch, 'VS');
      expect(provider.apps.any((a) => a.name.contains('VS')), true);
    });

    test('loadAppDetail fetches from backend', () async {
      await provider.loadAppDetail('vscode');
      expect(provider.selectedApp, isNotNull);
      expect(provider.selectedApp!.name, 'VS Code');
    });

    test('clearSelectedApp resets selectedApp', () async {
      await provider.loadAppDetail('vscode');
      expect(provider.selectedApp, isNotNull);

      provider.clearSelectedApp();
      expect(provider.selectedApp, isNull);
    });

    test('installApp throws without auth on real backend', () async {
      expect(() => provider.installApp(1), throwsA(isA<Exception>()));
    });

    test('uninstallApp throws without auth on real backend', () async {
      expect(() => provider.uninstallApp(1), throwsA(isA<Exception>()));
    });
  });
}
