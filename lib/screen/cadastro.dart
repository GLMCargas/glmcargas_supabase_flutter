import 'dart:io';
import 'package:app/cadastro/cadastro_endereco.dart';
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

    return supabase.storage.from("fotos_motoristas").getPublicUrl(filePath);
  }

  Future<void> _signUp() async {
    print("▶️ Iniciando cadastro sem Auth...");

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

      // FORMATAR DATA
      final partes = _nascimentoController.text.split("/");
      final dataPostgres = "${partes[2]}-${partes[1]}-${partes[0]}";

      // DADOS PARA SALVAR ANTES DO AUTH
      final dados = {
        "email": _emailController.text.trim(),
        "nome": _nomeController.text.trim(),
        "sobrenome": _sobrenomeController.text.trim(),
        "cpf_cnpj": _cpfController.text.replaceAll(RegExp(r'\D'), ''),
        "data_nascimento": dataPostgres,
        "telefone": _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
        "genero": _generoSelecionado,
      };

      print("📦 Inserindo na tabela Usuario_Caminhoneiro...");
      final insertResponse = await supabase
          .from("Usuario_Caminhoneiro")
          .insert(dados)
          .select()
          .single();

      print("✔️ Inserido no banco: $insertResponse");

      // AGORA CRIA O AUTH
      print("📨 Criando usuário no AUTH...");
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw "Falha ao criar usuário no AUTH";
      }

      final userId = authResponse.user!.id;
      print("✔️ Auth criado com ID: $userId");

      // ATUALIZA LINHA COM ID DO AUTH
      print("📨 Atualizando tabela com ID Auth...");
      await supabase
          .from("Usuario_Caminhoneiro")
          .update({"id": userId})
          .eq("email", _emailController.text.trim());

      print("✔️ Linha atualizada com ID Auth!");

      // FINALIZA
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        _proximo();
      }
    } catch (e, st) {
      print("❌ ERRO NO CADASTRO:");
      print(e);
      print(st);

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
              // 🔶🔶🔶 TOPO FIXO DENTRO DA ÁREA BRANCA 🔶🔶🔶
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

              // 🔶🔶🔶 ÁREA ROLÁVEL 🔶🔶🔶
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        /// TÍTULOS
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

                        /// FOTO DO MOTORISTA
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
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// CAMPOS DO FORMULÁRIO
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

                        /// GÊNERO
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

                        /// BOTÃO DE CADASTRO
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

  /// Campo padrão
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
