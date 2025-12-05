import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vehicle_data.dart';
import 'documentos_cnh.dart';

class CadastroPlacaRntrcScreen extends StatefulWidget {
  final VehicleData vehicleData;

  const CadastroPlacaRntrcScreen({Key? key, required this.vehicleData})
    : super(key: key);

  @override
  State<CadastroPlacaRntrcScreen> createState() =>
      _CadastroPlacaRntrcScreenState();
}

class _CadastroPlacaRntrcScreenState extends State<CadastroPlacaRntrcScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _rntrcController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _placaController.dispose();
    _rntrcController.dispose();
    super.dispose();
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: usuário não autenticado.")),
      );
      return;
    }

    // Garantir que os campos essenciais não são nulos
    final v = widget.vehicleData;
    if (v.tipoVeiculo == null ||
        v.tamanhoVeiculo == null ||
        v.bauVeiculo == null ||
        v.tipoBau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro interno: dados do veículo incompletos."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dados = {
        "Usuario_CaminhoneiroID": user.id,
        "TamanhoVeiculo": v.tamanhoVeiculo,
        "TipoVeiculo": v.tipoVeiculo,
        "BauVeiculo": v.bauVeiculo,
        "TipoBau": v.tipoBau,
        "PlacaVeiculo": _placaController.text.trim(),
        "RNTRC_ANTT": _rntrcController.text.trim(),
      };

      await supabase.from("Veiculo").insert(dados);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosCnhScreen()),
      );
    } catch (e, stack) {
      print("❌ ERRO AO SALVAR VEÍCULO:");
      print(e);
      print(stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar veículo: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Cadastro de veículo',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Digite a placa e o RNTRC do veículo',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _placaController,
                          decoration: InputDecoration(
                            labelText: "Placa *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.orange.shade100,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _rntrcController,
                          decoration: InputDecoration(
                            labelText: "RNTRC (ANTT) *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.orange.shade100,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Veja no documento do veículo onde encontrar o número do RNTRC (ANTT).',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _salvarVeiculo,
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        CircleAvatar(
                                          radius: 6,
                                          backgroundColor: Colors.orange,
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.play_arrow,
                                          size: 40,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.play_arrow,
                                          size: 50,
                                          color: Color(0xFFFFC89C),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
