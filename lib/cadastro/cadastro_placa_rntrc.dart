import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'documentos_cnh.dart';
import 'vehicle_data.dart';

class CadastroPlacaRntrcScreen extends StatefulWidget {
  const CadastroPlacaRntrcScreen({super.key, required this.vehicleData});

  final VehicleData vehicleData;

  @override
  State<CadastroPlacaRntrcScreen> createState() =>
      _CadastroPlacaRntrcScreenState();
}

class _CadastroPlacaRntrcScreenState extends State<CadastroPlacaRntrcScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _rntrcController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _placaController.dispose();
    _rntrcController.dispose();
    super.dispose();
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: usuário não autenticado.')),
      );
      return;
    }

    final v = widget.vehicleData;
    if (v.tipoVeiculo == null ||
        v.tamanhoVeiculo == null ||
        v.bauVeiculo == null ||
        v.tipoBau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro interno: dados do veículo incompletos.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('Veiculo').insert({
        'Usuario_CaminhoneiroID': user.id,
        'TamanhoVeiculo': v.tamanhoVeiculo,
        'TipoVeiculo': v.tipoVeiculo,
        'BauVeiculo': v.bauVeiculo,
        'TipoBau': v.tipoBau,
        'PlacaVeiculo': _placaController.text.trim(),
        'RNTRC_ANTT': _rntrcController.text.trim(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosCnhScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar veículo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirAjudaRntrc() async {
    const url = 'https://consultapublica.antt.gov.br/Site/ConsultaRNTRC.aspx';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Dados do veículo',
      subtitle: 'Digite a placa e o RNTRC para concluir o cadastro do veículo.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(labelText: 'Placa *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rntrcController,
              decoration: const InputDecoration(labelText: 'RNTRC (ANTT) *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 18),
            GlmInfoCard(
              child: InkWell(
                onTap: _abrirAjudaRntrc,
                borderRadius: BorderRadius.circular(18),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Veja como localizar o número do RNTRC (ANTT).',
                        style: TextStyle(
                          color: GlmColors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GlmPrimaryButton(
              label: 'Enviar documentos',
              icon: Icons.arrow_forward_rounded,
              loading: _isLoading,
              onPressed: _salvarVeiculo,
            ),
          ],
        ),
      ),
    );
  }
}
