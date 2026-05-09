import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/app_store_app.dart';
import 'app_detail_screen.dart';

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  final ApiClient _api = ApiClient();
  List<MyRating> _ratings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ratings = await _api.getMyRatings();
      if (mounted) setState(() => _ratings = ratings);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的评分')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                )
              : _ratings.isEmpty
                  ? const Center(child: Text('暂无评分记录'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _ratings.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = _ratings[index];
                          return ListTile(
                            leading: r.appIcon != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(r.appIcon!, width: 48, height: 48, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 48)),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.apps),
                                  ),
                            title: Text(r.appName ?? '应用 #${r.appId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < r.rating ? Icons.star : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  )),
                                ),
                                if (r.comment != null && r.comment!.isNotEmpty)
                                  Text(r.comment!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (r.createdAt != null)
                                  Text(
                                    '${r.createdAt!.year}-${r.createdAt!.month.toString().padLeft(2, '0')}-${r.createdAt!.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppDetailScreen(slug: r.appId.toString()),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
