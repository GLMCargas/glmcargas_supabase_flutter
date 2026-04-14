import 'package:app/widgets/glm_ui.dart';
import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilMotoristaScreen extends StatefulWidget {
  const PerfilMotoristaScreen({super.key});

  @override
  State<PerfilMotoristaScreen> createState() => _PerfilMotoristaScreenState();
}

class _PerfilMotoristaScreenState extends State<PerfilMotoristaScreen> {
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? veiculo;
  bool carregando = true;
  bool _menuAberto = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final supabase = Supabase.instance.client;

    if (!mounted) return;
    setState(() => carregando = true);

    var user = supabase.auth.currentUser;

    var tentativas = 0;
    while (user == null && tentativas < 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      user = supabase.auth.currentUser;
      tentativas++;
    }

    if (user == null) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        usuario = null;
        veiculo = null;
      });
      return;
    }

    try {
      final dadosUsuario = await supabase
          .from('Usuario_Caminhoneiro')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final dadosVeiculo = await supabase
          .from('Veiculo')
          .select()
          .eq('Usuario_CaminhoneiroID', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        usuario = dadosUsuario;
        veiculo = dadosVeiculo;
        carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return '-';
    final partes = valor.toString().split('-');
    if (partes.length != 3) return valor.toString();
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Aprovado':
        return const Color(0xFFD7F4DB);
      case 'Reprovado':
        return const Color(0xFFFFD8D3);
      default:
        return const Color(0xFFFFE8C9);
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
        current: GlmBottomNavItem.profile,
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
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : usuario == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar os dados do perfil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: GlmColors.textMuted),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  const GlmSectionHeader(
                    title: 'Meu perfil',
                    subtitle:
                        'Veja seus dados pessoais e o veículo cadastrado.',
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: GlmColors.accentSoft,
                    backgroundImage: usuario!['foto_url'] != null
                        ? NetworkImage(usuario!['foto_url'])
                        : null,
                    child: usuario!['foto_url'] == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: GlmColors.accentStrong,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${usuario!['nome'] ?? ''} ${usuario!['sobrenome'] ?? ''}'
                        .trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: GlmColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(usuario!['status']?.toString()),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Status: ${usuario!['status'] ?? 'Pendente'}',
                      style: const TextStyle(
                        color: GlmColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlmInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dados pessoais',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GlmColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _linhaInfo('Email', usuario!['email']),
                        _linhaInfo('Telefone', usuario!['telefone']),
                        _linhaInfo(
                          'Nascimento',
                          _formatarData(usuario!['data_nascimento']),
                        ),
                        _linhaInfo('Gênero', usuario!['genero']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlmInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Veículo cadastrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GlmColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (veiculo == null)
                          const Text(
                            'Nenhum veículo cadastrado ainda.',
                            style: TextStyle(color: GlmColors.textMuted),
                          )
                        else ...[
                          _linhaInfo(
                            'Tipo do veículo',
                            veiculo!['TipoVeiculo'],
                          ),
                          _linhaInfo('Carroceria', veiculo!['TipoBau']),
                          _linhaInfo('Placa', veiculo!['PlacaVeiculo']),
                          _linhaInfo('RNTRC', veiculo!['RNTRC_ANTT']),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _linhaInfo(String label, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: GlmColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valor?.toString() ?? '-',
              style: const TextStyle(color: GlmColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
