import 'dart:convert';

import 'package:app/widgets/glm_ui.dart';
import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum MotoristaHomeMode { disponiveis, minhasEntregas }

enum _MinhasEntregasTab { ativas, historico }

class HomeMotoristaScreen extends StatefulWidget {
  const HomeMotoristaScreen({
    super.key,
    this.mode = MotoristaHomeMode.disponiveis,
  });

  final MotoristaHomeMode mode;

  @override
  State<HomeMotoristaScreen> createState() => _HomeMotoristaScreenState();
}

class _HomeMotoristaScreenState extends State<HomeMotoristaScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> cargas = [];
  int? _cardAbertoIndex;
  final Set<int> _solicitacoesEmEnvio = {};
  final Set<String> _execucoesEmAtualizacao = {};
  final Map<int, _SolicitacaoViagemInfo> _solicitacoesPorViagem = {};

  bool _menuAberto = false;
  bool carregandoCargas = true;
  String? erroCargas;
  String ufSelecionada = 'Todas';
  _MinhasEntregasTab _minhasEntregasTab = _MinhasEntregasTab.ativas;

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

  bool get _mostrandoMinhasEntregas {
    return widget.mode == MotoristaHomeMode.minhasEntregas;
  }

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
      final result = _mostrandoMinhasEntregas
          ? await _carregarMinhasEntregas()
          : await _carregarCargasDisponiveis();

      if (!mounted) return;

      setState(() {
        cargas = result.cargas;
        carregandoCargas = false;
        _solicitacoesPorViagem
          ..clear()
          ..addAll(result.solicitacoes);
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

  Future<_CargasLoadResult> _carregarCargasDisponiveis() async {
    final response = await supabase.rpc(
      'listar_cargas_publicadas_motorista',
      params: {'p_uf_coleta': ufSelecionada == 'Todas' ? null : ufSelecionada},
    );

    final loadedTrips = await _complementarDadosNavegacao(
      List<Map<String, dynamic>>.from(response ?? const []),
    );
    final loadedRequests = await _carregarSolicitacoes();
    final availableTrips = loadedTrips
        .where((trip) {
          final tripId = _extractTripId(trip);
          final solicitacao = tripId == null ? null : loadedRequests[tripId];

          return solicitacao?.status != _SolicitacaoViagemStatus.aceita;
        })
        .toList(growable: false);

    return _CargasLoadResult(
      cargas: availableTrips,
      solicitacoes: loadedRequests,
    );
  }

  Future<_CargasLoadResult> _carregarMinhasEntregas() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return const _CargasLoadResult(cargas: [], solicitacoes: {});
    }

    final data = await supabase
        .from('solicitacoes_viagem')
        .select(
          'id, viagem_id, room_id, status, status_execucao, '
          'coleta_informada_em, coleta_confirmada_em, '
          'entrega_informada_em, entrega_confirmada_em, created_at',
        )
        .eq('motorista_user_id', user.id)
        .eq('status', 'Aceita')
        .order('created_at', ascending: false);

    final requestList = List<Map<String, dynamic>>.from(
      data as List,
    ).map(_SolicitacaoViagemInfo.fromMap).toList(growable: false);
    final tripIds = requestList
        .map((request) => request.viagemId)
        .toSet()
        .toList(growable: false);

    if (tripIds.isEmpty) {
      return const _CargasLoadResult(cargas: [], solicitacoes: {});
    }

    final tripRows = await supabase
        .from('Viagens')
        .select(
          'id, empresa, produto, origem_cidade, origem_uf, '
          'destino_cidade, destino_uf, peso, peso_texto, valor, dimensoes, '
          'tipo_veiculo, tipo_carroceria, categoria_carga, '
          'compatibilidade_veiculo, '
          'data_limite_entrega, coleta_endereco, coleta_latitude, '
          'coleta_longitude, coleta_place_id, entrega_endereco, '
          'entrega_latitude, entrega_longitude, entrega_place_id',
        )
        .inFilter('id', tripIds);
    final tripsById = {
      for (final trip in List<Map<String, dynamic>>.from(tripRows as List))
        if (trip['id'] is num) (trip['id'] as num).toInt(): trip,
    };

    final activeTrips = <Map<String, dynamic>>[];
    final finishedTrips = <Map<String, dynamic>>[];
    final requests = <int, _SolicitacaoViagemInfo>{};

    for (final solicitacao in requestList) {
      final loadedTrip = tripsById[solicitacao.viagemId];
      if (loadedTrip == null) continue;
      requests[solicitacao.viagemId] = solicitacao;

      final viagem = Map<String, dynamic>.from(loadedTrip);
      viagem['id'] ??= solicitacao.viagemId;
      viagem['viagem_id'] ??= solicitacao.viagemId;

      if (solicitacao.isFinalizada) {
        finishedTrips.add(viagem);
      } else {
        activeTrips.add(viagem);
      }
    }

    return _CargasLoadResult(
      cargas: [...activeTrips, ...finishedTrips],
      solicitacoes: requests,
    );
  }

  Future<List<Map<String, dynamic>>> _complementarDadosNavegacao(
    List<Map<String, dynamic>> trips,
  ) async {
    final ids = trips
        .map(_extractTripId)
        .whereType<int>()
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) return trips;

    final data = await supabase
        .from('Viagens')
        .select(
          'id, coleta_endereco, coleta_latitude, coleta_longitude, '
          'coleta_place_id, entrega_endereco, entrega_latitude, '
          'entrega_longitude, entrega_place_id',
        )
        .inFilter('id', ids);

    final navigationByTripId = {
      for (final item in List<Map<String, dynamic>>.from(data))
        if (item['id'] is num) (item['id'] as num).toInt(): item,
    };

    return trips
        .map((trip) {
          final tripId = _extractTripId(trip);
          final navigation = tripId == null ? null : navigationByTripId[tripId];
          if (navigation == null) return trip;

          return {...trip, ...navigation};
        })
        .toList(growable: false);
  }

  Future<Map<int, _SolicitacaoViagemInfo>> _carregarSolicitacoes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {};

    final data = await supabase
        .from('solicitacoes_viagem')
        .select(
          'id, viagem_id, room_id, status, status_execucao, '
          'coleta_informada_em, coleta_confirmada_em, '
          'entrega_informada_em, entrega_confirmada_em, created_at',
        )
        .eq('motorista_user_id', user.id);

    final requests = (data as List)
        .map((item) => _SolicitacaoViagemInfo.fromMap(item))
        .toList();

    return {for (final request in requests) request.viagemId: request};
  }

  void _toggleCard(int index) {
    setState(() {
      _cardAbertoIndex = _cardAbertoIndex == index ? null : index;
    });
  }

  int? _extractTripId(Map<String, dynamic> carga) {
    final viagemId = carga['viagem_id'];
    if (viagemId is num) return viagemId.toInt();

    final legacyId = carga['id'];
    if (legacyId is num) return legacyId.toInt();

    return null;
  }

  Future<String?> _abrirChat(int? viagemId) async {
    try {
      if (viagemId == null) {
        if (!mounted) return null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat para esta carga ainda não está configurado.'),
          ),
        );
        return null;
      }

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
    final viagemId = _extractTripId(viagem);
    if (viagemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta carga ainda não pode receber solicitações.'),
        ),
      );
      return;
    }
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
        if (!_mostrandoMinhasEntregas &&
            solicitacao.status == _SolicitacaoViagemStatus.aceita) {
          cargas.removeWhere((carga) => _extractTripId(carga) == viagemId);
          _cardAbertoIndex = null;
        }
      });

      final message = solicitacao.createdNow
          ? 'Solicitação enviada. A empresa recebeu sua mensagem no chat.'
          : 'Você já possui uma solicitação para essa viagem.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      final message =
          e.toString().contains('Perfil do motorista não encontrado')
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

  Future<void> _abrirRotaNoMaps(_NavigationPoint point) async {
    final params = <String, String>{
      'api': '1',
      'destination': point.mapsDestinationForUrl,
      'travelmode': 'driving',
    };

    if (point.placeId != null && point.placeId!.isNotEmpty) {
      params['destination_place_id'] = point.placeId!;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel abrir o Google Maps.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o Google Maps.')),
      );
    }
  }

  Future<void> _informarColeta(_SolicitacaoViagemInfo solicitacao) async {
    await _atualizarExecucao(
      solicitacao: solicitacao,
      rpcName: 'informar_coleta_realizada',
      successMessage: 'Coleta informada. Aguarde a confirmacao da empresa.',
    );
  }

  Future<void> _informarEntrega(_SolicitacaoViagemInfo solicitacao) async {
    await _atualizarExecucao(
      solicitacao: solicitacao,
      rpcName: 'informar_entrega_realizada',
      successMessage: 'Entrega informada. Aguarde a confirmacao da empresa.',
    );
  }

  Future<void> _atualizarExecucao({
    required _SolicitacaoViagemInfo solicitacao,
    required String rpcName,
    required String successMessage,
  }) async {
    if (_execucoesEmAtualizacao.contains(solicitacao.id)) return;

    setState(() => _execucoesEmAtualizacao.add(solicitacao.id));

    try {
      final result = await supabase.rpc(
        rpcName,
        params: {'p_solicitacao_id': solicitacao.id},
      );
      final resultMap = Map<String, dynamic>.from(result as Map);

      final updated = solicitacao.copyWith(
        statusExecucao: _SolicitacaoViagemInfo.execucaoFromRaw(
          resultMap['status_execucao']?.toString(),
        ),
        coletaInformadaEm: resultMap['coleta_informada_em']?.toString(),
        coletaConfirmadaEm: resultMap['coleta_confirmada_em']?.toString(),
        entregaInformadaEm: resultMap['entrega_informada_em']?.toString(),
        entregaConfirmadaEm: resultMap['entrega_confirmada_em']?.toString(),
      );

      if (!mounted) return;

      setState(() {
        _solicitacoesPorViagem[solicitacao.viagemId] = updated;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nao foi possivel atualizar a viagem agora: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _execucoesEmAtualizacao.remove(solicitacao.id));
      }
    }
  }

  _NavigationPoint? _navigationPointFor(
    Map<String, dynamic> viagem,
    _SolicitacaoViagemInfo solicitacao,
  ) {
    if (solicitacao.status != _SolicitacaoViagemStatus.aceita) {
      return null;
    }

    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.emEntrega:
        return _pointFromTrip(viagem, stage: _NavigationStage.entrega);
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return _pointFromTrip(viagem, stage: _NavigationStage.coleta);
      case _ExecucaoViagemStatus.retiradaInformada:
      case _ExecucaoViagemStatus.entregaInformada:
      case _ExecucaoViagemStatus.concluida:
      case _ExecucaoViagemStatus.cancelada:
        return null;
    }
  }

  _NavigationPoint? _pointFromTrip(
    Map<String, dynamic> viagem, {
    required _NavigationStage stage,
  }) {
    final isColeta = stage == _NavigationStage.coleta;
    final addressKey = isColeta ? 'coleta_endereco' : 'entrega_endereco';
    final latKey = isColeta ? 'coleta_latitude' : 'entrega_latitude';
    final lngKey = isColeta ? 'coleta_longitude' : 'entrega_longitude';
    final placeKey = isColeta ? 'coleta_place_id' : 'entrega_place_id';
    final cityKey = isColeta ? 'origem_cidade' : 'destino_cidade';
    final ufKey = isColeta ? 'origem_uf' : 'destino_uf';

    final address = _firstNonEmpty([
      viagem[addressKey],
      _cityUf(viagem[cityKey], viagem[ufKey]),
    ]);
    final latitude = _asDouble(viagem[latKey]);
    final longitude = _asDouble(viagem[lngKey]);
    final placeId = viagem[placeKey]?.toString().trim();

    if (address == null && (latitude == null || longitude == null)) {
      return null;
    }

    return _NavigationPoint(
      stage: stage,
      label: isColeta ? 'Local de coleta' : 'Local de entrega',
      address:
          address ??
          '${latitude!.toStringAsFixed(6)}, '
              '${longitude!.toStringAsFixed(6)}',
      latitude: latitude,
      longitude: longitude,
      placeId: placeId == null || placeId.isEmpty ? null : placeId,
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }

    return null;
  }

  String? _cityUf(dynamic city, dynamic uf) {
    final cityText = city?.toString().trim();
    final ufText = uf?.toString().trim();

    if ((cityText == null || cityText.isEmpty) &&
        (ufText == null || ufText.isEmpty)) {
      return null;
    }

    if (cityText == null || cityText.isEmpty) return ufText;
    if (ufText == null || ufText.isEmpty) return cityText;

    return '$cityText, $ufText';
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
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

  String formatarPesoViagem(Map<String, dynamic> viagem) {
    return formatarPeso(
      _firstNonEmpty([
        viagem['peso_texto'],
        viagem['pesoExibicao'],
        viagem['peso_exibicao'],
        viagem['peso_bruto'],
        viagem['peso'],
      ]),
    );
  }

  String formatarCompatibilidadeVeiculo(Map<String, dynamic> viagem) {
    const chavesCompatibilidade = [
      'compatibilidade_veiculo',
      'compatibilidadeVeiculo',
      'compatibilidade',
      'dimensoes',
    ];

    for (final chave in chavesCompatibilidade) {
      final texto = viagem[chave]?.toString().trim();
      if (texto != null && texto.isNotEmpty) {
        return texto;
      }
    }

    final tipoVeiculo = _firstNonEmpty([
      viagem['tipo_veiculo'],
      viagem['tipoVeiculo'],
    ]);
    final tipoCarroceria = _firstNonEmpty([
      viagem['tipo_carroceria'],
      viagem['tipoCarroceria'],
    ]);

    if (tipoVeiculo != null && tipoCarroceria != null) {
      return '$tipoVeiculo - $tipoCarroceria';
    }

    final fallback = _firstNonEmpty([
      tipoVeiculo,
      tipoCarroceria,
      viagem['categoria_carga'],
      viagem['categoriaCarga'],
    ]);
    if (fallback != null) return fallback;

    return '-';
  }

  String inicialEmpresa(dynamic empresa) {
    final texto = empresa?.toString().trim();

    if (texto == null || texto.isEmpty) return '?';
    return texto.substring(0, 1).toUpperCase();
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

  Color _cardStatusColor(_SolicitacaoViagemInfo solicitacao) {
    if (solicitacao.isFinalizada) return const Color(0xFF607D8B);
    if (solicitacao.status == _SolicitacaoViagemStatus.aceita) {
      return const Color(0xFF2E7D32);
    }

    return _statusColor(solicitacao.status);
  }

  String _cardStatusLabel(_SolicitacaoViagemInfo solicitacao) {
    if (solicitacao.isFinalizada) return 'Finalizada';

    if (solicitacao.status != _SolicitacaoViagemStatus.aceita) {
      return _statusLabel(solicitacao.status);
    }

    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return 'Aguardando coleta';
      case _ExecucaoViagemStatus.retiradaInformada:
        return 'Coleta informada';
      case _ExecucaoViagemStatus.emEntrega:
        return 'Em entrega';
      case _ExecucaoViagemStatus.entregaInformada:
        return 'Entrega informada';
      case _ExecucaoViagemStatus.concluida:
        return 'Finalizada';
      case _ExecucaoViagemStatus.cancelada:
        return 'Cancelada';
    }
  }

  String _execucaoDescription(_SolicitacaoViagemInfo solicitacao) {
    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return 'Siga ate o ponto de coleta. Quando a carga estiver com voce, informe a coleta no app.';
      case _ExecucaoViagemStatus.retiradaInformada:
        return 'Coleta informada. Aguarde a empresa confirmar para liberar a rota ate a entrega.';
      case _ExecucaoViagemStatus.emEntrega:
        return 'Coleta confirmada. Siga ate o local de entrega.';
      case _ExecucaoViagemStatus.entregaInformada:
        return 'Entrega informada. Aguarde a confirmacao final da empresa.';
      case _ExecucaoViagemStatus.concluida:
        return 'Viagem concluida pela empresa.';
      case _ExecucaoViagemStatus.cancelada:
        return 'Esta viagem foi cancelada.';
    }
  }

  String _execucaoTitle(_SolicitacaoViagemInfo solicitacao) {
    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return 'Rota liberada para coleta';
      case _ExecucaoViagemStatus.retiradaInformada:
        return 'Coleta aguardando confirmacao';
      case _ExecucaoViagemStatus.emEntrega:
        return 'Rota liberada para entrega';
      case _ExecucaoViagemStatus.entregaInformada:
        return 'Entrega aguardando confirmacao';
      case _ExecucaoViagemStatus.concluida:
        return 'Viagem concluida';
      case _ExecucaoViagemStatus.cancelada:
        return 'Viagem cancelada';
    }
  }

  IconData _execucaoIcon(_SolicitacaoViagemInfo solicitacao) {
    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return Icons.inventory_2_outlined;
      case _ExecucaoViagemStatus.retiradaInformada:
      case _ExecucaoViagemStatus.entregaInformada:
        return Icons.hourglass_top_rounded;
      case _ExecucaoViagemStatus.emEntrega:
        return Icons.flag_outlined;
      case _ExecucaoViagemStatus.concluida:
        return Icons.check_circle_outline_rounded;
      case _ExecucaoViagemStatus.cancelada:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildNavigationFlow(
    Map<String, dynamic> viagem,
    _SolicitacaoViagemInfo solicitacao,
  ) {
    final point = _navigationPointFor(viagem, solicitacao);
    final updating = _execucoesEmAtualizacao.contains(solicitacao.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlmInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: GlmColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _execucaoIcon(solicitacao),
                      color: GlmColors.accentStrong,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _execucaoTitle(solicitacao),
                          style: const TextStyle(
                            color: GlmColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _execucaoDescription(solicitacao),
                          style: const TextStyle(
                            color: GlmColors.textMuted,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TripExecutionTimeline(solicitacao: solicitacao),
            ],
          ),
        ),
        if (point != null) ...[
          const SizedBox(height: 12),
          _RoutePreviewCard(
            point: point,
            onOpen: () => _abrirRotaNoMaps(point),
          ),
        ],
        if (solicitacao.canInformarColeta) ...[
          const SizedBox(height: 12),
          GlmPrimaryButton(
            label: 'Informar carga coletada',
            icon: Icons.inventory_2_outlined,
            loading: updating,
            onPressed: updating ? null : () => _informarColeta(solicitacao),
          ),
        ] else if (solicitacao.canInformarEntrega) ...[
          const SizedBox(height: 12),
          GlmPrimaryButton(
            label: 'Informar entrega realizada',
            icon: Icons.flag_outlined,
            loading: updating,
            onPressed: updating ? null : () => _informarEntrega(solicitacao),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _mostrandoMinhasEntregas
        ? 'Minhas Entregas'
        : 'Cargas Disponiveis';
    final activeDeliveries = cargas
        .where((carga) {
          final viagemId = _extractTripId(carga);
          final solicitacao = viagemId == null
              ? null
              : _solicitacoesPorViagem[viagemId];
          return !(solicitacao?.isFinalizada ?? false);
        })
        .toList(growable: false);
    final historyDeliveries = cargas
        .where((carga) {
          final viagemId = _extractTripId(carga);
          final solicitacao = viagemId == null
              ? null
              : _solicitacoesPorViagem[viagemId];
          return solicitacao?.isFinalizada ?? false;
        })
        .toList(growable: false);
    final displayedCargas = !_mostrandoMinhasEntregas
        ? cargas
        : _minhasEntregasTab == _MinhasEntregasTab.ativas
        ? activeDeliveries
        : historyDeliveries;
    final emptyMessage = !_mostrandoMinhasEntregas
        ? 'Nenhuma carga disponivel.'
        : _minhasEntregasTab == _MinhasEntregasTab.ativas
        ? 'Nenhuma carga ativa no momento.'
        : 'Nenhuma carga finalizada no historico.';

    return GlmShell(
      header: GlmHeader(
        onBack: () => Navigator.maybePop(context),
        onMenu: () => setState(() => _menuAberto = true),
      ),
      bottomNavigation: GlmBottomNavigation(
        current: _mostrandoMinhasEntregas
            ? GlmBottomNavItem.deliveries
            : GlmBottomNavItem.home,
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
            GlmSectionHeader(title: title),
            if (!_mostrandoMinhasEntregas) ...[
              const SizedBox(height: 20),
              GlmInfoCard(
                child: DropdownButtonFormField<String>(
                  initialValue: ufSelecionada,
                  decoration: const InputDecoration(labelText: 'UF de coleta'),
                  items: ufs.map((uf) {
                    return DropdownMenuItem<String>(
                      value: uf,
                      child: Text(uf == 'Todas' ? 'Todos os estados' : uf),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      ufSelecionada = value ?? 'Todas';
                      _cardAbertoIndex = null;
                    });
                    await _carregarCargas();
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              _MinhasEntregasTabs(
                current: _minhasEntregasTab,
                activeCount: activeDeliveries.length,
                historyCount: historyDeliveries.length,
                onChanged: (tab) {
                  setState(() {
                    _minhasEntregasTab = tab;
                    _cardAbertoIndex = null;
                  });
                },
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: carregandoCargas
                  ? const Center(
                      child: CircularProgressIndicator(color: GlmColors.accent),
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
                  : displayedCargas.isEmpty
                  ? Center(
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(color: GlmColors.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarCargas,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: displayedCargas.length,
                        itemBuilder: (context, index) {
                          final v = displayedCargas[index];
                          final viagemId = _extractTripId(v);
                          final aberta = _cardAbertoIndex == index;
                          final solicitacao = viagemId != null
                              ? _solicitacoesPorViagem[viagemId]
                              : null;
                          final enviando = _solicitacoesEmEnvio.contains(
                            viagemId ?? -1,
                          );
                          final chatDisponivel = viagemId != null;
                          final solicitacaoAceita =
                              solicitacao?.status ==
                              _SolicitacaoViagemStatus.aceita;
                          final viagemFinalizada =
                              solicitacao?.isFinalizada ?? false;
                          final mostrarPreviewColeta =
                              solicitacao == null ||
                              solicitacao.status ==
                                  _SolicitacaoViagemStatus.aguardando;
                          final previewColeta = mostrarPreviewColeta
                              ? _pointFromTrip(
                                  v,
                                  stage: _NavigationStage.coleta,
                                )
                              : null;

                          return GestureDetector(
                            onTap: () => _toggleCard(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: viagemFinalizada
                                    ? const Color(0xFFF4F2EF)
                                    : aberta
                                    ? const Color(0xFFFFE8D1)
                                    : const Color(0xFFFFF8F1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: viagemFinalizada
                                      ? const Color(0xFFB8AEA4)
                                      : aberta
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
                                            if (solicitacao != null) ...[
                                              const SizedBox(height: 8),
                                              _StatusChip(
                                                label: _cardStatusLabel(
                                                  solicitacao,
                                                ),
                                                color: _cardStatusColor(
                                                  solicitacao,
                                                ),
                                              ),
                                            ],
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
                                      'Compatibilidade de veiculo',
                                      formatarCompatibilidadeVeiculo(v),
                                    ),
                                    _detalhe('Peso', formatarPesoViagem(v)),
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
                                    if (previewColeta != null) ...[
                                      const SizedBox(height: 14),
                                      _RoutePreviewCard(
                                        point: previewColeta,
                                        onOpen: () =>
                                            _abrirRotaNoMaps(previewColeta),
                                      ),
                                    ],
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
                                    if (solicitacao != null &&
                                        solicitacaoAceita) ...[
                                      const SizedBox(height: 14),
                                      _buildNavigationFlow(v, solicitacao),
                                    ],
                                    if (!_mostrandoMinhasEntregas) ...[
                                      const SizedBox(height: 14),
                                      GlmPrimaryButton(
                                        label: solicitacao == null
                                            ? 'Solicitar esta viagem'
                                            : 'Solicitação ${_statusLabel(solicitacao.status).toLowerCase()}',
                                        icon: solicitacao == null
                                            ? Icons
                                                  .assignment_turned_in_outlined
                                            : solicitacao.status ==
                                                  _SolicitacaoViagemStatus
                                                      .aceita
                                            ? Icons.check_circle_outline_rounded
                                            : solicitacao.status ==
                                                  _SolicitacaoViagemStatus
                                                      .recusada
                                            ? Icons.cancel_outlined
                                            : Icons.schedule_rounded,
                                        loading: enviando,
                                        onPressed: solicitacao == null
                                            ? () => _solicitarViagem(v)
                                            : null,
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    GlmOutlinedAction(
                                      label: solicitacao == null
                                          ? 'Falar com a empresa'
                                          : 'Abrir chat da viagem',
                                      icon: Icons.chat_bubble_outline_rounded,
                                      onPressed: chatDisponivel
                                          ? () => _abrirChat(viagemId)
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

class _CargasLoadResult {
  const _CargasLoadResult({required this.cargas, required this.solicitacoes});

  final List<Map<String, dynamic>> cargas;
  final Map<int, _SolicitacaoViagemInfo> solicitacoes;
}

class _MinhasEntregasTabs extends StatelessWidget {
  const _MinhasEntregasTabs({
    required this.current,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  final _MinhasEntregasTab current;
  final int activeCount;
  final int historyCount;
  final ValueChanged<_MinhasEntregasTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_MinhasEntregasTab>(
        segments: [
          ButtonSegment(
            value: _MinhasEntregasTab.ativas,
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text('Ativas ($activeCount)'),
          ),
          ButtonSegment(
            value: _MinhasEntregasTab.historico,
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text('Historico ($historyCount)'),
          ),
        ],
        selected: {current},
        showSelectedIcon: false,
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : GlmColors.textPrimary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? GlmColors.textPrimary
                : const Color(0xFFFFFBF7),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: GlmColors.border),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        onSelectionChanged: (selected) => onChanged(selected.first),
      ),
    );
  }
}

enum _SolicitacaoViagemStatus { aguardando, aceita, recusada }

enum _ExecucaoViagemStatus {
  aguardandoRetirada,
  retiradaInformada,
  emEntrega,
  entregaInformada,
  concluida,
  cancelada,
}

enum _NavigationStage { coleta, entrega }

class _SolicitacaoViagemInfo {
  const _SolicitacaoViagemInfo({
    required this.id,
    required this.viagemId,
    required this.roomId,
    required this.status,
    required this.createdNow,
    this.statusExecucao,
    this.coletaInformadaEm,
    this.coletaConfirmadaEm,
    this.entregaInformadaEm,
    this.entregaConfirmadaEm,
  });

  final String id;
  final int viagemId;
  final String roomId;
  final _SolicitacaoViagemStatus status;
  final bool createdNow;
  final _ExecucaoViagemStatus? statusExecucao;
  final String? coletaInformadaEm;
  final String? coletaConfirmadaEm;
  final String? entregaInformadaEm;
  final String? entregaConfirmadaEm;

  bool get canInformarColeta {
    return status == _SolicitacaoViagemStatus.aceita &&
        (statusExecucao == null ||
            statusExecucao == _ExecucaoViagemStatus.aguardandoRetirada);
  }

  bool get canInformarEntrega {
    return status == _SolicitacaoViagemStatus.aceita &&
        statusExecucao == _ExecucaoViagemStatus.emEntrega;
  }

  bool get isFinalizada {
    return statusExecucao == _ExecucaoViagemStatus.concluida;
  }

  factory _SolicitacaoViagemInfo.fromMap(Map<String, dynamic> map) {
    return _SolicitacaoViagemInfo(
      id: map['id']?.toString() ?? '',
      viagemId: (map['viagem_id'] as num).toInt(),
      roomId: map['room_id']?.toString() ?? '',
      status: _statusFromRaw(map['status']?.toString()),
      createdNow: false,
      statusExecucao: execucaoFromRaw(map['status_execucao']?.toString()),
      coletaInformadaEm: map['coleta_informada_em']?.toString(),
      coletaConfirmadaEm: map['coleta_confirmada_em']?.toString(),
      entregaInformadaEm: map['entrega_informada_em']?.toString(),
      entregaConfirmadaEm: map['entrega_confirmada_em']?.toString(),
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
      statusExecucao: execucaoFromRaw(map['status_execucao']?.toString()),
    );
  }

  _SolicitacaoViagemInfo copyWith({
    _ExecucaoViagemStatus? statusExecucao,
    String? coletaInformadaEm,
    String? coletaConfirmadaEm,
    String? entregaInformadaEm,
    String? entregaConfirmadaEm,
  }) {
    return _SolicitacaoViagemInfo(
      id: id,
      viagemId: viagemId,
      roomId: roomId,
      status: status,
      createdNow: createdNow,
      statusExecucao: statusExecucao ?? this.statusExecucao,
      coletaInformadaEm: coletaInformadaEm ?? this.coletaInformadaEm,
      coletaConfirmadaEm: coletaConfirmadaEm ?? this.coletaConfirmadaEm,
      entregaInformadaEm: entregaInformadaEm ?? this.entregaInformadaEm,
      entregaConfirmadaEm: entregaConfirmadaEm ?? this.entregaConfirmadaEm,
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

  static _ExecucaoViagemStatus? execucaoFromRaw(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();

    if (normalized.isEmpty) return null;
    if (normalized.contains('retirada informada')) {
      return _ExecucaoViagemStatus.retiradaInformada;
    }
    if (normalized.contains('em entrega')) {
      return _ExecucaoViagemStatus.emEntrega;
    }
    if (normalized.contains('entrega informada')) {
      return _ExecucaoViagemStatus.entregaInformada;
    }
    if (normalized.contains('conclu')) {
      return _ExecucaoViagemStatus.concluida;
    }
    if (normalized.contains('cancel')) {
      return _ExecucaoViagemStatus.cancelada;
    }
    if (normalized.contains('aguardando retirada')) {
      return _ExecucaoViagemStatus.aguardandoRetirada;
    }

    return null;
  }
}

class _NavigationPoint {
  const _NavigationPoint({
    required this.stage,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
    this.placeId,
  });

  final _NavigationStage stage;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get mapsDestination {
    if (hasCoordinates) {
      return '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}';
    }

    return address;
  }

  String get mapsDestinationForUrl {
    return placeId == null ? mapsDestination : address;
  }

  String get title {
    return stage == _NavigationStage.coleta
        ? 'Rota ate a coleta'
        : 'Rota ate a entrega';
  }
}

class _RoutePreviewCard extends StatefulWidget {
  const _RoutePreviewCard({required this.point, required this.onOpen});

  final _NavigationPoint point;
  final VoidCallback onOpen;

  @override
  State<_RoutePreviewCard> createState() => _RoutePreviewCardState();
}

class _RoutePreviewCardState extends State<_RoutePreviewCard> {
  static const _mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );

  late Future<_RoutePreviewData> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _loadRoutePreview();
  }

  @override
  void didUpdateWidget(covariant _RoutePreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.point.mapsDestination != widget.point.mapsDestination ||
        oldWidget.point.stage != widget.point.stage) {
      _routeFuture = _loadRoutePreview();
    }
  }

  Future<_RoutePreviewData> _loadRoutePreview() async {
    if (!widget.point.hasCoordinates) {
      return const _RoutePreviewData(
        message: 'Coordenadas da carga indisponiveis.',
      );
    }

    final destination = LatLng(widget.point.latitude!, widget.point.longitude!);

    if (_mapboxAccessToken.isEmpty) {
      return _RoutePreviewData(
        destination: destination,
        message: 'Rota detalhada indisponivel.',
      );
    }

    final origin = await _getDriverLocation();

    if (origin == null) {
      return _RoutePreviewData(
        destination: destination,
        message: 'Ative a localizacao para ver a rota ate a carga.',
      );
    }

    final route = await _fetchMapboxRoute(
      origin: origin,
      destination: destination,
    );

    return _RoutePreviewData(
      origin: origin,
      destination: destination,
      route: route.isEmpty ? [origin, destination] : route,
      message: route.isEmpty ? 'Rota aproximada ate a carga.' : null,
    );
  }

  Future<LatLng?> _getDriverLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  Future<List<LatLng>> _fetchMapboxRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final path =
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${_coordinateForMapbox(origin)};${_coordinateForMapbox(destination)}';
    final uri = Uri.parse(path).replace(
      queryParameters: const {
        'geometries': 'geojson',
        'overview': 'full',
        'alternatives': 'false',
        'steps': 'false',
        'access_token': _mapboxAccessToken,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) return const [];

      final firstRoute = routes.first;
      if (firstRoute is! Map<String, dynamic>) return const [];

      final geometry = firstRoute['geometry'];
      if (geometry is! Map<String, dynamic>) return const [];

      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return const [];

      return coordinates
          .whereType<List>()
          .where((coordinate) => coordinate.length >= 2)
          .map(
            (coordinate) => LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String _coordinateForMapbox(LatLng point) {
    return '${point.longitude.toStringAsFixed(6)},'
        '${point.latitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 212,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GlmColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<_RoutePreviewData>(
                  future: _routeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _RouteMapLoading();
                    }

                    final data = snapshot.data;
                    if (data == null || !data.canShowMap) {
                      return _RouteMapFallback(
                        message: data?.message ?? 'Mapa indisponivel agora.',
                      );
                    }

                    return _RouteMiniMap(
                      data: data,
                      mapboxAccessToken: _mapboxAccessToken,
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: GlmColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.point.stage == _NavigationStage.coleta
                              ? Icons.inventory_2_outlined
                              : Icons.flag_outlined,
                          color: GlmColors.accentStrong,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.point.label,
                          style: const TextStyle(
                            color: GlmColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBF7),
                border: Border(top: BorderSide(color: Color(0xFFF3DEC7))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.point.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GlmColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.point.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GlmColors.textPrimary,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onOpen,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Abrir no Google Maps',
                              style: TextStyle(
                                color: GlmColors.accentStrong,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: GlmColors.accentStrong,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewData {
  const _RoutePreviewData({
    this.origin,
    this.destination,
    this.route = const [],
    this.message,
  });

  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> route;
  final String? message;

  bool get canShowMap => destination != null;

  List<LatLng> get cameraPoints {
    if (route.length > 1) return route;
    return [?origin, ?destination];
  }
}

class _RouteMiniMap extends StatelessWidget {
  const _RouteMiniMap({required this.data, required this.mapboxAccessToken});

  final _RoutePreviewData data;
  final String mapboxAccessToken;

  bool get _hasMapboxToken => mapboxAccessToken.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final destination = data.destination!;
    final cameraPoints = data.cameraPoints;
    final hasRoute = data.route.length > 1;

    return FlutterMap(
      options: MapOptions(
        initialCenter: destination,
        initialZoom: 13,
        initialCameraFit: cameraPoints.length > 1
            ? CameraFit.coordinates(
                coordinates: cameraPoints,
                padding: const EdgeInsets.fromLTRB(34, 28, 34, 24),
                maxZoom: 15,
              )
            : null,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.pinchMove |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        if (_hasMapboxToken)
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/mapbox/streets-v12/'
                'tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken',
            userAgentPackageName: 'br.com.glmcargas.app',
          )
        else
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.glmcargas.app',
          ),
        if (hasRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: data.route,
                color: GlmColors.accent,
                borderColor: Colors.white,
                borderStrokeWidth: 3,
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (data.origin != null)
              Marker(
                point: data.origin!,
                width: 28,
                height: 28,
                child: _RouteMarker(
                  color: GlmColors.textMuted,
                  icon: Icons.my_location_rounded,
                ),
              ),
            Marker(
              point: destination,
              width: 34,
              height: 34,
              child: _RouteMarker(
                color: GlmColors.accentStrong,
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        if (data.message != null)
          Positioned(
            right: 10,
            bottom: 10,
            child: _RouteMapMessage(message: data.message!),
          ),
      ],
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}

class _RouteMapLoading extends StatelessWidget {
  const _RouteMapLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF2E5),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: GlmColors.accentStrong,
          ),
        ),
      ),
    );
  }
}

class _RouteMapFallback extends StatelessWidget {
  const _RouteMapFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF2E5),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _RouteMapMessage(message: message),
    );
  }
}

class _RouteMapMessage extends StatelessWidget {
  const _RouteMapMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GlmColors.border),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GlmColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
    );
  }
}

enum _TripStepState { pending, active, waiting, done, canceled }

class _TripExecutionTimeline extends StatelessWidget {
  const _TripExecutionTimeline({required this.solicitacao});

  final _SolicitacaoViagemInfo solicitacao;

  _TripStepState get _coletaState {
    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case null:
        return _TripStepState.active;
      case _ExecucaoViagemStatus.retiradaInformada:
        return _TripStepState.waiting;
      case _ExecucaoViagemStatus.emEntrega:
      case _ExecucaoViagemStatus.entregaInformada:
      case _ExecucaoViagemStatus.concluida:
        return _TripStepState.done;
      case _ExecucaoViagemStatus.cancelada:
        return _TripStepState.canceled;
    }
  }

  _TripStepState get _entregaState {
    switch (solicitacao.statusExecucao) {
      case _ExecucaoViagemStatus.aguardandoRetirada:
      case _ExecucaoViagemStatus.retiradaInformada:
      case null:
        return _TripStepState.pending;
      case _ExecucaoViagemStatus.emEntrega:
        return _TripStepState.active;
      case _ExecucaoViagemStatus.entregaInformada:
        return _TripStepState.waiting;
      case _ExecucaoViagemStatus.concluida:
        return _TripStepState.done;
      case _ExecucaoViagemStatus.cancelada:
        return _TripStepState.canceled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coletaState = _coletaState;
    final entregaState = _entregaState;

    return Column(
      children: [
        Row(
          children: [
            _TripStepDot(icon: Icons.inventory_2_outlined, state: coletaState),
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: coletaState == _TripStepState.done
                      ? GlmColors.accent
                      : const Color(0xFFF3DEC7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            _TripStepDot(icon: Icons.flag_outlined, state: entregaState),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TripStepText(
                title: 'Coleta',
                subtitle: _labelForState(coletaState),
                state: coletaState,
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TripStepText(
                title: 'Entrega',
                subtitle: _labelForState(entregaState),
                state: entregaState,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _labelForState(_TripStepState state) {
    switch (state) {
      case _TripStepState.pending:
        return 'Pendente';
      case _TripStepState.active:
        return 'Em rota';
      case _TripStepState.waiting:
        return 'Aguardando empresa';
      case _TripStepState.done:
        return 'Confirmada';
      case _TripStepState.canceled:
        return 'Cancelada';
    }
  }
}

class _TripStepDot extends StatelessWidget {
  const _TripStepDot({required this.icon, required this.state});

  final IconData icon;
  final _TripStepState state;

  Color get _color {
    switch (state) {
      case _TripStepState.active:
        return GlmColors.accentStrong;
      case _TripStepState.waiting:
        return const Color(0xFFB26A00);
      case _TripStepState.done:
        return const Color(0xFF2E7D32);
      case _TripStepState.canceled:
        return const Color(0xFFC62828);
      case _TripStepState.pending:
        return GlmColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = state != _TripStepState.pending;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active ? _color : const Color(0xFFFFF2E5),
        shape: BoxShape.circle,
        border: Border.all(color: active ? _color : GlmColors.border),
      ),
      child: Icon(
        state == _TripStepState.done ? Icons.check_rounded : icon,
        color: active ? Colors.white : GlmColors.textMuted,
        size: 18,
      ),
    );
  }
}

class _TripStepText extends StatelessWidget {
  const _TripStepText({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.textAlign,
  });

  final String title;
  final String subtitle;
  final _TripStepState state;
  final TextAlign textAlign;

  Color get _titleColor {
    return state == _TripStepState.pending
        ? GlmColors.textMuted
        : GlmColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _titleColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GlmColors.textMuted,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
