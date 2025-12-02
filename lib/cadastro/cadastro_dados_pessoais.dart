import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'
    show MaskTextInputFormatter;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cadastro_endereco.dart';

const Color kBackgroundColor = Color(0xFFFBD5B8);
const Color kPrimaryColor = Color(0xFFE48333);

class CadastroDadosPessoaisScreen extends StatefulWidget {
  const CadastroDadosPessoaisScreen({Key? key}) : super(key: key);

  @override
  State<CadastroDadosPessoaisScreen> createState() =>
      _CadastroDadosPessoaisScreenState();
}

class _CadastroDadosPessoaisScreenState
    extends State<CadastroDadosPessoaisScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();

  String? _genero;

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

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfController.dispose();
    _nascimentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      // aqui você pode guardar os dados em algum modelo/global se quiser
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroEnderecoScreen()),
      );
    }
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
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _TopoLogo(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Olá, Motorista !',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Criar conta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Complete os dados para criar sua conta',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CampoTexto(
                        label: 'Email: *',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _CampoTexto(
                        label: 'Nome: *',
                        controller: _nomeController,
                      ),
                      _CampoTexto(
                        label: 'Sobrenome: *',
                        controller: _sobrenomeController,
                      ),
                      _CampoTexto(
                        label: 'CPF/CNPJ: *',
                        controller: _cpfController,
                      ),
                      _CampoTexto(
                        label: 'Data de Nascimento: *',
                        controller: _nascimentoController,
                        keyboardType: TextInputType.datetime,
                      ),
                      _CampoTexto(
                        label: 'Telefone: *',
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                      ),
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
                      const SizedBox(height: 16),
                      const Text(
                        'Com qual gênero você se identifica?',
                        style: TextStyle(fontSize: 16),
                      ),
                      RadioListTile<String>(
                        value: 'Feminino',
                        groupValue: _genero,
                        activeColor: kPrimaryColor,
                        title: const Text('Feminino'),
                        onChanged: (v) => setState(() => _genero = v),
                      ),
                      RadioListTile<String>(
                        value: 'Masculino',
                        groupValue: _genero,
                        activeColor: kPrimaryColor,
                        title: const Text('Masculino'),
                        onChanged: (v) => setState(() => _genero = v),
                      ),
                      RadioListTile<String>(
                        value: 'Prefiro não informar',
                        groupValue: _genero,
                        activeColor: kPrimaryColor,
                        title: const Text('Prefiro não informar'),
                        onChanged: (v) => setState(() => _genero = v),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: _BotaoSetaGrande(onTap: _proximo),
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
    );
  }
}

/// topo com logo e menu igual às telas
class _TopoLogo extends StatelessWidget {
  const _TopoLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: kBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // logo fake
          Row(
            children: const [
              Icon(Icons.local_shipping, color: kPrimaryColor),
              SizedBox(width: 4),
              Text(
                'GLM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              Text('CARGAS', style: TextStyle(color: kPrimaryColor)),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [Icon(Icons.menu, size: 28)],
          ),
        ],
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _CampoTexto({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _BotaoSetaGrande extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoSetaGrande({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(radius: 6, backgroundColor: kPrimaryColor),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 40, color: kPrimaryColor),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 50, color: Color(0xFFFFC89C)),
        ],
      ),
    );
  }
}
