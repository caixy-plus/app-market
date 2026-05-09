import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import '../models/app_store_app.dart';
import 'app_detail_screen.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppStoreProvider>();
      if (provider.apps.isEmpty) {
        provider.loadApps(refresh: true);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    await context.read<AppStoreProvider>().loadApps();
  }

  Future<void> _refresh() async {
    await context.read<AppStoreProvider>().loadApps(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用列表'),
        actions: [
          _buildSortMenu(),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildAppList()),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    return Consumer<AppStoreProvider>(
      builder: (context, provider, child) {
        return PopupMenuButton<String>(
          initialValue: provider.currentSortBy,
          onSelected: (value) => provider.setSortBy(value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'popular', child: Text('按热门')),
            const PopupMenuItem(value: 'newest', child: Text('按最新')),
            const PopupMenuItem(value: 'rating', child: Text('按评分')),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.currentSortBy == 'popular'
                      ? '热门'
                      : provider.currentSortBy == 'newest'
                          ? '最新'
                          : '评分',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<AppStoreProvider>(
      builder: (context, provider, child) {
        final categories = [
          AppCategory(key: 'all', name: '全部'),
          ...provider.categories,
        ];
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = provider.currentCategory == cat.key;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (_) => provider.setCategory(cat.key),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppList() {
    return Consumer<AppStoreProvider>(
      builder: (context, provider, child) {
        if (provider.loading && provider.apps.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无应用', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.apps.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.apps.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _AppCard(app: provider.apps[index]);
            },
          ),
        );
      },
    );
  }
}

class _AppCard extends StatelessWidget {
  final AppStoreApp app;

  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AppDetailScreen(slug: app.slug)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey[200],
                ),
                child: app.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          app.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(app.name),
                        ),
                      )
                    : _buildPlaceholder(app.name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.displayDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTag(app.category ?? '其他', Color(0xFF2D5BE3)),
                        const SizedBox(width: 6),
                        _buildTag(app.displayPrice, app.isFree ? Colors.green : Colors.orange),
                        const Spacer(),
                        if (app.ratingAvg != null) ...[
                          Icon(Icons.star, size: 14, color: Colors.orange[400]),
                          const SizedBox(width: 2),
                          Text(
                            app.ratingAvg!.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
