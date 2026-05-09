import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/app_store_app.dart';

class AppStoreProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<AppStoreApp> _popularApps = [];
  List<AppStoreApp> _latestApps = [];
  List<AppStoreApp> _apps = [];
  AppStoreApp? _selectedApp;
  List<AppRating> _selectedAppRatings = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentCategoryId = 'all';
  String _currentSortBy = 'popular';
  String _currentSearch = '';
  final Set<int> _installedAppIds = {};
  final Set<int> _installingAppIds = {};
  List<AppCategory> _categories = [];
  bool _categoriesLoading = false;

  List<AppStoreApp> get popularApps => _popularApps;
  List<AppStoreApp> get latestApps => _latestApps;
  List<AppStoreApp> get apps => _apps;
  AppStoreApp? get selectedApp => _selectedApp;
  List<AppRating> get selectedAppRatings => _selectedAppRatings;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get currentCategory => _currentCategoryId;
  String get currentSortBy => _currentSortBy;
  String get currentSearch => _currentSearch;
  Set<int> get installedAppIds => _installedAppIds;
  Set<int> get installingAppIds => _installingAppIds;
  List<AppCategory> get categories => _categories;
  bool get categoriesLoading => _categoriesLoading;

  Future<void> loadPopularApps() async {
    try {
      _popularApps = await _api.getPopularApps(limit: 10);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('loadPopularApps error: $e');
      notifyListeners();
    }
  }

  Future<void> loadLatestApps() async {
    try {
      _latestApps = await _api.getLatestApps(limit: 10);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('loadLatestApps error: $e');
      notifyListeners();
    }
  }

  Future<void> loadApps({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _apps = [];
      _hasMore = true;
    }

    if (_loading || !_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.browseApps(
        category: _currentCategoryId == 'all' ? null : _currentCategoryId,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        sortBy: _currentSortBy,
        page: _currentPage,
        size: 20,
      );
      debugPrint('loadApps success: ${result.length} items');

      if (refresh) {
        _apps = result;
      } else {
        _apps.addAll(result);
      }
      _hasMore = result.length == 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
      debugPrint('loadApps error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _categoriesLoading = true;
    notifyListeners();
    try {
      final data = await _api.getCategories();
      _categories = data.map((e) => AppCategory(
        key: e['id']?.toString() ?? '',
        name: e['name']?.toString() ?? '',
        icon: e['icon']?.toString(),
      )).toList();
      debugPrint('loadCategories success: ${_categories.length} items');
    } catch (e) {
      _error = e.toString();
      debugPrint('loadCategories error: $e');
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategory(String categoryId) async {
    _currentCategoryId = categoryId;
    await loadApps(refresh: true);
  }

  Future<void> setSortBy(String sortBy) async {
    _currentSortBy = sortBy;
    await loadApps(refresh: true);
  }

  Future<void> setSearch(String search) async {
    _currentSearch = search;
    await loadApps(refresh: true);
  }

  Future<void> loadAppDetail(String slug) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedApp = await _api.getAppDetail(slug);
      notifyListeners(); // show detail ASAP, load ratings after
      if (_selectedApp != null) {
        _selectedAppRatings = await _api.getAppRatings(_selectedApp!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearSelectedApp() {
    _selectedApp = null;
    notifyListeners();
  }

  Future<String?> installApp(int appId) async {
    _installingAppIds.add(appId);
    notifyListeners();
    try {
      final downloadUrl = await _api.installApp(appId);
      return downloadUrl;
    } catch (e) {
      rethrow;
    } finally {
      _installingAppIds.remove(appId);
      notifyListeners();
    }
  }

  Future<void> uninstallApp(int appId) async {
    try {
      await _api.uninstallApp(appId);
      _installedAppIds.remove(appId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rateApp(int appId, int rating, {String? comment}) async {
    try {
      await _api.rateApp(appId, rating: rating, comment: comment);
      if (_selectedApp != null && _selectedApp!.id == appId) {
        final oldCount = _selectedApp!.ratingCount ?? 0;
        final oldAvg = _selectedApp!.ratingAvg ?? 0.0;
        final newAvg = (oldAvg * oldCount + rating) / (oldCount + 1);
        _selectedApp = AppStoreApp(
          id: _selectedApp!.id,
          slug: _selectedApp!.slug,
          name: _selectedApp!.name,
          shortDesc: _selectedApp!.shortDesc,
          fullDesc: _selectedApp!.fullDesc,
          category: _selectedApp!.category,
          tags: _selectedApp!.tags,
          iconUrl: _selectedApp!.iconUrl,
          screenshots: _selectedApp!.screenshots,
          pricingType: _selectedApp!.pricingType,
          priceCents: _selectedApp!.priceCents,
          version: _selectedApp!.version,
          manifestUrl: _selectedApp!.manifestUrl,
          installCount: _selectedApp!.installCount,
          ratingAvg: double.parse(newAvg.toStringAsFixed(2)),
          ratingCount: oldCount + 1,
          auditStatus: _selectedApp!.auditStatus,
          status: _selectedApp!.status,
          publishedAt: _selectedApp!.publishedAt,
          createdAt: _selectedApp!.createdAt,
          updatedAt: _selectedApp!.updatedAt,
        );
        // Refresh ratings list after submitting
        _selectedAppRatings = await _api.getAppRatings(appId);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
