import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  String _subject = '';
  bool _loading = true;
  final _controller = TextEditingController();
  bool _sending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.conversationMessages(widget.conversationId));
      if (mounted) setState(() {
        _messages = List<Map<String, dynamic>>.from(res.data['messages'] ?? []);
        _subject = res.data['conversation']?['subject'] ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(Endpoints.sendMessage(widget.conversationId), data: {'content': _controller.text.trim()});
      _controller.clear();
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_subject.isNotEmpty ? _subject : 'Chat')),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isSystem = m['message_type'] == 'system';
                    if (isSystem) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(m['content'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                      ));
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['sender_name'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Text(m['content'] ?? '', style: const TextStyle(fontSize: 14)),
                        ),
                      ]),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Type a message...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder()),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            IconButton(
              icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppTheme.primary),
              onPressed: _send,
            ),
          ]),
        ),
      ]),
    );
  }
}
