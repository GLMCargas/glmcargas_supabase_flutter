import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'cadastro_tipo_veiculo.dart';

class CadastroEnderecoScreen extends StatefulWidget {
  const CadastroEnderecoScreen({Key? key}) : super(key: key);

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

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CadastroTipoVeiculoScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _TopoLogo(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Endereço',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Complete com os dados do seu endereço',
                      ),
                      const SizedBox(height: 24),
                      _CampoTexto(
                        label: 'CEP: *',
                        controller: _cepController,
                      ),
                      _CampoTexto(
                        label: 'Rua: *',
                        controller: _ruaController,
                      ),
                      _CampoTexto(
                        label: 'Bairro: *',
                        controller: _bairroController,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _CampoTexto(
                              label: 'Cidade: *',
                              controller: _cidadeController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _CampoTexto(
                              label: 'UF: *',
                              controller: _ufController,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _CampoTexto(
                              label: 'Número: *',
                              controller: _numeroController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CampoTexto(
                              label: 'Complemento (opcional):',
                              controller: _complementoController,
                              validatorOverride: (_) => null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Cadastre seu veículo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _BotaoSetaGrande(onTap: _proximo),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// reaproveita os widgets do primeiro arquivo:

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validatorOverride;

  const _CampoTexto({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validatorOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validatorOverride ??
            (value) =>
                (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
        ),
      ),
    );
  }
}

class _TopoLogo extends StatelessWidget {
  const _TopoLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const _TopoLogoBase();
  }
}

class _BotaoSetaGrande extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoSetaGrande({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => _BotaoSetaGrandeBase(onTap: onTap);
}

// para não duplicar, usei estas classes base vindas do primeiro arquivo:
class _TopoLogoBase extends StatelessWidget {
  const _TopoLogoBase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: const [
              Icon(Icons.local_shipping, color: kPrimaryColor),
              SizedBox(width: 4),
              Text(
                'GLM',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              Text(
                'CARGAS',
                style: TextStyle(color: kPrimaryColor),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.menu, size: 28),
        ],
      ),
    );
  }
}

class _BotaoSetaGrandeBase extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoSetaGrandeBase({Key? key, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(radius: 6, backgroundColor: kPrimaryColor),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 40, color: kPrimaryColor),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 50, color: Color(0xFFFFC89C)),
        ],
      ),
    );
  }
}
