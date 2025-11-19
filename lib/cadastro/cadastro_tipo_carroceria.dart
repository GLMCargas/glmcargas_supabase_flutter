import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'cadastro_placa_rntrc.dart';

class CadastroTipoCarroceriaScreen extends StatefulWidget {
  const CadastroTipoCarroceriaScreen({Key? key}) : super(key: key);

  @override
  State<CadastroTipoCarroceriaScreen> createState() =>
      _CadastroTipoCarroceriaScreenState();
}

class _CadastroTipoCarroceriaScreenState
    extends State<CadastroTipoCarroceriaScreen> {
  String? _carroceria;

  void _proximo() {
    if (_carroceria == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de carroceria')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CadastroPlacaRntrcScreen(),
      ),
    );
  }

  Widget _radio(String label) {
    return RadioListTile<String>(
      value: label,
      groupValue: _carroceria,
      activeColor: kPrimaryColor,
      onChanged: (v) => setState(() => _carroceria = v),
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
                      child: Text('Selecione o tipo de carroceria'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Fechadas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('Baú'),
                    _radio('Baú Frigorífico'),
                    _radio('Baú Refrigerado'),
                    _radio('Sider'),
                    const SizedBox(height: 12),
                    const Text('Abertas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('Caçamba'),
                    _radio('Grade Baixa'),
                    _radio('Graneleiro'),
                    _radio('Plataforma'),
                    _radio('Prancha'),
                    const SizedBox(height: 12),
                    const Text('Especiais',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _radio('Apenas Cavalo'),
                    _radio('Bug Porta Container'),
                    _radio('Cavaqueira'),
                    _radio('Cegonheiro'),
                    _radio('Gaiola'),
                    _radio('Hopper'),
                    _radio('Munck'),
                    _radio('Silo'),
                    _radio('Tanque'),
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
