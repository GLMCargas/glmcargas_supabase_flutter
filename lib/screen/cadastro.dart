import 'dart:io';
import 'package:app/cadastro/cadastro_endereco.dart';
import 'package:flutter/foundation.dart';
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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();

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
  Uint8List? _fotoSelecionadaWeb;
  String? _generoSelecionado;

  final ImagePicker _picker = ImagePicker();

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroEnderecoScreen()),
      );
    }
  }

  Future<void> _selecionarFoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _fotoSelecionadaWeb = bytes;
        _fotoSelecionada = null; 
      });
    } else {
      setState(() {
        _fotoSelecionada = File(pickedFile.path);
        _fotoSelecionadaWeb = null; 
      });
    }
  }

  Future<String?> _uploadFoto(String userId) async {
    if (_fotoSelecionada == null) return null;

    final supabase = Supabase.instance.client;
    final fileBytes = await _fotoSelecionada!.readAsBytes();

    final filePath = "fotos_motoristas/$userId.jpg";

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

    return supabase.storage.from("fotos_motoristas").getPublicUrl(filePath);
  }

  Future<void> _signUp() async {
    print("▶️ Iniciando cadastro...");

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

      final partes = _nascimentoController.text.split("/");
      final dataFormatada = "${partes[2]}-${partes[1]}-${partes[0]}";

      final signUpResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = signUpResponse.user;

      if (user == null) {
        throw "Erro ao criar usuário no AUTH.";
      }

      final userId = user.id;

      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final filePath = "fotos_motoristas/$userId.jpg";
      final dados = {
        "id": userId, 
        "email": _emailController.text.trim(),
        "nome": _nomeController.text.trim(),
        "sobrenome": _sobrenomeController.text.trim(),
        "cpf_cnpj": _cpfController.text.trim(),
        "data_nascimento": dataFormatada,
        "telefone": _telefoneController.text.trim(),
        "genero": _generoSelecionado,
        "foto_url": filePath,
      };

      await supabase.from("Usuario_Caminhoneiro").insert(dados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroEnderecoScreen()),
        );
      }
    } catch (e, stack) {
      print("ERRO NO CADASTRO:");
      print(e);
      print(stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao cadastrar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        const Center(
                          child: Text(
                            "Olá, Motorista!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Center(
                          child: Text(
                            "Criar conta",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Center(
                          child: Text(
                            "Complete os dados para criar sua conta",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Column(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _selecionarFoto,
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundImage: kIsWeb
                                        ? (_fotoSelecionadaWeb != null
                                              ? MemoryImage(
                                                  _fotoSelecionadaWeb!,
                                                )
                                              : null)
                                        : (_fotoSelecionada != null
                                              ? FileImage(_fotoSelecionada!)
                                              : null),
                                    child:
                                        (_fotoSelecionada == null &&
                                            _fotoSelecionadaWeb == null)
                                        ? const Icon(
                                            Icons.add_a_photo,
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _selecionarFoto,
                                  child: Text(
                                    "Adicionar foto",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildCampo(
                          "Email",
                          _emailController,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo("Nome", _nomeController),
                        const SizedBox(height: 16),

                        _buildCampo("Sobrenome", _sobrenomeController),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: usandoCnpj ? [cnpjMask] : [cpfMask],
                          validator: (v) => v == null || v.isEmpty
                              ? "Campo obrigatório"
                              : null,
                          decoration: InputDecoration(
                            labelText: "CPF/CNPJ *",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            final numbers = v.replaceAll(RegExp(r'\D'), '');
                            if (numbers.length > 11 && !usandoCnpj) {
                              setState(() => usandoCnpj = true);
                              _cpfController.clear();
                            } else if (numbers.length <= 11 && usandoCnpj) {
                              setState(() => usandoCnpj = false);
                              _cpfController.clear();
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildCampo(
                          "Data de Nascimento",
                          _nascimentoController,
                          mask: dataMask,
                          type: TextInputType.datetime,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo(
                          "Telefone",
                          _telefoneController,
                          mask: telefoneMask,
                          type: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) => v == null || v.isEmpty
                              ? "Campo obrigatório"
                              : null,
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

                        const SizedBox(height: 24),

                        const Text(
                          "Com qual gênero você se identifica?",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        RadioListTile(
                          title: const Text("Feminino"),
                          value: "Feminino",
                          groupValue: _generoSelecionado,
                          onChanged: (v) =>
                              setState(() => _generoSelecionado = v),
                        ),

                        RadioListTile(
                          title: const Text("Masculino"),
                          value: "Masculino",
                          groupValue: _generoSelecionado,
                          onChanged: (v) =>
                              setState(() => _generoSelecionado = v),
                        ),

                        RadioListTile(
                          title: const Text("Prefiro não informar"),
                          value: "Não Informar",
                          groupValue: _generoSelecionado,
                          onChanged: (v) =>
                              setState(() => _generoSelecionado = v),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(
    String label,
    TextEditingController controller, {
    TextInputFormatter? mask,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      inputFormatters: mask != null ? [mask] : null,
      validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
      decoration: InputDecoration(
        labelText: "$label *",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
