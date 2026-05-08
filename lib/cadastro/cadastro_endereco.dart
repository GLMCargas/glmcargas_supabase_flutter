import 'dart:convert';

import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  final _numeroFocusNode = FocusNode();
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _semNumero = false;
  bool _isBuscandoCep = false;
  String? _ultimoCepBuscado;

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _numeroFocusNode.dispose();
    super.dispose();
  }

  String _somenteDigitos(String valor) {
    return valor.replaceAll(RegExp(r'\D'), '');
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : null,
      ),
    );
  }

  Future<void> _buscarCep({bool force = false}) async {
    final cep = _somenteDigitos(_cepController.text);

    if (cep.length != 8 || _isBuscandoCep) {
      return;
    }

    if (!force && _ultimoCepBuscado == cep) {
      return;
    }

    setState(() => _isBuscandoCep = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode != 200) {
        throw StateError('Falha ao consultar o CEP.');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw StateError('Resposta invalida do servico de CEP.');
      }

      if (data['erro'] == true) {
        _mostrarMensagem('CEP nao encontrado. Confira o numero informado.');
        return;
      }

      _ruaController.text = (data['logradouro'] ?? '').toString().trim();
      _bairroController.text = (data['bairro'] ?? '').toString().trim();
      _cidadeController.text = (data['localidade'] ?? '').toString().trim();
      _ufController.text = (data['uf'] ?? '').toString().trim().toUpperCase();

      final complemento = (data['complemento'] ?? '').toString().trim();
      if (complemento.isNotEmpty && _complementoController.text.trim().isEmpty) {
        _complementoController.text = complemento;
      }

      _ultimoCepBuscado = cep;

      if (!mounted) return;
      FocusScope.of(context).requestFocus(_numeroFocusNode);
    } catch (_) {
      _mostrarMensagem(
        'Nao foi possivel buscar o CEP agora. Voce pode preencher manualmente.',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isBuscandoCep = false);
      }
    }
  }

  Future<void> _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _mostrarMensagem('Erro: usuario nao autenticado.', erro: true);
      return;
    }

    final dados = {
      'Usuario_CaminhoneiroID': user.id,
      'CEP': int.tryParse(_somenteDigitos(_cepController.text)),
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
      _mostrarMensagem('Erro ao salvar: $e', erro: true);
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
            _campo(
              'CEP',
              _cepController,
              keyboardType: TextInputType.number,
              inputFormatters: [_cepMask],
              onChanged: (value) {
                final cep = _somenteDigitos(value);

                if (cep.length < 8) {
                  _ultimoCepBuscado = null;
                  return;
                }

                _buscarCep();
              },
              suffixIcon: _isBuscandoCep
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: () => _buscarCep(force: true),
                      icon: const Icon(Icons.search_rounded),
                    ),
            ),
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
                    focusNode: _numeroFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      const Text('S/N', style: TextStyle(fontSize: 12)),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator:
          validatorOverride ??
          (v) => (v == null || v.isEmpty) ? 'Campo obrigatorio' : null,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
