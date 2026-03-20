import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});
  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.conversations, queryParameters: {'conversation_type': 'driver_dispatch'});
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(res.data['items'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('No messages', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    const Text('Contact dispatch from a trip detail page', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      final unread = c['unread_count'] ?? 0;
                      return ListTile(
                        title: Text(c['subject'] ?? 'Conversation', style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(c['last_message_preview'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        trailing: unread > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            : null,
                        onTap: () => context.push('/chat/${c['id']}'),
                      );
                    },
                  ),
                ),
    );
  }
}
