import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();

  // Máscaras
  final cpfMask = MaskTextInputFormatter(
    mask: "###.###.###-##",
    filter: {"#": RegExp(r'[0-9]')},
  );
  final cnpjMask = MaskTextInputFormatter(
    mask: "##.###.###/####-##",
    filter: {"#": RegExp(r'[0-9]')},
  );
  final telefoneMask = MaskTextInputFormatter(
    mask: "(##) #####-####",
    filter: {"#": RegExp(r'[0-9]')},
  );
  final dataMask = MaskTextInputFormatter(
    mask: "##/##/####",
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool usandoCnpj = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  File? _fotoSelecionada;

  String? _generoSelecionado;

  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarFoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _fotoSelecionada = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadFoto(String userId) async {
    if (_fotoSelecionada == null) return null;

    final supabase = Supabase.instance.client;
    final fileBytes = await _fotoSelecionada!.readAsBytes();

    final filePath = "motoristas/$userId.jpg";

    await supabase.storage
        .from("fotos_motoristas")
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: "image/jpeg",
            upsert: true,
          ),
        );

    final url = supabase.storage
        .from("fotos_motoristas")
        .getPublicUrl(filePath);

    return url;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_generoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selecione um gênero.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Criar usuário
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) throw "Erro ao criar usuário.";

      final userId = response.user!.id;

      // 2. Upload da foto (opcional)
      String? fotoUrl;
      if (_fotoSelecionada != null) {
        fotoUrl = await _uploadFoto(userId);
      }

      // 3. Inserir dados na tabela
      await supabase.from("Usuario_Caminhoneiro").insert({
        "id_auth": userId,
        "email": _emailController.text.trim(),
        "nome": _nomeController.text.trim(),
        "sobrenome": _sobrenomeController.text.trim(),
        "cpf_cnpj": _cpfController.text.trim(),
        "data_nascimento": _nascimentoController.text.trim(),
        "telefone": _telefoneController.text.trim(),
        "genero": _generoSelecionado,
        "foto_url": fotoUrl, // pode ser null
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      String mensagemErro = "Erro ao cadastrar. Tente novamente.";

      // Detecta erro de usuário já existente (422)
      if (e.toString().contains("422") ||
          e.toString().toLowerCase().contains("already registered") ||
          e.toString().toLowerCase().contains("user already exists")) {
        mensagemErro = "Este email já está cadastrado. Tente fazer login.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
      );
    }
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    TextInputFormatter? mask,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      inputFormatters: mask != null ? [mask] : null,
      validator: (value) =>
          (value == null || value.isEmpty) ? "Campo obrigatório" : null,
      decoration: InputDecoration(
        labelText: "$label *",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
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
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _selecionarFoto,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: _fotoSelecionada != null
                                ? FileImage(_fotoSelecionada!)
                                : null,
                            child: _fotoSelecionada == null
                                ? const Icon(Icons.add_a_photo, size: 30)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Adicionar foto",
                          style: TextStyle(color: Colors.orange),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  _campo(
                    "Email",
                    _emailController,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _campo("Nome", _nomeController),
                  const SizedBox(height: 16),

                  _campo("Sobrenome", _sobrenomeController),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: usandoCnpj ? [cnpjMask] : [cpfMask],
                    validator: (v) =>
                        v == null || v.isEmpty ? "Campo obrigatório" : null,
                    decoration: InputDecoration(
                      labelText: "CPF/CNPJ *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.replaceAll(RegExp(r'\D'), '').length > 11 &&
                          !usandoCnpj) {
                        setState(() => usandoCnpj = true);
                        _cpfController.clear();
                      } else if (v.replaceAll(RegExp(r'\D'), '').length <= 11 &&
                          usandoCnpj) {
                        setState(() => usandoCnpj = false);
                        _cpfController.clear();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  _campo(
                    "Data de Nascimento",
                    _nascimentoController,
                    mask: dataMask,
                    type: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),

                  _campo(
                    "Telefone",
                    _telefoneController,
                    mask: telefoneMask,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Campo obrigatório" : null,
                    decoration: InputDecoration(
                      labelText: "Senha *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Com qual gênero você se identifica?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  RadioListTile(
                    title: const Text("Feminino"),
                    value: "Feminino",
                    groupValue: _generoSelecionado,
                    onChanged: (v) => setState(() => _generoSelecionado = v),
                  ),

                  RadioListTile(
                    title: const Text("Masculino"),
                    value: "Masculino",
                    groupValue: _generoSelecionado,
                    onChanged: (v) => setState(() => _generoSelecionado = v),
                  ),

                  RadioListTile(
                    title: const Text("Prefiro não informar"),
                    value: "Não Informar",
                    groupValue: _generoSelecionado,
                    onChanged: (v) => setState(() => _generoSelecionado = v),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Cadastrar",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
