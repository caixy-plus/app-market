import 'package:flutter_test/flutter_test.dart';
import 'package:app_market/models/app_store_app.dart';

void main() {
  group('AppStoreApp Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'slug': 'vscode',
        'name': 'VS Code',
        'shortDesc': '轻量级编辑器',
        'fullDesc': '完整的描述',
        'category': '开发工具',
        'iconUrl': 'https://example.com/icon.png',
        'pricingType': 'free',
        'priceCents': 0,
        'version': '1.0.0',
        'installCount': 100,
        'ratingAvg': 4.5,
        'ratingCount': 20,
        'status': 'PUBLISHED',
        'createdAt': '2024-01-15T00:00:00Z',
      };

      final app = AppStoreApp.fromJson(json);

      expect(app.id, 1);
      expect(app.slug, 'vscode');
      expect(app.name, 'VS Code');
      expect(app.shortDesc, '轻量级编辑器');
      expect(app.category, '开发工具');
      expect(app.pricingType, 'free');
      expect(app.isFree, true);
      expect(app.installCount, 100);
      expect(app.ratingAvg, 4.5);
      expect(app.status, 'PUBLISHED');
      expect(app.createdAt, isNotNull);
    });

    test('displayDescription falls back correctly', () {
      final app1 = AppStoreApp(id: 1, slug: 'a', name: 'A', shortDesc: '短描述');
      expect(app1.displayDescription, '短描述');

      final app2 = AppStoreApp(id: 2, slug: 'b', name: 'B', fullDesc: '完整描述');
      expect(app2.displayDescription, '完整描述');

      final app3 = AppStoreApp(id: 3, slug: 'c', name: 'C');
      expect(app3.displayDescription, '暂无描述');
    });

    test('displayPrice formats correctly', () {
      final free = AppStoreApp(id: 1, slug: 'a', name: 'A', pricingType: 'free');
      expect(free.displayPrice, '免费');

      final paid = AppStoreApp(id: 2, slug: 'b', name: 'B', pricingType: 'paid', priceCents: 1999);
      expect(paid.displayPrice, '¥19.99');
    });

    test('supportedPlatforms parsing', () {
      final json = {
        'id': 1,
        'slug': 'test',
        'name': 'Test',
        'supportedPlatforms': ['android', 'windows'],
      };

      final app = AppStoreApp.fromJson(json);
      expect(app.supportedPlatforms, ['android', 'windows']);
    });
  });
}
