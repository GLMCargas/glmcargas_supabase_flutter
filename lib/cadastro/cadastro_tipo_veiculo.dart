import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'cadastro_tipo_carroceria.dart';

class CadastroTipoVeiculoScreen extends StatefulWidget {
  const CadastroTipoVeiculoScreen({Key? key}) : super(key: key);

  @override
  State<CadastroTipoVeiculoScreen> createState() =>
      _CadastroTipoVeiculoScreenState();
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
      MaterialPageRoute(
        builder: (_) => const CadastroTipoCarroceriaScreen(),
      ),
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
            const _TopoLogo(),
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
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('Selecione o tipo de veículo'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Pesados',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('Bitrem'),
                    _radio('Carreta'),
                    _radio('Carreta LS'),
                    _radio('Rodotrem'),
                    _radio('Vanderléia'),
                    const SizedBox(height: 12),
                    const Text('Médios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('Bitruck'),
                    _radio('Truck'),
                    const SizedBox(height: 12),
                    const Text('Leves',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('3/4'),
                    _radio('Fiorino'),
                    _radio('Toco'),
                    _radio('VLC'),
                    const SizedBox(height: 24),
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
