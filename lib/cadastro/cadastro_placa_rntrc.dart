import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cadastro_dados_pessoais.dart';
import 'documentos_cnh.dart';

class CadastroPlacaRntrcScreen extends StatefulWidget {
  const CadastroPlacaRntrcScreen({Key? key}) : super(key: key);

  @override
  State<CadastroPlacaRntrcScreen> createState() =>
      _CadastroPlacaRntrcScreenState();
}

class _BotaoSetaGrandeBase extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoSetaGrandeBase({Key? key, required this.onTap}) : super(key: key);

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

class _BotaoSetaGrande extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoSetaGrande({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => _BotaoSetaGrandeBase(onTap: onTap);
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
        MaterialPageRoute(builder: (_) => const DocumentosCnhScreen()),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(
                            'https://consultas.antt.gov.br/…',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.info_outline, size: 18),
                                ),
                                const WidgetSpan(child: SizedBox(width: 6)),
                                TextSpan(
                                  text:
                                      'Veja aqui onde encontrar o número do RNTRC',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(alignment: Alignment.bottomRight),
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

  const _CampoTexto({Key? key, required this.label, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
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
