import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cadastro_tipo_veiculo.dart';

class CadastroEnderecoScreen extends StatefulWidget {
  const CadastroEnderecoScreen({super.key});

  @override
  State<CadastroEnderecoScreen> createState() => _CadastroEnderecoScreenState();
}

class _CadastroEnderecoScreenState extends State<CadastroEnderecoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();

  bool _semNumero = false;

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Future<void> _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: usuario nao autenticado.')),
      );
      return;
    }

    final dados = {
      'Usuario_CaminhoneiroID': user.id,
      'CEP': int.tryParse(_cepController.text.replaceAll(RegExp(r'\D'), '')),
      'Rua': _ruaController.text.trim(),
      'Bairro': _bairroController.text.trim(),
      'Cidade': _cidadeController.text.trim(),
      'UF': _ufController.text.trim().toUpperCase(),
      'Numero': _semNumero
          ? 0
          : int.tryParse(
              _numeroController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ),
      'Complemento': _complementoController.text.trim().isEmpty
          ? null
          : _complementoController.text.trim(),
    };

    try {
      await supabase.from('Endere\u00E7o').insert(dados);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroTipoVeiculoScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Endereco',
      subtitle: 'Complete com os dados do seu endereco.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _campo('CEP', _cepController),
            const SizedBox(height: 16),
            _campo('Rua', _ruaController),
            const SizedBox(height: 16),
            _campo('Bairro', _bairroController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _campo('Cidade', _cidadeController)),
                const SizedBox(width: 10),
                SizedBox(width: 92, child: _campo('UF', _ufController)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    'Numero',
                    _numeroController,
                    validatorOverride: (v) {
                      if (_semNumero) return null;
                      return (v == null || v.isEmpty)
                          ? 'Campo obrigatorio'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                GlmInfoCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Checkbox(
                        value: _semNumero,
                        onChanged: (v) {
                          setState(() => _semNumero = v ?? false);
                        },
                      ),
                      const Text('Sem numero', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _campo(
              'Complemento',
              _complementoController,
              validatorOverride: (_) => null,
              requiredField: false,
            ),
            const SizedBox(height: 24),
            GlmPrimaryButton(
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              onPressed: _salvarEndereco,
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validatorOverride,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      validator:
          validatorOverride ??
          (v) => (v == null || v.isEmpty) ? 'Campo obrigatorio' : null,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
      ),
    );
  }
}
