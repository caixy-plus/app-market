import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_store_app.dart';

enum DownloadStatus { downloading, completed, cancelled, failed }

class DownloadTask {
  final int appId;
  final String appName;
  final String? iconUrl;
  final DateTime startTime;
  DownloadStatus status;
  double progress;
  String? filePath;
  String? error;

  DownloadTask({
    required this.appId,
    required this.appName,
    this.iconUrl,
    required this.startTime,
    this.status = DownloadStatus.downloading,
    this.progress = 0.0,
    this.filePath,
    this.error,
  });
}

class DownloadProvider with ChangeNotifier {
  final Map<int, DownloadTask> _tasks = {};
  final Map<int, CancelToken> _cancelTokens = {};

  List<DownloadTask> get downloadingTasks =>
      _tasks.values.where((t) => t.status == DownloadStatus.downloading).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

  List<DownloadTask> get completedTasks =>
      _tasks.values.where((t) => t.status == DownloadStatus.completed).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

  DownloadTask? getTask(int appId) => _tasks[appId];

  bool isDownloading(int appId) =>
      _tasks[appId]?.status == DownloadStatus.downloading;

  Future<void> startDownload(AppStoreApp app, {String? downloadUrl}) async {
    if (_tasks.containsKey(app.id) &&
        _tasks[app.id]!.status == DownloadStatus.downloading) {
      return;
    }

    final task = DownloadTask(
      appId: app.id,
      appName: app.name,
      iconUrl: app.iconUrl,
      startTime: DateTime.now(),
    );
    _tasks[app.id] = task;
    notifyListeners();

    // No download URL → just mark as completed (API-only install)
    if (downloadUrl == null || downloadUrl.isEmpty) {
      task.status = DownloadStatus.completed;
      notifyListeners();
      return;
    }

    // Request permissions on Android
    if (Platform.isAndroid) {
      // For Android < 11, request legacy storage permission
      // For Android 11+, app-specific dirs don't need permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted && !storageStatus.isLimited) {
        // On Android 11+, storage permission may be denied but we can still use app-specific dirs
        // Check if we're on Android 11+ by checking if we can write to app-specific dir
        try {
          final testDir = await getExternalStorageDirectory();
          if (testDir == null) {
            task.status = DownloadStatus.failed;
            task.error = '无法访问存储目录';
            notifyListeners();
            return;
          }
        } catch (e) {
          task.status = DownloadStatus.failed;
          task.error = '需要存储权限才能下载';
          notifyListeners();
          return;
        }
      }
    }

    final cancelToken = CancelToken();
    _cancelTokens[app.id] = cancelToken;

    try {
      // Use app-specific external storage for downloaded APKs
      // This works on all Android versions including Android 10+ scoped storage
      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
        // Create a dedicated downloads subdirectory
        final downloadsDir = Directory('${baseDir!.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        baseDir = downloadsDir;
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${app.slug}_${app.version ?? 'latest'}.apk'
          .replaceAll(RegExp(r'[^\w\.-]'), '_');
      final savePath = '${baseDir.path}/$fileName';

      // Remove existing file if present
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      final dio = Dio();
      // Configure Dio for GitHub and other download URLs
      dio.options.followRedirects = true;
      dio.options.maxRedirects = 5;
      dio.options.validateStatus = (status) => status != null && status < 500;
      dio.options.headers = {
        'User-Agent': 'AppHub/1.0 (Android Download)',
        'Accept': '*/*',
      };

      debugPrint('Starting download from: $downloadUrl');
      debugPrint('Save path: $savePath');

      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          debugPrint('Download progress: $received / $total');
          if (total <= 0) {
            // Unknown total size, show indeterminate progress
            task.progress = 0.5;
          } else {
            task.progress = (received / total).clamp(0.0, 0.99);
          }
          notifyListeners();
        },
      );

      task.progress = 1.0;
      task.filePath = savePath;
      task.status = DownloadStatus.completed;
      notifyListeners();

      // Auto-install on Android
      if (Platform.isAndroid) {
        await _installApk(savePath, app.name);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.type} - ${e.message}');
      debugPrint('Response status: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      if (CancelToken.isCancel(e)) {
        task.status = DownloadStatus.cancelled;
      } else {
        task.status = DownloadStatus.failed;
        task.error = '下载失败: ${e.message ?? e.type.toString()}';
      }
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Download error: $e');
      debugPrint('Stack trace: $stackTrace');
      task.status = DownloadStatus.failed;
      task.error = '下载失败: $e';
      notifyListeners();
    } finally {
      _cancelTokens.remove(app.id);
    }
  }

  Future<void> _installApk(String filePath, String appName) async {
    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      // OpenFilex result handling
      if (result.type == ResultType.done) {
        // Installation dialog shown successfully
        debugPrint('APK installation dialog shown for $appName');
      } else if (result.type == ResultType.noAppToOpen) {
        // No app to handle APK - this shouldn't happen on Android
        debugPrint('No app found to open APK for $appName');
      } else if (result.type == ResultType.error) {
        debugPrint('Error opening APK for $appName: ${result.message}');
      }
    } catch (e) {
      debugPrint('Installation error for $appName: $e');
    }
  }

  void cancelDownload(int appId) {
    _cancelTokens[appId]?.cancel();
    _cancelTokens.remove(appId);

    final task = _tasks[appId];
    if (task != null) {
      task.status = DownloadStatus.cancelled;
    }
    notifyListeners();
  }

  void removeTask(int appId) {
    _cancelTokens[appId]?.cancel();
    _cancelTokens.remove(appId);
    _tasks.remove(appId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    super.dispose();
  }
}
