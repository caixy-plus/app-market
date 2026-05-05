import '../models/app_store_app.dart';

class MockData {
  static final List<AppStoreApp> apps = [];
  static final List<AppCategory> categories = [];

  static List<AppStoreApp> browseApps({
    String? category,
    String? search,
    String sortBy = 'popular',
    int page = 1,
    int size = 20,
  }) => [];

  static AppStoreApp? getAppDetail(String slug) => null;

  static List<AppStoreApp> getPopularApps({int limit = 10}) => [];

  static List<AppStoreApp> getLatestApps({int limit = 10}) => [];
}
