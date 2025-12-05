import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // se for usar algo de auth aqui depois
import 'cadastro_tipo_carroceria.dart';
import 'vehicle_data.dart';

class CadastroTipoVeiculoScreen extends StatefulWidget {
  const CadastroTipoVeiculoScreen({Key? key}) : super(key: key);

  @override
  State<CadastroTipoVeiculoScreen> createState() =>
      _CadastroTipoVeiculoScreenState();
}

class _CadastroTipoVeiculoScreenState extends State<CadastroTipoVeiculoScreen> {
  String? _tipoSelecionado;

  String _determinarTamanho(String tipo) {
    const pesados = {
      'Bitrem',
      'Carreta',
      'Carreta LS',
      'Rodotrem',
      'Vanderléia',
    };
    const medios = {
      'Bitruck',
      'Truck',
    };
    const leves = {
      '3/4',
      'Fiorino',
      'Toco',
      'VLC',
    };

    if (pesados.contains(tipo)) return 'Pesado';
    if (medios.contains(tipo)) return 'Médio';
    if (leves.contains(tipo)) return 'Leve';
    return 'Desconhecido';
  }

  void _proximo() {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de veículo')),
      );
      return;
    }

    final vehicleData = VehicleData(
      tipoVeiculo: _tipoSelecionado,
      tamanhoVeiculo: _determinarTamanho(_tipoSelecionado!),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroTipoCarroceriaScreen(vehicleData: vehicleData),
      ),
    );
  }

  Widget _radio(String label) {
    return RadioListTile<String>(
      value: label,
      groupValue: _tipoSelecionado,
      activeColor: Colors.orange,
      onChanged: (v) => setState(() => _tipoSelecionado = v),
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
              // TOPO IGUAL AO CADASTRO
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
                          'Selecione o tipo de veículo',
                          textAlign: TextAlign.center,
                        ),
                      ),
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
