import 'package:flutter/material.dart';
import '../api/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _apiClient = ApiClient();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  List<Map<String, dynamic>> _models = [];
  String? _selectedModel;
  bool _loading = false;
  bool _loadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    try {
      final models = await _apiClient.getModels();
      setState(() {
        _models = models;
        _loadingModels = false;
        if (models.isNotEmpty) {
          _selectedModel = models[0]['id'] as String?;
        }
      });
    } catch (e) {
      setState(() => _loadingModels = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载模型失败: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _selectedModel == null || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _loading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final apiMessages = _messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final result = await _apiClient.chatCompletion(
        model: _selectedModel!,
        messages: apiMessages.cast<Map<String, String>>(),
      );
      final choices = result['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final content = message is Map ? (message['content'] ?? '') : '';
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: content.toString()));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: '错误: $e'));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 对话'),
        actions: [
          if (_loadingModels)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: '选择模型',
              onSelected: (id) => setState(() => _selectedModel = id),
              itemBuilder: (_) => _models.map((m) {
                final id = m['id'] as String;
                final name = m['name'] as String? ?? id;
                return PopupMenuItem(
                  value: id,
                  child: Row(
                    children: [
                      if (id == _selectedModel)
                        const Icon(Icons.check, size: 16, color: Colors.blue)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(name),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedModel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.blue.withValues(alpha: 0.05),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _models.firstWhere(
                      (m) => m['id'] == _selectedModel,
                      orElse: () => {'name': _selectedModel},
                    )['name'] as String? ?? _selectedModel!,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      '选择模型，开始对话',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(
                            msg.content,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loading ? null : _send,
                    icon: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage({required this.role, required this.content});
}
