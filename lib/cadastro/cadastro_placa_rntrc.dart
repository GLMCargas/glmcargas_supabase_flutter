import 'package:app/services/app_error_messages.dart';
import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _placaNormalizada(String valor) {
    return valor.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  String _rntrcNormalizado(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  String? _validarPlaca(String? valor) {
    final placa = _placaNormalizada(valor ?? '');

    if (placa.isEmpty) {
      return 'Campo obrigatorio';
    }

    final placaValida = RegExp(r'^[A-Z]{3}[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$');
    if (!placaValida.hasMatch(placa)) {
      return 'Informe uma placa valida';
    }

    return null;
  }

  String? _validarRntrc(String? valor) {
    final rntrc = _rntrcNormalizado(valor ?? '');

    if (rntrc.isEmpty) {
      return 'Campo obrigatorio';
    }

    if (rntrc.length != 8 && rntrc.length != 9) {
      return 'Informe 8 numeros do RNTRC ou 9 com zero a esquerda';
    }

    return null;
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: usuario nao autenticado.')),
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
          content: Text('Erro interno: dados do veiculo incompletos.'),
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
        'PlacaVeiculo': _placaNormalizada(_placaController.text),
        'RNTRC_ANTT': _rntrcNormalizado(_rntrcController.text),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosCnhScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorMessages.signup(e)),
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
      title: 'Dados do veiculo',
      subtitle: 'Digite a placa e o RNTRC para concluir o cadastro do veiculo.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _placaController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(7),
                _PlacaVeiculoInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Placa *',
                hintText: 'Ex.: ABC-1234',
              ),
              validator: _validarPlaca,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rntrcController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                labelText: 'RNTRC (ANTT) *',
                hintText: 'Ex.: 12345678',
              ),
              validator: _validarRntrc,
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
                        'Veja como localizar o numero do RNTRC (ANTT).',
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

class _PlacaVeiculoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final limited = raw.length > 7 ? raw.substring(0, 7) : raw;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3) {
        buffer.write('-');
      }
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
