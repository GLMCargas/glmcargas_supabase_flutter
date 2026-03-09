import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  RealtimeChannel? _channel;

  bool _loading = true;
  bool _sending = false;
  String? _roomId;

  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Pegue o roomId dos argumentos, só 1 vez
    if (_roomId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['roomId'] != null) {
      _roomId = args['roomId'].toString();
      _init();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para usar o chat.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      await _loadHistory();
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadHistory() async {
    final roomId = _roomId!;
    final data = await _supabase
        .from('chat_messages')
        .select('id, room_id, sender_user_id, message, created_at')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    _messages
      ..clear()
      ..addAll((data as List).map((m) => _ChatMessage.fromMap(m)));
  }

  void _subscribeRealtime() {
    final roomId = _roomId!;
    _channel = _supabase.channel('room:$roomId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record == null) return;

            final msg = _ChatMessage.fromMap(record);

            // Evita duplicar (caso o insert local chegue via realtime)
            if (_messages.any((m) => m.id == msg.id)) return;

            if (mounted) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final roomId = _roomId;
    final user = _supabase.auth.currentUser;
    final text = _textController.text.trim();

    if (roomId == null || user == null) return;
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      _textController.clear();

      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'sender_user_id': user.id,
        'message': text,
      });

      // Não adiciona localmente: o realtime insere e mantém consistente
      _scrollToBottom();
    } catch (e) {
      _textController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com a empresa'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_roomId == null)
              ? const Center(child: Text('RoomId não informado.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMine = userId != null && m.senderUserId == userId;

                          return Align(
                            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMine ? Colors.blueGrey.shade200 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.message ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(m.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Digite sua mensagem…',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: _sending ? null : _sendMessage,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChatMessage {
  final String id;
  final String roomId;
  final String senderUserId;
  final String? message;
  final DateTime createdAt;

  _ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUserId,
    required this.message,
    required this.createdAt,
  });

  factory _ChatMessage.fromMap(Map<String, dynamic> map) {
    return _ChatMessage(
      id: map['id'].toString(),
      roomId: map['room_id'].toString(),
      senderUserId: map['sender_user_id'].toString(),
      message: map['message']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}