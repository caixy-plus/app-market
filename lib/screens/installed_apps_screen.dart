import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import '../models/app_store_app.dart';
import 'app_detail_screen.dart';

class InstalledAppsScreen extends StatelessWidget {
  const InstalledAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStoreProvider>();
    final installedIds = provider.installedAppIds;

    // 从所有已加载的应用中查找已安装应用
    final allApps = <AppStoreApp>[
      ...provider.popularApps,
      ...provider.latestApps,
      ...provider.apps,
    ];
    final result = installedIds
        .map((id) => allApps.cast<AppStoreApp?>().firstWhere(
              (a) => a?.id == id,
              orElse: () => null,
            ))
        .whereType<AppStoreApp>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('已安装应用')),
      body: result.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无已安装应用', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: result.length,
              itemBuilder: (context, index) {
                final app = result[index];
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
                    subtitle: Text(app.category ?? '其他'),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          await provider.uninstallApp(app.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已卸载')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('卸载失败: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('卸载'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AppDetailScreen(slug: app.slug)),
                      );
                    },
                  ),
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
