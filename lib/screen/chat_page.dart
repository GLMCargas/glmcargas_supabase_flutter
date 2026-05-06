import 'package:app/widgets/glm_ui.dart';
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
  String _companyName = 'Empresa';

  final List<_ChatMessage> _messages = [];

  int _findPendingMatchIndex(_ChatMessage incoming) {
    return _messages.indexWhere(
      (message) =>
          message.isPending &&
          message.senderUserId == incoming.senderUserId &&
          message.message?.trim() == incoming.message?.trim(),
    );
  }

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
      final companyName =
          args['companyName']?.toString() ?? args['empresa']?.toString();

      if (companyName != null && companyName.trim().isNotEmpty) {
        _companyName = companyName.trim();
      }

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
      await _loadCompanyName();
      await _loadHistory();
      _subscribeRealtime();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar chat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadCompanyName() async {
    if (_roomId == null || _companyName != 'Empresa') return;

    final data = await _supabase
        .from('chat_rooms')
        .select('Viagens:viagem_id(empresa)')
        .eq('id', _roomId!)
        .maybeSingle();

    final viagem = (data?['Viagens'] as Map?) ?? {};
    final companyName = viagem['empresa']?.toString().trim();

    if (!mounted || companyName == null || companyName.isEmpty) return;

    setState(() => _companyName = companyName);
  }

  Future<void> _loadHistory() async {
    final data = await _supabase
        .from('chat_messages')
        .select('id, room_id, sender_user_id, message, created_at')
        .eq('room_id', _roomId!)
        .order('created_at', ascending: true);

    final loaded = (data as List).map((m) => _ChatMessage.fromMap(m)).toList();

    if (!mounted) return;

    setState(() {
      _messages
        ..clear()
        ..addAll(loaded);
    });
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
            if (record.isEmpty) return;

            final msg = _ChatMessage.fromMap(record);
            final alreadyExists = _messages.any((m) => m.id == msg.id);
            if (alreadyExists || !mounted) return;

            setState(() {
              final pendingIndex = _findPendingMatchIndex(msg);
              if (pendingIndex != -1) {
                _messages[pendingIndex] = msg;
              } else {
                _messages.add(msg);
              }
            });

            _scrollToBottom();
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final user = _supabase.auth.currentUser;

    if (text.isEmpty || _roomId == null || user == null || _sending) return;

    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMessage = _ChatMessage(
      id: tempId,
      roomId: _roomId!,
      senderUserId: user.id,
      message: text,
      createdAt: DateTime.now(),
      isPending: true,
    );

    setState(() {
      _sending = true;
      _messages.add(optimisticMessage);
      _textController.clear();
    });

    _scrollToBottom();

    try {
      final inserted = await _supabase
          .from('chat_messages')
          .insert({
            'room_id': _roomId,
            'sender_user_id': user.id,
            'message': text,
          })
          .select('id, room_id, sender_user_id, message, created_at')
          .single();

      final savedMessage = _ChatMessage.fromMap(inserted);

      if (!mounted) return;

      setState(() {
        _messages.removeWhere(
          (message) => message.id == savedMessage.id && message.id != tempId,
        );
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = savedMessage;
        } else if (!_messages.any((m) => m.id == savedMessage.id)) {
          _messages.add(savedMessage);
        }
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        _textController.text = text;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar mensagem: $e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    return GlmShell(
      header: GlmHeader(
        onBack: () async {
          final popped = await Navigator.maybePop(context);
          if (!context.mounted) return;

          if (!popped) {
            Navigator.pushReplacementNamed(context, '/chats');
          }
        },
        trailing: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/chats'),
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: GlmColors.accent,
          ),
        ),
      ),
      bottomNavigation: const GlmBottomNavigation(
        current: GlmBottomNavItem.chats,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _companyName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GlmColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _roomId == null
                  ? const Center(
                      child: Text(
                        'RoomId nao informado.',
                        style: TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GlmColors.border),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMine =
                              userId != null && m.senderUserId == userId;

                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Opacity(
                              opacity: m.isPending ? 0.65 : 1,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 290,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color(0xFFFFE2C3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(
                                      isMine ? 18 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isMine ? 4 : 18,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: isMine
                                        ? GlmColors.border
                                        : const Color(0xFFE9DED1),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (m.isPending) ...[
                                          const SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.8,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          _formatTime(m.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: GlmColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
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
  final bool isPending;

  _ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUserId,
    required this.message,
    required this.createdAt,
    this.isPending = false,
  });

  factory _ChatMessage.fromMap(Map map) {
    return _ChatMessage(
      id: map['id'].toString(),
      roomId: map['room_id'].toString(),
      senderUserId: map['sender_user_id'].toString(),
      message: map['message']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
    );
  }
}
