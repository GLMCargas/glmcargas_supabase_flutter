import 'package:app/auth/account_access.dart';
import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountStatusPage extends StatefulWidget {
  const AccountStatusPage({
    super.key,
    required this.profile,
  });

  final AccountProfile profile;

  @override
  State<AccountStatusPage> createState() => _AccountStatusPageState();
}

class _AccountStatusPageState extends State<AccountStatusPage> {
  final _supabase = Supabase.instance.client;

  late AccountProfile _profile;
  bool _checkingStatus = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<List<Map<String, dynamic>>> _loadDocuments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final response = await _supabase
        .from('Documentos_Motorista')
        .select()
        .eq('motorista_id', user.id)
        .order('enviado_em', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refreshStatus() async {
    if (_checkingStatus) return;

    setState(() => _checkingStatus = true);

    try {
      await _supabase.auth.refreshSession();
      final access = await const AccountAccessService().resolveCurrentUser();

      if (!mounted) return;

      if (access.state == AccountAccessState.approved) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        return;
      }

      setState(() {
        if (access.profile != null) {
          _profile = access.profile!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status atual: ${_profile.status}.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar o status agora.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingStatus = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_signingOut) return;

    setState(() => _signingOut = true);

    try {
      await _supabase.auth.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Color _statusColor(String status) {
    if (AccountProfile.isApprovedStatus(status)) {
      return const Color(0xFFD8F1DE);
    }

    if (status == 'Reprovado') {
      return const Color(0xFFFFD9D4);
    }

    return const Color(0xFFFFE7C6);
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Em analise':
      case 'Em análise':
        return 'Seu cadastro esta em processamento. Enquanto isso, você pode acompanhar a conta e conferir os documentos enviados.';
      case 'Reprovado':
        return 'Seu cadastro ainda não foi aprovado. Consulte os documentos enviados e aguarde o retorno da equipe responsável.';
      case 'Pendente':
      default:
        return 'Recebemos seu cadastro e ele esta pendente de avaliação. Assim que a conta for aprovada, o acesso completo ao sistema será liberado.';
    }
  }

  String _documentLabel(String? tipo) {
    switch (tipo) {
      case 'CNH':
        return 'CNH';
      case 'Selfie':
        return 'Selfie';
      default:
        return tipo?.toString() ?? 'Documento';
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Envio sem data disponível';
    }

    try {
      final parsed = DateTime.parse(value).toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return 'Enviado em $day/$month/$year as $hour:$minute';
    } catch (_) {
      return 'Documento enviado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _profile.status;

    return GlmShell(
      header: GlmHeader(
        trailing: IconButton(
          onPressed: _signingOut ? null : _logout,
          icon: const Icon(Icons.logout_rounded, color: GlmColors.accent),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const GlmSectionHeader(
              title: 'Status da conta',
              subtitle:
                  'Seu acesso completo será liberado quando o cadastro for aprovado.',
            ),
            const SizedBox(height: 24),
            GlmInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ola, ${_profile.nome}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GlmColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Status atual: $status',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GlmColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage(status),
                    style: const TextStyle(
                      color: GlmColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadDocuments(),
              builder: (context, snapshot) {
                final docs = snapshot.data ?? const <Map<String, dynamic>>[];

                return GlmInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documentos enviados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GlmColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState != ConnectionState.done)
                        const Center(child: CircularProgressIndicator())
                      else if (docs.isEmpty)
                        const Text(
                          'Nenhum documento foi localizado ate o momento.',
                          style: TextStyle(color: GlmColors.textMuted),
                        )
                      else
                        ...docs.map(
                          (doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: GlmColors.accentStrong,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _documentLabel(doc['tipo']?.toString()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: GlmColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatDate(
                                          doc['enviado_em']?.toString(),
                                        ),
                                        style: const TextStyle(
                                          color: GlmColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            GlmPrimaryButton(
              label: 'Atualizar status',
              icon: Icons.refresh_rounded,
              loading: _checkingStatus,
              onPressed: _refreshStatus,
            ),
            const SizedBox(height: 12),
            GlmOutlinedAction(
              label: 'Sair da conta',
              icon: Icons.logout_rounded,
              onPressed: _signingOut ? null : _logout,
            ),
          ],
        ),
      ),
    );
  }
}
