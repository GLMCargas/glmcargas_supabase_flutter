import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'cadastro_tipo_carroceria.dart';

class CadastroTipoVeiculoScreen extends StatefulWidget {
  const CadastroTipoVeiculoScreen({Key? key}) : super(key: key);

  @override
  State<CadastroTipoVeiculoScreen> createState() =>
      _CadastroTipoVeiculoScreenState();
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

class _CadastroTipoVeiculoScreenState extends State<CadastroTipoVeiculoScreen> {
  String? _tipoSelecionado;

  void _proximo() {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de veículo')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CadastroTipoCarroceriaScreen()),
    );
  }

  Widget _radio(String label) {
    return RadioListTile<String>(
      value: label,
      groupValue: _tipoSelecionado,
      activeColor: kPrimaryColor,
      onChanged: (v) => setState(() => _tipoSelecionado = v),
      title: Text(label),
    );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Cadastro de veículo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(child: Text('Selecione o tipo de veículo')),
                    const SizedBox(height: 24),
                    const Text(
                      'Pesados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _radio('Bitrem'),
                    _radio('Carreta'),
                    _radio('Carreta LS'),
                    _radio('Rodotrem'),
                    _radio('Vanderléia'),
                    const SizedBox(height: 12),
                    const Text(
                      'Médios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _radio('Bitruck'),
                    _radio('Truck'),
                    const SizedBox(height: 12),
                    const Text(
                      'Leves',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _radio('3/4'),
                    _radio('Fiorino'),
                    _radio('Toco'),
                    _radio('VLC'),
                    const SizedBox(height: 24),
                    Align(alignment: Alignment.bottomRight),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _BotaoSetaGrande(onTap: _proximo),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
