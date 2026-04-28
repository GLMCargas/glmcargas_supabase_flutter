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

  List<Map<String, dynamic>> cargas = [];
  Set<dynamic> cardsAbertos = {};
  bool _menuAberto = false;
  bool carregandoCargas = true;
  String? erroCargas;

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
    _carregarCargas();
  }

  Future<void> _carregarCargas() async {
    if (!mounted) return;

    if (supabase.auth.currentUser == null) {
      setState(() {
        cargas = [];
        carregandoCargas = false;
        erroCargas = 'Faça login para visualizar as cargas disponíveis.';
      });
      return;
    }

    setState(() {
      carregandoCargas = true;
      erroCargas = null;
    });

    try {
      final response = await supabase.rpc(
        'listar_cargas_publicadas_motorista',
        params: {
          'p_uf_coleta': ufSelecionada == 'Todas' ? null : ufSelecionada,
        },
      );

      if (!mounted) return;

      setState(() {
        cargas = List<Map<String, dynamic>>.from(response ?? const []);
        carregandoCargas = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar cargas: $e');
      if (!mounted) return;

      setState(() {
        cargas = [];
        carregandoCargas = false;
        erroCargas = 'Não foi possível carregar as cargas desta região.';
      });
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

  Future<void> _abrirChat(dynamic viagemId) async {
    try {
      if (viagemId is! num) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat para esta carga ainda não está configurado.'),
          ),
        );
        return;
      }

      final roomId = await supabase.rpc(
        'create_or_get_chat_room',
        params: {'p_viagem_id': viagemId.toInt()},
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'roomId': roomId.toString()},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir chat: $e')));
    }
  }

  String formatarData(String iso) {
    try {
      if (iso.trim().isEmpty) return '-';

      final data = DateTime.parse(iso).toLocal();
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year;

      if (!iso.contains('T')) {
        return '$dia/$mes/$ano';
      }

      final hora = data.hour.toString().padLeft(2, '0');
      final minuto = data.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano $hora:$minuto';
    } catch (_) {
      return iso;
    }
  }

  String formatarValor(dynamic valor) {
    final texto = valor?.toString().trim();

    if (texto == null || texto.isEmpty) return '-';
    if (texto.toLowerCase().contains('combinar')) return texto;
    if (texto.startsWith('R\$')) return texto;

    return 'R\$ $texto';
  }

  String formatarPeso(dynamic peso) {
    final texto = peso?.toString().trim();

    if (texto == null || texto.isEmpty) return '-';
    if (texto.toLowerCase().contains('kg') ||
        texto.toLowerCase().contains('ton')) {
      return texto;
    }

    return '$texto kg';
  }

  String inicialEmpresa(dynamic empresa) {
    final texto = empresa?.toString().trim();

    if (texto == null || texto.isEmpty) return '?';
    return texto.substring(0, 1).toUpperCase();
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
                decoration: const InputDecoration(
                  labelText: 'UF de coleta',
                ),
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
                  await _carregarCargas();
                },
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: carregandoCargas
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: GlmColors.accent,
                      ),
                    )
                  : erroCargas != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  erroCargas!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: GlmColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GlmPrimaryButton(
                                  label: 'Tentar novamente',
                                  icon: Icons.refresh_rounded,
                                  onPressed: _carregarCargas,
                                ),
                              ],
                            ),
                          ),
                        )
                      : cargas.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma carga disponível.',
                        style: TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: cargas.length,
                      itemBuilder: (context, index) {
                        final v = cargas[index];
                        final aberta = cardsAbertos.contains(v['id']);
                        final chatDisponivel = v['id'] is num;

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
                                        inicialEmpresa(v['empresa']),
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
                                    Flexible(
                                      child: Text(
                                        '${v['origem_cidade'] ?? '-'} / ${v['origem_uf'] ?? '-'} -> ${v['destino_cidade'] ?? '-'} / ${v['destino_uf'] ?? '-'}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: GlmColors.accentStrong,
                                          fontWeight: FontWeight.w700,
                                        ),
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
                                  _detalhe(
                                    'Peso',
                                    formatarPeso(v['peso']),
                                  ),
                                  _detalhe(
                                    'Valor',
                                    formatarValor(v['valor']),
                                  ),
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
                                    onPressed: chatDisponivel
                                        ? () => _abrirChat(v['id'])
                                        : null,
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
