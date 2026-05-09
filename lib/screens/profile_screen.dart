import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'download_manager_screen.dart';
import 'feedback_screen.dart';
import 'installed_apps_screen.dart';
import 'login_screen.dart';
import 'my_ratings_screen.dart';

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
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
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
              label: '应用数',
              value: '${provider.apps.length}',
              icon: Icons.apps,
              color: Color(0xFF2D5BE3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        '下载管理',
        Icons.download_outlined,
        Color(0xFF2D5BE3),
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadManagerScreen()),
          );
        },
      ),
      if (Platform.isAndroid)
        _MenuItem(
          '应用管理',
          Icons.apps_outlined,
          Color(0xFF059669),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstalledAppsScreen()),
            );
          },
        ),
      _MenuItem(
        '我的评分',
        Icons.star_outline,
        Color(0xFFD97706),
        () {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyRatingsScreen()),
          );
        },
      ),
      _MenuItem(
        '意见反馈',
        Icons.feedback_outlined,
        Color(0xFF7C3AED),
        () {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedbackScreen()),
          );
        },
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
                  leading: Icon(item.icon, color: item.color),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: item.onTap,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    String themeLabel;
    switch (themeProvider.mode) {
      case AppThemeMode.light:
        themeLabel = '亮色';
        break;
      case AppThemeMode.dark:
        themeLabel = '暗色';
        break;
      case AppThemeMode.auto:
        themeLabel = '跟随系统';
        break;
    }

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
                ListTile(
                  leading: Icon(Icons.color_lens_outlined, color: Theme.of(context).colorScheme.primary),
                  title: const Text('主题设置'),
                  subtitle: Text(themeLabel),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showThemePicker(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.system_update_outlined, color: Colors.teal),
                  title: const Text('检查更新'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已是最新版本')),
                    );
                  },
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

  void _showThemePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '主题设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('亮色'),
                trailing: themeProvider.mode == AppThemeMode.light
                    ? const Icon(Icons.check, color: Color(0xFF2D5BE3))
                    : null,
                onTap: () {
                  themeProvider.setMode(AppThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('暗色'),
                trailing: themeProvider.mode == AppThemeMode.dark
                    ? const Icon(Icons.check, color: Color(0xFF2D5BE3))
                    : null,
                onTap: () {
                  themeProvider.setMode(AppThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('跟随系统'),
                trailing: themeProvider.mode == AppThemeMode.auto
                    ? const Icon(Icons.check, color: Color(0xFF2D5BE3))
                    : null,
                onTap: () {
                  themeProvider.setMode(AppThemeMode.auto);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem(this.title, this.icon, this.color, this.onTap);
}
