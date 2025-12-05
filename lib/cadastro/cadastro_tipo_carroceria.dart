import 'package:flutter/material.dart';
import 'cadastro_placa_rntrc.dart';
import 'vehicle_data.dart';

class CadastroTipoCarroceriaScreen extends StatefulWidget {
  final VehicleData vehicleData;

  const CadastroTipoCarroceriaScreen({
    Key? key,
    required this.vehicleData,
  }) : super(key: key);

  @override
  State<CadastroTipoCarroceriaScreen> createState() =>
      _CadastroTipoCarroceriaScreenState();
}

class _CadastroTipoCarroceriaScreenState
    extends State<CadastroTipoCarroceriaScreen> {
  String? _carroceriaSelecionada;

  String _determinarCategoriaBau(String tipoBau) {
    const fechadas = {
      'Baú',
      'Baú Frigorífico',
      'Baú Refrigerado',
      'Sider',
    };
    const abertas = {
      'Caçamba',
      'Grade Baixa',
      'Graneleiro',
      'Plataforma',
      'Prancha',
    };
    const especiais = {
      'Apenas Cavalo',
      'Bug Porta Container',
      'Cavaqueira',
      'Cegonheiro',
      'Gaiola',
      'Hopper',
      'Munck',
      'Silo',
      'Tanque',
    };

    if (fechadas.contains(tipoBau)) return 'Fechado';
    if (abertas.contains(tipoBau)) return 'Aberto';
    if (especiais.contains(tipoBau)) return 'Especial';
    return 'Outro';
  }

  void _proximo() {
    if (_carroceriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de carroceria')),
      );
      return;
    }

    final categoria = _determinarCategoriaBau(_carroceriaSelecionada!);

    final updated = widget.vehicleData.copyWith(
      tipoBau: _carroceriaSelecionada,
      bauVeiculo: categoria,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroPlacaRntrcScreen(vehicleData: updated),
      ),
    );
  }

  Widget _radio(String label) {
    return RadioListTile<String>(
      value: label,
      groupValue: _carroceriaSelecionada,
      activeColor: Colors.orange,
      onChanged: (v) => setState(() => _carroceriaSelecionada = v),
      title: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // TOPO
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.local_shipping, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      "GLM",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "CARGAS",
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                    Spacer(),
                    Icon(Icons.menu, color: Colors.orange, size: 28),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
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
                      const Center(
                        child: Text(
                          'Selecione o tipo de carroceria',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Fechadas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _radio('Baú'),
                      _radio('Baú Frigorífico'),
                      _radio('Baú Refrigerado'),
                      _radio('Sider'),

                      const SizedBox(height: 12),

                      const Text(
                        'Abertas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _radio('Caçamba'),
                      _radio('Grade Baixa'),
                      _radio('Graneleiro'),
                      _radio('Plataforma'),
                      _radio('Prancha'),

                      const SizedBox(height: 12),

                      const Text(
                        'Especiais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _proximo,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.play_arrow,
                                  size: 40, color: Colors.orange),
                              SizedBox(width: 4),
                              Icon(Icons.play_arrow,
                                  size: 50, color: Color(0xFFFFC89C)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
