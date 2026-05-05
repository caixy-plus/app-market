import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import 'app_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStoreProvider>().setSearch('');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<AppStoreProvider>().setSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索应用名称、标签...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onSearch('');
                    },
                  )
                : null,
          ),
          onSubmitted: _onSearch,
          onChanged: (value) {
            if (value.isEmpty) _onSearch('');
            setState(() {});
          },
        ),
        actions: [
          TextButton(
            onPressed: () => _onSearch(_controller.text),
            child: const Text('搜索'),
          ),
        ],
      ),
      body: Consumer<AppStoreProvider>(
        builder: (context, provider, child) {
          if (provider.loading && provider.apps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    provider.currentSearch.isEmpty
                        ? '输入关键词开始搜索'
                        : '没有找到相关应用',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.apps.length,
            itemBuilder: (context, index) {
              final app = provider.apps[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: app.iconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AppDetailScreen(slug: app.slug)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
