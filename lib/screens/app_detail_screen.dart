import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_store_provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_store_app.dart';

class AppDetailScreen extends StatefulWidget {
  final String slug;

  const AppDetailScreen({super.key, required this.slug});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  bool _installing = false;
  bool _rating = false;
  double _userRating = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStoreProvider>().loadAppDetail(widget.slug);
    });
  }

  String _currentPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  bool _isSupported(AppStoreApp app) {
    final platforms = app.supportedPlatforms;
    if (platforms == null || platforms.isEmpty) return true;
    return platforms.contains(_currentPlatform());
  }

  Future<void> _handleInstall(AppStoreApp app) async {
    setState(() => _installing = true);
    try {
      final provider = context.read<AppStoreProvider>();
      if (provider.installedAppIds.contains(app.id)) {
        await provider.uninstallApp(app.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已卸载')),
          );
        }
      } else {
        await provider.installApp(app.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('安装成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Future<void> _handleOpen(AppStoreApp app) async {
    final url = app.officialUrl ?? app.manifestUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无下载链接')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  Future<void> _handleGithub(AppStoreApp app) async {
    final repoUrl = app.githubRepoUrl;
    if (repoUrl == null || repoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无 GitHub 源码链接')),
      );
      return;
    }
    final uri = Uri.parse(repoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  Future<void> _handleCheckUpdate(AppStoreApp app) async {
    final repoUrl = app.githubRepoUrl;
    if (repoUrl == null || repoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无 GitHub 源码链接')),
      );
      return;
    }
    // 跳转到 GitHub releases 页面
    final releasesUrl = repoUrl.endsWith('/')
        ? '${repoUrl}releases'
        : '$repoUrl/releases';
    final uri = Uri.parse(releasesUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开链接')),
        );
      }
    }
  }

  Future<void> _handleRate(AppStoreApp app) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('为应用评分'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('点击星星评分'),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _userRating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => _userRating = index + 1);
                        },
                      );
                    }),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _rating = true);
                try {
                  await context.read<AppStoreProvider>().rateApp(
                    app.id,
                    _userRating.toInt(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('评分成功')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('评分失败: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _rating = false);
                }
              },
              child: const Text('提交'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          if (provider.loading && provider.selectedApp == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final app = provider.selectedApp;
          if (app == null) {
            return const Center(child: Text('应用不存在或加载失败'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(app),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(app),
                    _buildActionButtons(app),
                    _buildInfoSection(app),
                    _buildDescription(app),
                    _buildRatingSection(app),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AppStoreApp app) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1890FF), Color(0xFF4169E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Hero(
              tag: 'app_icon_${app.id}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: app.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          app.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(app.name, 40),
                        ),
                      )
                    : _buildPlaceholder(app.name, 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStoreApp app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  app.category ?? '其他',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: app.isFree
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  app.displayPrice,
                  style: TextStyle(
                    fontSize: 12,
                    color: app.isFree ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (app.ratingAvg != null) ...[
                Icon(Icons.star, size: 18, color: Colors.orange[400]),
                const SizedBox(width: 4),
                Text(
                  app.ratingAvg!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${app.ratingCount ?? 0} 评价)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
              const Spacer(),
              Icon(Icons.download, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${app.installCount} 次安装',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppStoreApp app) {
    final provider = context.watch<AppStoreProvider>();
    final isInstalled = provider.installedAppIds.contains(app.id);
    final supported = _isSupported(app);
    final hasGithub = app.githubRepoUrl != null && app.githubRepoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: supported && !_installing ? () => _handleInstall(app) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInstalled ? Colors.grey[200] : Colors.blue,
                    foregroundColor: isInstalled ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _installing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(isInstalled ? Icons.delete_outline : Icons.download),
                  label: Text(
                    !supported
                        ? '不支持当前平台'
                        : isInstalled
                            ? '卸载'
                            : '安装',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleOpen(app),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('访问官网', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
          if (hasGithub) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleGithub(app),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.code, size: 18),
                    label: const Text('GitHub 源码', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleCheckUpdate(app),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.teal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.update, size: 18, color: Colors.teal),
                    label: const Text('检查更新', style: TextStyle(fontSize: 15, color: Colors.teal)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(AppStoreApp app) {
    final items = [
      if (app.version != null) ('版本', app.version!),
      if (app.pricingType != null) ('定价', _pricingLabel(app.pricingType!)),
      if (app.status != null) ('状态', _statusLabel(app.status!)),
      if (app.createdAt != null) ('上架', _formatDate(app.createdAt!)),
      if (app.githubRepoUrl != null && app.githubRepoUrl!.isNotEmpty)
        ('GitHub', app.githubRepoUrl!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用信息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) {
              final isUrl = item.$1 == 'GitHub';
              return InkWell(
                onTap: isUrl
                    ? () async {
                        final uri = Uri.parse(item.$2);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUrl ? '查看仓库' : item.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUrl ? Colors.blue : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(AppStoreApp app) {
    final desc = app.fullDesc ?? app.shortDesc;
    if (desc == null || desc.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用介绍',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(AppStoreApp app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '评分与评论',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _rating ? null : () => _handleRate(app),
                child: _rating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('我要评分'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (app.ratingAvg != null)
            Row(
              children: [
                Text(
                  app.ratingAvg!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (app.ratingAvg!.round())
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${app.ratingCount ?? 0} 条评价',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              '暂无评分',
              style: TextStyle(color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name, double fontSize) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _pricingLabel(String type) {
    switch (type) {
      case 'free':
        return '免费';
      case 'freemium':
        return '免费增值';
      case 'paid':
        return '付费';
      case 'subscription':
        return '订阅';
      default:
        return type;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PUBLISHED':
        return '已发布';
      case 'DRAFT':
        return '草稿';
      case 'SUBMITTED':
        return '待审核';
      case 'REVIEWING':
        return '审核中';
      case 'DELISTED':
        return '已下架';
      case 'SUSPENDED':
        return '已暂停';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
