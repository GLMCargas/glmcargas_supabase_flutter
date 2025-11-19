import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'documentos_cnh.dart';

class CadastroPlacaRntrcScreen extends StatefulWidget {
  const CadastroPlacaRntrcScreen({Key? key}) : super(key: key);

  @override
  State<CadastroPlacaRntrcScreen> createState() =>
      _CadastroPlacaRntrcScreenState();
}

class _CadastroPlacaRntrcScreenState extends State<CadastroPlacaRntrcScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _rntrcController = TextEditingController();

  @override
  void dispose() {
    _placaController.dispose();
    _rntrcController.dispose();
    super.dispose();
  }

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DocumentosCnhScreen(),
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
                      const Text(
                        'Cadastro de veículo',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Digite a placa e o RNTRC do veículo'),
                      const SizedBox(height: 24),
                      _CampoTexto(
                        label: 'Placa: *',
                        controller: _placaController,
                      ),
                      _CampoTexto(
                        label: 'RNTRC (ANTT): *',
                        controller: _rntrcController,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                child: Icon(Icons.info_outline, size: 18),
                              ),
                              WidgetSpan(child: SizedBox(width: 6)),
                              TextSpan(
                                  text:
                                      'Veja aqui onde encontrar o número do RNTRC'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CampoTexto({
    Key? key,
    required this.label,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
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
