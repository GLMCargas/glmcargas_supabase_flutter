import 'package:app/widgets/glm_ui.dart';
import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeMotoristaScreen extends StatefulWidget {
  const HomeMotoristaScreen({super.key});

  @override
  State<HomeMotoristaScreen> createState() => _HomeMotoristaScreenState();
}

class _HomeMotoristaScreenState extends State<HomeMotoristaScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> viagens = [];
  Set<dynamic> cardsAbertos = {};
  bool _menuAberto = false;

  String ufSelecionada = 'Todas';

  final List<String> ufs = const [
    'Todas',
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO',
  ];

  @override
  void initState() {
    super.initState();
    _carregarViagens();
  }

  Future<void> _carregarViagens() async {
    try {
      dynamic response;

      if (ufSelecionada != 'Todas') {
        response = await supabase
            .from('Viagens')
            .select()
            .eq('origem_uf', ufSelecionada);
      } else {
        response = await supabase.from('Viagens').select();
      }

      if (!mounted) return;

      setState(() {
        viagens = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Erro ao carregar viagens: $e');
    }
  }

  void _toggleCard(dynamic id) {
    setState(() {
      if (cardsAbertos.contains(id)) {
        cardsAbertos.remove(id);
      } else {
        cardsAbertos.add(id);
      }
    });
  }

  Future<void> _abrirChat(int viagemId) async {
    try {
      final roomId = await supabase.rpc(
        'create_or_get_chat_room',
        params: {'p_viagem_id': viagemId},
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'roomId': roomId.toString()},
      );
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().contains('Viagem sem empresa vinculada')
          ? 'Esta viagem ainda nao esta vinculada a uma empresa para o chat.'
          : e.toString().contains('Viagem nao encontrada')
          ? 'Nao foi possivel localizar essa viagem.'
          : 'Erro ao abrir chat. Tente novamente.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String formatarData(String iso) {
    try {
      final data = DateTime.parse(iso).toLocal();
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year;
      final hora = data.hour.toString().padLeft(2, '0');
      final minuto = data.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano $hora:$minuto';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlmShell(
      header: GlmHeader(
        onBack: () => Navigator.maybePop(context),
        onMenu: () => setState(() => _menuAberto = true),
      ),
      bottomNavigation: const GlmBottomNavigation(
        current: GlmBottomNavItem.home,
      ),
      overlays: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          left: _menuAberto ? 0 : -260,
          top: 0,
          bottom: 0,
          child: MenuLateral(
            onClose: () => setState(() => _menuAberto = false),
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            const GlmSectionHeader(
              title: 'Cargas Disponíveis',
            ),
            const SizedBox(height: 20),
            GlmInfoCard(
              child: DropdownButtonFormField<String>(
                initialValue: ufSelecionada,
                decoration: const InputDecoration(labelText: 'Estados'),
                items: ufs.map((uf) {
                  return DropdownMenuItem<String>(
                    value: uf,
                    child: Text(uf == 'Todas' ? 'Todos os estados' : uf),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    ufSelecionada = value ?? 'Todas';
                    cardsAbertos.clear();
                  });
                  await _carregarViagens();
                },
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: viagens.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma carga disponível.',
                        style: TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: viagens.length,
                      itemBuilder: (context, index) {
                        final v = viagens[index];
                        final aberta = cardsAbertos.contains(v['id']);

                        return GestureDetector(
                          onTap: () => _toggleCard(v['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: aberta
                                  ? const Color(0xFFFFE8D1)
                                  : const Color(0xFFFFF8F1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: aberta
                                    ? GlmColors.accent
                                    : GlmColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: GlmColors.accent,
                                      child: Text(
                                        (v['empresa'] ?? '?')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
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
                                            (v['empresa'] ?? '').toString(),
                                            style: const TextStyle(
                                              color: GlmColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            (v['produto'] ?? '').toString(),
                                            style: const TextStyle(
                                              color: GlmColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${v['origem_uf'] ?? '-'} -> ${v['destino_uf'] ?? '-'}',
                                      style: const TextStyle(
                                        color: GlmColors.accentStrong,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (aberta) ...[
                                  const SizedBox(height: 14),
                                  const Divider(color: Color(0xFFF3DEC7)),
                                  const SizedBox(height: 8),
                                  _detalhe(
                                    'Dimensões',
                                    '${v['dimensoes'] ?? '-'}',
                                  ),
                                  _detalhe('Peso', '${v['peso'] ?? '-'} kg'),
                                  _detalhe('Valor', 'R\$ ${v['valor'] ?? '-'}'),
                                  _detalhe(
                                    'Entrega limite',
                                    formatarData(
                                      (v['data_limite_entrega'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  GlmPrimaryButton(
                                    label: 'Falar com a empresa',
                                    icon: Icons.chat_bubble_outline_rounded,
                                    onPressed: () =>
                                        _abrirChat((v['id'] as num).toInt()),
                                  ),
                                ],
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

  Widget _detalhe(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: GlmColors.textPrimary, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
