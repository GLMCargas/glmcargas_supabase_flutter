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

      final data = await supabase
          .from('chat_rooms')
          .select(
            'id, created_at, viagem_id, Viagens:viagem_id(empresa, origem_cidade, origem_uf, destino_cidade, destino_uf)',
          )
          .order('created_at', ascending: false);

      rooms = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar chats: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.orange,
                        ),
                      ),
                      const Icon(
                        Icons.local_shipping,
                        color: Colors.orange,
                        size: 28,
                      ),
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
                        style: TextStyle(color: Colors.orange, fontSize: 20),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadRooms,
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Meus chats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),

                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : rooms.isEmpty
                      ? const Center(
                          child: Text(
                            'Você ainda não tem conversas.',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, i) {
                            final r = rooms[i];
                            final roomId = r['id'].toString();
                            final viagem = (r['Viagens'] as Map?) ?? {};

                            final empresa = (viagem['empresa'] ?? 'Empresa')
                                .toString();
                            final origemCidade = (viagem['origem_cidade'] ?? '')
                                .toString();
                            final origemUf = (viagem['origem_uf'] ?? '')
                                .toString();
                            final destinoCidade =
                                (viagem['destino_cidade'] ?? '').toString();
                            final destinoUf = (viagem['destino_uf'] ?? '')
                                .toString();

                            final subtitle =
                                (origemCidade.isEmpty && destinoCidade.isEmpty)
                                ? 'Viagem #${r['viagem_id']}'
                                : '$origemCidade-$origemUf → $destinoCidade-$destinoUf';

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: {'roomId': roomId},
                                );

                                if (mounted) {
                                  _loadRooms();
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.orange.shade400,
                                      child: Text(
                                        empresa.isNotEmpty
                                            ? empresa[0].toUpperCase()
                                            : 'E',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            empresa,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 28),
                                  ],
                                ),
                              ),
                            );
                          },
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
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/home'),
                          child: const Icon(
                            Icons.home_outlined,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/perfilMotorista'),
                          child: const Icon(
                            Icons.person_outline,
                            size: 32,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/chats'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ),
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
