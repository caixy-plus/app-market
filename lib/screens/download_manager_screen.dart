import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import 'app_detail_screen.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('下载管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '下载中'),
              Tab(text: '已完成'),
            ],
          ),
        ),
        body: Consumer<DownloadProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _buildDownloadingTab(provider),
                _buildCompletedTab(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDownloadingTab(DownloadProvider provider) {
    final tasks = provider.downloadingTasks;
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无下载任务', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildIcon(task.iconUrl, task.appName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.appName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => provider.cancelDownload(task.appId),
                      tooltip: '取消下载',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2D5BE3)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab(DownloadProvider provider) {
    final tasks = provider.completedTasks;
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无已完成的下载', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _buildIcon(task.iconUrl, task.appName),
            title: Text(
              task.appName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '下载完成',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.check_circle, color: Color(0xFF059669)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppDetailScreen(slug: task.appName.toLowerCase()),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildIcon(String? iconUrl, String name) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: iconUrl != null && iconUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(name),
              ),
            )
          : _placeholder(name),
    );
  }

  Widget _placeholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
