import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';

import 'cadastro_tipo_carroceria.dart';
import 'vehicle_data.dart';

class CadastroTipoVeiculoScreen extends StatefulWidget {
  const CadastroTipoVeiculoScreen({super.key});

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
      'VanderlÃ©ia',
    };
    const medios = {'Bitruck', 'Truck'};
    const leves = {'3/4', 'Fiorino', 'Toco', 'VLC'};

    if (pesados.contains(tipo)) return 'Pesado';
    if (medios.contains(tipo)) return 'Medio';
    if (leves.contains(tipo)) return 'Leve';
    return 'Desconhecido';
  }

  void _proximo() {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de veiculo.')),
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

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Cadastro de veiculo',
      subtitle: 'Selecione o tipo do veiculo para continuar o cadastro.',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<String>(
            groupValue: _tipoSelecionado,
            onChanged: (value) {
              setState(() => _tipoSelecionado = value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _group('Pesados', const [
                  'Bitrem',
                  'Carreta',
                  'Carreta LS',
                  'Rodotrem',
                  'VanderlÃ©ia',
                ]),
                const SizedBox(height: 16),
                _group('Medios', const ['Bitruck', 'Truck']),
                const SizedBox(height: 16),
                _group('Leves', const ['3/4', 'Fiorino', 'Toco', 'VLC']),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlmPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            onPressed: _proximo,
          ),
        ],
      ),
    );
  }

  Widget _group(String label, List<String> options) {
    return GlmInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: GlmColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...options.map(_radio),
        ],
      ),
    );
  }

  Widget _radio(String label) {
    return RadioListTile<String>(
      value: label,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
    );
  }
}
