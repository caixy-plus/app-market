import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import '../models/app_store_app.dart';
import 'app_detail_screen.dart';
import 'app_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<AppStoreProvider>();
    await Future.wait([
      provider.loadPopularApps(),
      provider.loadLatestApps(),
      provider.loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              _buildErrorBanner(),
              _buildSearchHeader(),
              _buildBanner(),
              _buildCategories(),
              _buildPopularSection(),
              _buildLatestSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return SliverToBoxAdapter(
      child: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          if (provider.error == null || provider.error!.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              '请求失败: ${provider.error}',
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  '搜索应用...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D5BE3), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '发现优质应用',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '汇集开源社区精选工具',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String? name) {
    switch (name) {
      case '开发工具':
        return Icons.code;
      case '效率办公':
        return Icons.work_outline;
      case '设计创意':
        return Icons.design_services;
      case '媒体娱乐':
        return Icons.movie;
      case '系统工具':
        return Icons.settings;
      case '网络通信':
        return Icons.language;
      case '游戏娱乐':
        return Icons.sports_esports;
      case '教育学习':
        return Icons.school;
      default:
        return Icons.apps;
    }
  }

  Color _categoryColor(int index) {
    final colors = [
      const Color(0xFF2D5BE3),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFFE11D48),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          final categories = [
            AppCategory(key: 'all', name: '全部', icon: 'apps'),
            ...provider.categories,
          ];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _CategoryItem(
                  label: cat.name,
                  icon: _categoryIcon(cat.name),
                  color: _categoryColor(index),
                  onTap: () {
                    provider.setCategory(cat.key);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppListScreen()),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularSection() {
    return SliverToBoxAdapter(
      child: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('热门应用', () {
                provider.setSortBy('popular');
                provider.setCategory('all');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppListScreen()),
                );
              }),
              SizedBox(
                height: 140,
                child: provider.popularApps.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: provider.popularApps.length,
                        itemBuilder: (_, index) {
                          return _AppCard(app: provider.popularApps[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLatestSection() {
    return SliverToBoxAdapter(
      child: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('最新上架', () {
                provider.setSortBy('newest');
                provider.setCategory('all');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppListScreen()),
                );
              }),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.latestApps.length,
                itemBuilder: (_, index) {
                  return _AppListTile(app: provider.latestApps[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text('查看更多'),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final AppStoreApp app;

  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppDetailScreen(slug: app.slug)),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              child: app.iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        app.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(app.name),
                      ),
                    )
                  : _buildPlaceholder(app.name),
            ),
            const SizedBox(height: 8),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '${app.installCount} 次安装',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  final AppStoreApp app;

  const _AppListTile({required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: app.iconUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  app.iconUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(app.name),
                ),
              )
            : _buildPlaceholder(app.name),
      ),
      title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        app.displayDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (app.ratingAvg != null) ...[
            Icon(Icons.star, size: 14, color: Colors.orange[400]),
            const SizedBox(width: 2),
            Text(app.ratingAvg!.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppDetailScreen(slug: app.slug)),
        );
      },
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
