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
  final Set<dynamic> cardsAbertos = {};
  final Set<int> _solicitacoesEmEnvio = {};
  final Map<int, _SolicitacaoViagemInfo> _solicitacoesPorViagem = {};

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

      final loadedTrips = List<Map<String, dynamic>>.from(response);
      final loadedRequests = await _carregarSolicitacoes();

      if (!mounted) return;

      setState(() {
        viagens = loadedTrips;
        _solicitacoesPorViagem
          ..clear()
          ..addAll(loadedRequests);
      });
    } catch (e) {
      debugPrint('Erro ao carregar viagens: $e');
    }
  }

  Future<Map<int, _SolicitacaoViagemInfo>> _carregarSolicitacoes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    final data = await supabase
        .from('solicitacoes_viagem')
        .select('id, viagem_id, room_id, status, created_at')
        .eq('motorista_user_id', user.id);

    final requests = (data as List)
        .map((item) => _SolicitacaoViagemInfo.fromMap(item))
        .toList();

    return {
      for (final request in requests) request.viagemId: request,
    };
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

  Future<String?> _abrirChat(int viagemId) async {
    try {
      final roomId = await supabase.rpc(
        'create_or_get_chat_room',
        params: {'p_viagem_id': viagemId},
      );

      if (!mounted) return roomId?.toString();

      await Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'roomId': roomId.toString()},
      );

      return roomId?.toString();
    } catch (e) {
      if (!mounted) return null;

      final message = e.toString().contains('Viagem sem empresa vinculada')
          ? 'Esta viagem ainda não está vinculada a uma empresa para o chat.'
          : e.toString().contains('Viagem não encontrada')
          ? 'Não foi possível localizar essa viagem.'
          : 'Erro ao abrir chat. Tente novamente.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      return null;
    }
  }

  Future<void> _solicitarViagem(Map<String, dynamic> viagem) async {
    final viagemId = (viagem['id'] as num).toInt();
    if (_solicitacoesEmEnvio.contains(viagemId)) return;

    setState(() => _solicitacoesEmEnvio.add(viagemId));

    try {
      final result = await supabase.rpc(
        'request_trip_interest',
        params: {'p_viagem_id': viagemId},
      );

      final solicitacao = _SolicitacaoViagemInfo.fromRequestRpc(
        viagemId: viagemId,
        map: Map<String, dynamic>.from(result as Map),
      );

      if (!mounted) return;

      setState(() {
        _solicitacoesPorViagem[viagemId] = solicitacao;
      });

      final message = solicitacao.createdNow
          ? 'Solicitação enviada. A empresa recebeu sua mensagem no chat.'
          : 'Você já possui uma solicitação para essa viagem.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().contains('Perfil do motorista nao encontrado')
          ? 'Não foi possível localizar seu perfil para enviar a solicitação.'
          : e.toString().contains('Viagem sem empresa vinculada')
          ? 'Esta viagem ainda não está vinculada a uma empresa.'
          : 'Não foi possível enviar sua solicitação agora.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _solicitacoesEmEnvio.remove(viagemId));
      }
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

  Color _statusColor(_SolicitacaoViagemStatus status) {
    switch (status) {
      case _SolicitacaoViagemStatus.aceita:
        return const Color(0xFF2E7D32);
      case _SolicitacaoViagemStatus.recusada:
        return const Color(0xFFC62828);
      case _SolicitacaoViagemStatus.aguardando:
        return const Color(0xFFB26A00);
    }
  }

  String _statusLabel(_SolicitacaoViagemStatus status) {
    switch (status) {
      case _SolicitacaoViagemStatus.aceita:
        return 'Aceita';
      case _SolicitacaoViagemStatus.recusada:
        return 'Recusada';
      case _SolicitacaoViagemStatus.aguardando:
        return 'Aguardando resposta';
    }
  }

  String _statusDescription(_SolicitacaoViagemStatus status) {
    switch (status) {
      case _SolicitacaoViagemStatus.aceita:
        return 'A empresa aceitou sua solicitação para esta viagem.';
      case _SolicitacaoViagemStatus.recusada:
        return 'A empresa recusou sua solicitação para esta viagem.';
      case _SolicitacaoViagemStatus.aguardando:
        return 'Sua solicitação foi enviada e está aguardando retorno da empresa.';
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
                        'Nenhuma carga disponivel.',
                        style: TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarViagens,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: viagens.length,
                        itemBuilder: (context, index) {
                          final v = viagens[index];
                          final viagemId = (v['id'] as num).toInt();
                          final aberta = cardsAbertos.contains(v['id']);
                          final solicitacao = _solicitacoesPorViagem[viagemId];
                          final enviando = _solicitacoesEmEnvio.contains(
                            viagemId,
                          );

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
                                            if (solicitacao != null) ...[
                                              const SizedBox(height: 8),
                                              _StatusChip(
                                                label: _statusLabel(
                                                  solicitacao.status,
                                                ),
                                                color: _statusColor(
                                                  solicitacao.status,
                                                ),
                                              ),
                                            ],
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
                                      'Dimensoes',
                                      '${v['dimensoes'] ?? '-'}',
                                    ),
                                    _detalhe('Peso', '${v['peso'] ?? '-'} kg'),
                                    _detalhe(
                                      'Valor',
                                      'R\$ ${v['valor'] ?? '-'}',
                                    ),
                                    _detalhe(
                                      'Entrega limite',
                                      formatarData(
                                        (v['data_limite_entrega'] ?? '')
                                            .toString(),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    GlmInfoCard(
                                      child: Text(
                                        solicitacao == null
                                            ? 'Se você quiser fazer essa viagem, envie uma solicitação. Uma mensagem padrão será enviada para a empresa no chat.'
                                            : _statusDescription(
                                                solicitacao.status,
                                              ),
                                        style: const TextStyle(
                                          color: GlmColors.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    GlmPrimaryButton(
                                      label: solicitacao == null
                                          ? 'Solicitar esta viagem'
                                          : 'Solicitação ${_statusLabel(solicitacao.status).toLowerCase()}',
                                      icon: solicitacao == null
                                          ? Icons.assignment_turned_in_outlined
                                          : solicitacao.status ==
                                                    _SolicitacaoViagemStatus.aceita
                                          ? Icons.check_circle_outline_rounded
                                          : solicitacao.status ==
                                                    _SolicitacaoViagemStatus.recusada
                                          ? Icons.cancel_outlined
                                          : Icons.schedule_rounded,
                                      loading: enviando,
                                      onPressed: solicitacao == null
                                          ? () => _solicitarViagem(v)
                                          : null,
                                    ),
                                    const SizedBox(height: 10),
                                    GlmOutlinedAction(
                                      label: solicitacao == null
                                          ? 'Falar com a empresa'
                                          : 'Abrir chat da viagem',
                                      icon: Icons.chat_bubble_outline_rounded,
                                      onPressed: () => _abrirChat(viagemId),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

enum _SolicitacaoViagemStatus {
  aguardando,
  aceita,
  recusada,
}

class _SolicitacaoViagemInfo {
  const _SolicitacaoViagemInfo({
    required this.id,
    required this.viagemId,
    required this.roomId,
    required this.status,
    required this.createdNow,
  });

  final String id;
  final int viagemId;
  final String roomId;
  final _SolicitacaoViagemStatus status;
  final bool createdNow;

  factory _SolicitacaoViagemInfo.fromMap(Map<String, dynamic> map) {
    return _SolicitacaoViagemInfo(
      id: map['id']?.toString() ?? '',
      viagemId: (map['viagem_id'] as num).toInt(),
      roomId: map['room_id']?.toString() ?? '',
      status: _statusFromRaw(map['status']?.toString()),
      createdNow: false,
    );
  }

  factory _SolicitacaoViagemInfo.fromRequestRpc({
    required int viagemId,
    required Map<String, dynamic> map,
  }) {
    return _SolicitacaoViagemInfo(
      id: map['request_id']?.toString() ?? '',
      viagemId: viagemId,
      roomId: map['room_id']?.toString() ?? '',
      status: _statusFromRaw(map['status']?.toString()),
      createdNow: map['created_now'] == true,
    );
  }

  static _SolicitacaoViagemStatus _statusFromRaw(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();

    if (normalized.contains('aceit')) {
      return _SolicitacaoViagemStatus.aceita;
    }

    if (normalized.contains('recus')) {
      return _SolicitacaoViagemStatus.recusada;
    }

    return _SolicitacaoViagemStatus.aguardando;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
