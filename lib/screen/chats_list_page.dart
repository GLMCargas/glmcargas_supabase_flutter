import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() => loading = true);

      // Lista os rooms do motorista, trazendo dados da viagem (join)
      final data = await supabase
          .from('chat_rooms')
          .select('id, created_at, viagem_id, Viagens:viagem_id(empresa, origem_cidade, origem_uf, destino_cidade, destino_uf)')
          .order('created_at', ascending: false);

      rooms = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar chats: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus chats'),
        actions: [
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rooms.isEmpty
              ? const Center(child: Text('Você ainda não tem conversas.'))
              : ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rooms[i];
                    final roomId = r['id'].toString();
                    final viagem = (r['Viagens'] as Map?) ?? {};

                    final empresa = (viagem['empresa'] ?? 'Empresa').toString();
                    final origem =
                        '${(viagem['origem_cidade'] ?? '').toString()}-${(viagem['origem_uf'] ?? '').toString()}';
                    final destino =
                        '${(viagem['destino_cidade'] ?? '').toString()}-${(viagem['destino_uf'] ?? '').toString()}';

                    final subtitle = (origem.trim().isEmpty && destino.trim().isEmpty)
                        ? 'Viagem #${r['viagem_id']}'
                        : '$origem → $destino';

                    return ListTile(
                      title: Text(empresa),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {'roomId': roomId},
                        );
                      },
                    );
                  },
                ),
    );
  }
}