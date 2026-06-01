import 'dart:io';

import 'package:app/widgets/glm_ui.dart';
import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilMotoristaScreen extends StatefulWidget {
  const PerfilMotoristaScreen({super.key});

  @override
  State<PerfilMotoristaScreen> createState() => _PerfilMotoristaScreenState();
}

class _PerfilMotoristaScreenState extends State<PerfilMotoristaScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  Map<String, dynamic>? usuario;
  Map<String, dynamic>? veiculo;
  bool carregando = true;
  bool _menuAberto = false;
  bool _salvandoFoto = false;
  File? _fotoSelecionada;
  Uint8List? _fotoSelecionadaWeb;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => carregando = true);

    var user = _supabase.auth.currentUser;

    var tentativas = 0;
    while (user == null && tentativas < 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      user = _supabase.auth.currentUser;
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
      final dadosUsuario = await _supabase
          .from('Usuario_Caminhoneiro')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final dadosVeiculo = await _supabase
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

  Future<void> _selecionarFotoPerfil() async {
    if (_salvandoFoto) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _fotoSelecionadaWeb = bytes;
        _fotoSelecionada = null;
      });
    } else {
      setState(() {
        _fotoSelecionada = File(pickedFile.path);
        _fotoSelecionadaWeb = null;
      });
    }

    await _salvarFotoPerfil();
  }

  Future<void> _salvarFotoPerfil() async {
    final user = _supabase.auth.currentUser;

    if (user == null ||
        (_fotoSelecionada == null && _fotoSelecionadaWeb == null)) {
      return;
    }

    setState(() => _salvandoFoto = true);

    try {
      final filePath = 'fotos_motoristas/${user.id}.jpg';
      final fileBytes = kIsWeb
          ? _fotoSelecionadaWeb!
          : await _fotoSelecionada!.readAsBytes();

      await _supabase.storage
          .from('fotos_motoristas')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final fotoUrl = _supabase.storage
          .from('fotos_motoristas')
          .getPublicUrl(filePath);

      final usuarioAtualizado = await _supabase
          .from('Usuario_Caminhoneiro')
          .update({'foto_url': fotoUrl})
          .eq('id', user.id)
          .select()
          .maybeSingle();

      if (usuarioAtualizado == null) {
        throw Exception(
          'A foto foi enviada, mas nao foi possivel salvar no perfil.',
        );
      }

      if (!mounted) return;

      setState(() {
        usuario = usuarioAtualizado;
        _fotoSelecionada = null;
        _fotoSelecionadaWeb = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao atualizar foto de perfil: $e. Se continuar, aplique a migration de update do perfil no Supabase.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoFoto = false);
      }
    }
  }

  ImageProvider<Object>? _fotoPerfilAtual() {
    if (kIsWeb && _fotoSelecionadaWeb != null) {
      return MemoryImage(_fotoSelecionadaWeb!);
    }

    if (!kIsWeb && _fotoSelecionada != null) {
      return FileImage(_fotoSelecionada!);
    }

    final fotoUrl = usuario?['foto_url']?.toString();
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }

    return null;
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

  void _visualizarFoto() {
    final fotoPerfil = _fotoPerfilAtual();
    if (fotoPerfil == null) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image(
                    image: fotoPerfil,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = (usuario?['foto_url']?.toString().isNotEmpty ?? false) ||
        _fotoSelecionada != null ||
        _fotoSelecionadaWeb != null;
    final fotoPerfil = _fotoPerfilAtual();

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
                  'Nao foi possivel carregar os dados do perfil.',
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
                    subtitle: 'Veja seus dados pessoais e o veiculo cadastrado.',
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: temFoto ? _visualizarFoto : null,
                        child: MouseRegion(
                          cursor: temFoto
                              ? SystemMouseCursors.click
                              : MouseCursor.defer,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: GlmColors.accentSoft,
                            backgroundImage: fotoPerfil,
                            child: fotoPerfil == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: GlmColors.accentStrong,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: GlmColors.border),
                        ),
                        child: IconButton(
                          onPressed:
                              _salvandoFoto ? null : _selecionarFotoPerfil,
                          icon: _salvandoFoto
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  temFoto
                                      ? Icons.edit_rounded
                                      : Icons.add_a_photo_outlined,
                                  color: GlmColors.accentStrong,
                                ),
                        ),
                      ),
                    ],
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
                        _linhaInfo('Genero', usuario!['genero']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlmInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Veiculo cadastrado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GlmColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (veiculo == null)
                          const Text(
                            'Nenhum veiculo cadastrado ainda.',
                            style: TextStyle(color: GlmColors.textMuted),
                          )
                        else ...[
                          _linhaInfo(
                            'Tipo do veiculo',
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
