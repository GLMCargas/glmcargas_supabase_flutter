import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';

import 'cadastro_placa_rntrc.dart';
import 'vehicle_data.dart';

class CadastroTipoCarroceriaScreen extends StatefulWidget {
  const CadastroTipoCarroceriaScreen({super.key, required this.vehicleData});

  final VehicleData vehicleData;

  @override
  State<CadastroTipoCarroceriaScreen> createState() =>
      _CadastroTipoCarroceriaScreenState();
}

class _CadastroTipoCarroceriaScreenState
    extends State<CadastroTipoCarroceriaScreen> {
  String? _carroceriaSelecionada;

  String _determinarCategoriaBau(String tipoBau) {
    const fechadas = {'BaÃº', 'BaÃº FrigorÃ­fico', 'BaÃº Refrigerado', 'Sider'};
    const abertas = {
      'CaÃ§amba',
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
        const SnackBar(content: Text('Selecione um tipo de carroceria.')),
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

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Tipo de carroceria',
      subtitle: 'Escolha o modelo de carroceria utilizado no veiculo.',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<String>(
            groupValue: _carroceriaSelecionada,
            onChanged: (value) {
              setState(() => _carroceriaSelecionada = value);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _group('Fechadas', const [
                  'BaÃº',
                  'BaÃº FrigorÃ­fico',
                  'BaÃº Refrigerado',
                  'Sider',
                ]),
                const SizedBox(height: 16),
                _group('Abertas', const [
                  'CaÃ§amba',
                  'Grade Baixa',
                  'Graneleiro',
                  'Plataforma',
                  'Prancha',
                ]),
                const SizedBox(height: 16),
                _group('Especiais', const [
                  'Apenas Cavalo',
                  'Bug Porta Container',
                  'Cavaqueira',
                  'Cegonheiro',
                  'Gaiola',
                  'Hopper',
                  'Munck',
                  'Silo',
                  'Tanque',
                ]),
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
