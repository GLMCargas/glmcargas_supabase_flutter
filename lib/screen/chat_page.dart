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
    final data = await _supabase
        .from('chat_messages')
        .select('id, room_id, sender_user_id, message, created_at')
        .eq('room_id', _roomId!)
        .order('created_at', ascending: true);

    _messages
      ..clear()
      ..addAll((data as List).map((m) => _ChatMessage.fromMap(m)));
  }

  void _subscribeRealtime() {
    _channel = _supabase.channel('room:$_roomId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _roomId!,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record == null) return;

            final msg = _ChatMessage.fromMap(record);

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
    final text = _textController.text.trim();
    final user = _supabase.auth.currentUser;

    if (text.isEmpty || _roomId == null || user == null || _sending) return;

    setState(() => _sending = true);

    try {
      _textController.clear();

      await _supabase.from('chat_messages').insert({
        'room_id': _roomId,
        'sender_user_id': user.id,
        'message': text,
      });
    } catch (e) {
      _textController.text = text;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 430,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange),
                      ),
                      const Icon(Icons.local_shipping, color: Colors.orange, size: 28),
                      const SizedBox(width: 6),
                      const Text(
                        'GLM',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'CARGAS',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/chats'),
                        child: const Icon(Icons.chat_bubble, color: Colors.orange, size: 26),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Chat com a empresa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _roomId == null
                          ? const Center(child: Text('RoomId não informado'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _messages.length,
                              itemBuilder: (context, i) {
                                final m = _messages[i];
                                final isMine = userId != null && m.senderUserId == userId;

                                return Align(
                                  alignment: isMine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 290),
                                    margin: const EdgeInsets.symmetric(vertical: 5),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.orange.shade200
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                                        bottomRight: Radius.circular(isMine ? 4 : 18),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
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
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            filled: true,
                            fillColor: Colors.orange.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade400,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: _sending ? null : _sendMessage,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // RODAPÉ
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade300,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/home'),
                        child: const Icon(Icons.home_outlined, size: 32, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/perfilMotorista'),
                        child: const Icon(Icons.person_outline, size: 32, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/chats'),
                        child: const Icon(Icons.chat_bubble, size: 32, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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