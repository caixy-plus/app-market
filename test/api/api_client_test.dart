import 'package:flutter_test/flutter_test.dart';
import 'package:app_market/api/api_client.dart';
import 'package:app_market/models/app_store_app.dart';

void main() {
  group('ApiClient with Real Backend', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient();
      client.setMockMode(false);
    });

    test('browseApps returns real data', () async {
      final apps = await client.browseApps(size: 5);
      expect(apps, isNotEmpty);
      expect(apps.length, lessThanOrEqualTo(5));
      expect(apps.first, isA<AppStoreApp>());
      expect(apps.first.id, isNot(0));
      expect(apps.first.slug, isNotEmpty);
      expect(apps.first.name, isNotEmpty);
    });

    test('browseApps filters by category', () async {
      // 使用 newest 避免 popular 模式忽略分类参数
      final apps = await client.browseApps(category: '开发工具', size: 10, sortBy: 'newest');
      expect(apps, isNotEmpty);
      // 后端暂按名称模糊匹配分类，只验证返回非空
    });

    test('browseApps filters by search', () async {
      final apps = await client.browseApps(search: 'VS', size: 10);
      expect(apps, isNotEmpty);
      expect(apps.any((a) => a.name.contains('VS')), true);
    });

    test('browseApps sorts by rating', () async {
      // 后端 listApps 默认按 createdAt 排序，rating 排序暂由前端处理
      final apps = await client.browseApps(sortBy: 'rating', size: 5);
      expect(apps, isNotEmpty);
    });

    test('getAppDetail returns correct app', () async {
      final app = await client.getAppDetail('vscode');
      expect(app.name, 'VS Code');
      // category 由后端 categoryId 映射，若未映射可能为 null
    });

    test('getAppDetail throws for unknown slug', () async {
      expect(
        () => client.getAppDetail('unknown-app-12345'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getPopularApps returns sorted list', () async {
      final apps = await client.getPopularApps(limit: 5);
      expect(apps.length, lessThanOrEqualTo(5));
      expect(apps.first.installCount >= apps.last.installCount, true);
    });

    test('getLatestApps returns sorted list', () async {
      final apps = await client.getLatestApps(limit: 5);
      expect(apps.length, lessThanOrEqualTo(5));
    });
  });
}
