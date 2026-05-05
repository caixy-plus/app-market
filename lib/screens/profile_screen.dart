import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import '../providers/auth_provider.dart';
import 'installed_apps_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildStats(context)),
            SliverToBoxAdapter(child: _buildMenu(context)),
            SliverToBoxAdapter(child: _buildSettings(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            auth.isLoggedIn ? (auth.email ?? auth.userName ?? '用户') : '未登录',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!auth.isLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('登录'),
            )
          else
            TextButton(
              onPressed: () => auth.logout(),
              child: const Text('退出登录'),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final provider = context.watch<AppStoreProvider>();
    final installedCount = provider.installedAppIds.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: '已安装',
              value: installedCount.toString(),
              icon: Icons.download_done,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Mock 模式',
              value: provider.isMockMode ? '开启' : '关闭',
              icon: provider.isMockMode ? Icons.cloud_off : Icons.cloud,
              color: provider.isMockMode ? Colors.orange : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final items = [
      (
        '已安装应用',
        Icons.download_done_outlined,
        Colors.green,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstalledAppsScreen()),
          );
        }
      ),
      (
        '我的评分',
        Icons.star_outline,
        Colors.orange,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('功能开发中')),
          );
        }
      ),
      (
        '意见反馈',
        Icons.feedback_outlined,
        Colors.purple,
        () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('功能开发中')),
          );
        }
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '功能菜单',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: items.asMap().entries.map((entry) {
                final item = entry.value;
                return ListTile(
                  leading: Icon(item.$2, color: item.$3),
                  title: Text(item.$1),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: item.$4,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final provider = context.watch<AppStoreProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_off, color: Colors.orange),
                  title: const Text('本地模拟模式'),
                  subtitle: const Text('服务端不可用时自动开启'),
                  value: provider.isMockMode,
                  onChanged: (value) => provider.setMockMode(value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('关于'),
                  subtitle: const Text('应用商城 v1.0.0'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '应用商城',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '基于 Flutter 开发的跨平台应用分发客户端',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
