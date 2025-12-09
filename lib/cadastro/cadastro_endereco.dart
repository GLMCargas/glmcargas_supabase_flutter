import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cadastro_tipo_veiculo.dart';

class CadastroEnderecoScreen extends StatefulWidget {
  const CadastroEnderecoScreen({Key? key}) : super(key: key);

  @override
  State<CadastroEnderecoScreen> createState() => _CadastroEnderecoScreenState();
}

class _CadastroEnderecoScreenState extends State<CadastroEnderecoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();

  bool _semNumero = false;

  @override
  void dispose() {
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Future<void> _salvarEndereco() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: usuário não autenticado.")),
      );
      return;
    }

    final dados = {
      "Usuario_CaminhoneiroID": user.id,
      "CEP": int.tryParse(_cepController.text.replaceAll(RegExp(r'\D'), '')),
      "Rua": _ruaController.text.trim(),
      "Bairro": _bairroController.text.trim(),
      "Cidade": _cidadeController.text.trim(),
      "UF": _ufController.text.trim(),
      "Numero": _semNumero
          ? 0
          : int.tryParse(
              _numeroController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ),
      "Complemento": _complementoController.text.trim().isEmpty
          ? null
          : _complementoController.text.trim(),
    };

    try {
      await supabase.from("Endereço").insert(dados);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroTipoVeiculoScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
                          "Endereço",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'Complete com os dados do seu endereço',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        _campo("CEP", _cepController),
                        _campo("Rua", _ruaController),
                        _campo("Bairro", _bairroController),

                        Row(
                          children: [
                            Expanded(
                              child: _campo("Cidade", _cidadeController),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: _campo("UF", _ufController),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: _campo(
                                "Número",
                                _numeroController,
                                validatorOverride: (v) {
                                  if (_semNumero) return null;
                                  return (v == null || v.isEmpty)
                                      ? "Obrigatório"
                                      : null;
                                },
                              ),
                            ),

                            Column(
                              children: [
                                Checkbox(
                                  value: _semNumero,
                                  onChanged: (v) =>
                                      setState(() => _semNumero = v ?? false),
                                ),
                                const Text(
                                  "Sem número",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),

                        _campo(
                          "Complemento (opcional)",
                          _complementoController,
                          validatorOverride: (_) => null,
                        ),

                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.centerRight,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _salvarEndereco,
                              child: Row(
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

  Widget _campo(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validatorOverride,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator:
            validatorOverride ??
            (v) => (v == null || v.isEmpty) ? "Campo obrigatório" : null,
        decoration: InputDecoration(
          labelText: "$label *",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
