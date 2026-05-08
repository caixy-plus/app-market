class AppStoreApp {
  final int id;
  final String slug;
  final String name;
  final String? shortDesc;
  final String? fullDesc;
  final String? category;
  final String? tags;
  final String? iconUrl;
  final String? screenshots;
  final String? pricingType;
  final int? priceCents;
  final String? version;
  final String? manifestUrl;
  final int installCount;
  final double? ratingAvg;
  final int? ratingCount;
  final int? auditStatus;
  final String? status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? supportedPlatforms;
  final String? githubRepoUrl;
  final String? officialUrl;

  AppStoreApp({
    required this.id,
    required this.slug,
    required this.name,
    this.shortDesc,
    this.fullDesc,
    this.category,
    this.tags,
    this.iconUrl,
    this.screenshots,
    this.pricingType,
    this.priceCents,
    this.version,
    this.manifestUrl,
    this.installCount = 0,
    this.ratingAvg,
    this.ratingCount,
    this.auditStatus,
    this.status,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.supportedPlatforms,
    this.githubRepoUrl,
    this.officialUrl,
  });

  factory AppStoreApp.fromJson(Map<String, dynamic> json) {
    // Helper to read both snake_case (backend) and camelCase (mock)
    String? s(String snake, String camel) {
      final v = json[snake] ?? json[camel];
      if (v == null) return null;
      return v.toString();
    }

    int? i(String snake, String camel) {
      final v = json[snake] ?? json[camel];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    double? d(String snake, String camel) {
      final v = json[snake] ?? json[camel];
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // Category mapping (backend numeric id -> display name)
    String? mapCategory(dynamic val) {
      if (val == null) return null;
      final map = <String, String>{
        '1': '开发工具',
        '2': '效率办公',
        '3': '媒体娱乐',
        '4': '系统工具',
        '5': '网络通信',
        '6': '设计创意',
        '7': '游戏娱乐',
        '8': '教育学习',
      };
      return map[val.toString()] ?? val.toString();
    }

    // Status mapping (backend int -> StoreAppStatus string)
    String? mapStatus(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      final intMap = {0: 'DRAFT', 1: 'PUBLISHED', 2: 'DELISTED'};
      return intMap[val] ?? val.toString();
    }

    // Generate slug from name + id
    String makeSlug(String name, int id) {
      final clean = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-');
      final base = clean.length <= 30 ? clean : clean.substring(0, 30);
      return base.isNotEmpty ? '$base-$id' : id.toString();
    }

    final id = i('id', 'id') ?? 0;
    final name = s('name', 'name') ?? '';

    return AppStoreApp(
      id: id,
      slug: s('slug', 'slug') ?? makeSlug(name, id),
      name: name,
      shortDesc: s('description', 'description') ?? s('short_desc', 'shortDesc'),
      fullDesc: s('description', 'description') ?? s('full_desc', 'fullDesc'),
      category: mapCategory(json['category_id'] ?? json['categoryId'] ?? json['category']),
      tags: s('tags', 'tags'),
      iconUrl: s('logo_url', 'logoUrl') ?? s('icon_url', 'iconUrl'),
      screenshots: s('screenshots', 'screenshots'),
      pricingType: s('pricing_type', 'pricingType') ?? 'free',
      priceCents: i('price_cents', 'priceCents'),
      version: s('version', 'version'),
      manifestUrl: s('manifest_url', 'manifestUrl'),
      installCount: i('view_count', 'viewCount') ?? i('install_count', 'installCount') ?? 0,
      ratingAvg: d('rating', 'rating') ?? d('rating_avg', 'ratingAvg'),
      ratingCount: i('rating_count', 'ratingCount'),
      auditStatus: i('audit_status', 'auditStatus'),
      status: mapStatus(json['status']),
      publishedAt: _parseDateTime(json['published_at'] ?? json['publishedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
      supportedPlatforms: json['supportedPlatforms'] != null
          ? (json['supportedPlatforms'] as List).cast<String>()
          : null,
      githubRepoUrl: s('github_repo', 'githubRepo'),
      officialUrl: s('official_url', 'officialUrl'),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      // Unix timestamp (seconds)
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt(), isUtc: true);
    }
    return null;
  }

  String get displayDescription => shortDesc ?? fullDesc ?? '暂无描述';

  String get displayPrice {
    if (pricingType == 'free') return '免费';
    if (priceCents != null && priceCents! > 0) {
      return '¥${(priceCents! / 100).toStringAsFixed(2)}';
    }
    return '免费';
  }

  bool get isFree => pricingType == 'free' || (priceCents == null || priceCents == 0);
}

class AppCategory {
  final String key;
  final String name;
  final String? icon;

  AppCategory({required this.key, required this.name, this.icon});
}

class AppRating {
  final int id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String userName;
  final String? userAvatar;

  AppRating({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    required this.userName,
    this.userAvatar,
  });

  factory AppRating.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return AppRating(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment']?.toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? '匿名用户',
      userAvatar: json['user_avatar']?.toString() ?? json['userAvatar']?.toString(),
    );
  }
}
