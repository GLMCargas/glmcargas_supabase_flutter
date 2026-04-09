import 'package:app/widgets/glm_ui.dart';
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
    return GlmShell(
      header: GlmHeader(
        onBack: () => Navigator.maybePop(context),
        trailing: IconButton(
          onPressed: _loadRooms,
          icon: const Icon(Icons.refresh_rounded, color: GlmColors.accent),
        ),
      ),
      bottomNavigation: const GlmBottomNavigation(
        current: GlmBottomNavItem.chats,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            const GlmSectionHeader(
              title: 'Meus chats',
              subtitle: 'Acompanhe aqui as conversas abertas com as empresas.',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : rooms.isEmpty
                  ? const Center(
                      child: Text(
                        'Voce ainda nao tem conversas.',
                        style: TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: rooms.length,
                      itemBuilder: (context, i) {
                        final r = rooms[i];
                        final roomId = r['id'].toString();
                        final viagem = (r['Viagens'] as Map?) ?? {};

                        final empresa = (viagem['empresa'] ?? 'Empresa')
                            .toString();
                        final origemCidade = (viagem['origem_cidade'] ?? '')
                            .toString();
                        final origemUf = (viagem['origem_uf'] ?? '').toString();
                        final destinoCidade = (viagem['destino_cidade'] ?? '')
                            .toString();
                        final destinoUf = (viagem['destino_uf'] ?? '')
                            .toString();

                        final subtitle =
                            (origemCidade.isEmpty && destinoCidade.isEmpty)
                            ? 'Viagem #${r['viagem_id']}'
                            : '$origemCidade-$origemUf -> $destinoCidade-$destinoUf';

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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: GlmColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: GlmColors.accent,
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
                                          color: GlmColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: GlmColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 28,
                                  color: GlmColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
