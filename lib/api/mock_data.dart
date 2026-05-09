import '../models/app_store_app.dart';

class MockData {
  static final List<AppStoreApp> apps = [
    AppStoreApp(
      id: 1,
      slug: 'vs-code-1',
      name: 'VS Code',
      shortDesc: '微软出品的轻量级代码编辑器',
      fullDesc: 'Visual Studio Code 是一款轻量级但功能强大的源代码编辑器，支持丰富的插件生态。',
      category: '开发工具',
      iconUrl: 'https://caixy-disk.oss-cn-hangzhou.aliyuncs.com/apps/icons/microsoft/vscode/icon.png',
      version: '1.85.0',
      installCount: 12580,
      ratingAvg: 4.8,
      ratingCount: 342,
      status: 'PUBLISHED',
      githubRepoUrl: 'https://github.com/microsoft/vscode',
      officialUrl: 'https://code.visualstudio.com',
      pricingType: 'free',
    ),
    AppStoreApp(
      id: 2,
      slug: 'flutter-2',
      name: 'Flutter',
      shortDesc: 'Google UI 工具包',
      fullDesc: 'Flutter 是 Google 的 UI 工具包，用于在移动、Web 和桌面端构建精美的原生应用。',
      category: '开发工具',
      iconUrl: 'https://caixy-disk.oss-cn-hangzhou.aliyuncs.com/apps/icons/flutter/flutter/icon.png',
      version: '3.19.0',
      installCount: 8930,
      ratingAvg: 4.7,
      ratingCount: 210,
      status: 'PUBLISHED',
      githubRepoUrl: 'https://github.com/flutter/flutter',
      officialUrl: 'https://flutter.dev',
      pricingType: 'free',
    ),
    AppStoreApp(
      id: 3,
      slug: 'obsidian-3',
      name: 'Obsidian',
      shortDesc: '强大的知识管理工具',
      fullDesc: 'Obsidian 是一款基于本地 Markdown 文件的知识库工具，支持双向链接和图谱视图。',
      category: '效率办公',
      iconUrl: 'https://caixy-disk.oss-cn-hangzhou.aliyuncs.com/apps/icons/obsidianmd/obsidian/icon.png',
      version: '1.5.0',
      installCount: 6540,
      ratingAvg: 4.9,
      ratingCount: 180,
      status: 'PUBLISHED',
      githubRepoUrl: 'https://github.com/obsidianmd',
      officialUrl: 'https://obsidian.md',
      pricingType: 'free',
    ),
  ];

  static final List<AppCategory> categories = [
    AppCategory(key: 'all', name: '全部', icon: 'apps'),
    AppCategory(key: '1', name: '开发工具', icon: 'code'),
    AppCategory(key: '2', name: '效率办公', icon: 'work_outline'),
    AppCategory(key: '3', name: '媒体娱乐', icon: 'music_note'),
    AppCategory(key: '4', name: '系统工具', icon: 'settings'),
    AppCategory(key: '6', name: '设计创意', icon: 'design_services'),
  ];

  static String? _categoryId(String? name) {
    const map = {
      '开发工具': '1',
      '效率办公': '2',
      '媒体娱乐': '3',
      '系统工具': '4',
      '网络通信': '5',
      '设计创意': '6',
      '游戏娱乐': '7',
      '教育学习': '8',
    };
    return map[name];
  }

  static List<AppStoreApp> browseApps({
    String? category,
    String? search,
    String sortBy = 'popular',
    int page = 1,
    int size = 20,
  }) {
    var result = List<AppStoreApp>.from(apps);
    if (category != null && category != 'all') {
      result = result.where((a) {
        return a.category == category || _categoryId(a.category) == category;
      }).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((a) =>
          a.name.toLowerCase().contains(q) ||
          (a.shortDesc?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (sortBy == 'popular') {
      result.sort((a, b) => b.installCount.compareTo(a.installCount));
    } else if (sortBy == 'newest') {
      result.sort((a, b) => b.id.compareTo(a.id));
    } else if (sortBy == 'rating') {
      result.sort((a, b) => (b.ratingAvg ?? 0).compareTo(a.ratingAvg ?? 0));
    }
    final start = (page - 1) * size;
    if (start >= result.length) return [];
    return result.sublist(start, (start + size).clamp(0, result.length));
  }

  static AppStoreApp? getAppDetail(String slug) {
    try {
      return apps.firstWhere((a) => a.slug == slug);
    } catch (_) {
      return null;
    }
  }

  static List<AppStoreApp> getPopularApps({int limit = 10}) {
    final sorted = List<AppStoreApp>.from(apps)
      ..sort((a, b) => b.installCount.compareTo(a.installCount));
    return sorted.take(limit).toList();
  }

  static List<AppStoreApp> getLatestApps({int limit = 10}) {
    final sorted = List<AppStoreApp>.from(apps)
      ..sort((a, b) => b.id.compareTo(a.id));
    return sorted.take(limit).toList();
  }

  static List<AppRating> getAppRatings(int appId) {
    return [
      AppRating(
        id: 1,
        rating: 5,
        comment: '非常好用，推荐！',
        createdAt: DateTime(2024, 3, 15),
        userName: 'user1@example.com',
      ),
      AppRating(
        id: 2,
        rating: 4,
        comment: '功能强大，但界面可以再优化。',
        createdAt: DateTime(2024, 3, 10),
        userName: 'user2@example.com',
      ),
    ];
  }
}
