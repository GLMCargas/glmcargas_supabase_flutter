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

  final telefoneMask = MaskTextInputFormatter(
    mask: "(##) #####-####",
    filter: {"#": RegExp(r'[0-9]')},
  );

  final dataMask = MaskTextInputFormatter(
    mask: "##/##/####",
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _obscurePassword = true;
  bool _isLoading = false;

  File? _fotoSelecionada;
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

    return supabase.storage.from("fotos_motoristas").getPublicUrl(filePath);
  }

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroEnderecoScreen()),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _TopoLogo(), // FICA FIXO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 20),

                      /// FOTO + TEXTO
                      Center(
                        child: Column(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
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
                            ),

                            const SizedBox(height: 10),

                            /// TEXTO CLICÁVEL TAMBÉM
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _selecionarFoto,
                                child: const Text(
                                  "Adicionar foto",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Complete os dados para criar sua conta',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _CampoTexto(
                        label: 'Email:',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _CampoTexto(label: 'Nome:', controller: _nomeController),
                      _CampoTexto(
                        label: 'Sobrenome:',
                        controller: _sobrenomeController,
                      ),
                      _CampoTexto(
                        label: 'CPF/CNPJ:',
                        controller: _cpfController,
                      ),
                      _CampoTexto(
                        label: 'Data de Nascimento:',
                        controller: _nascimentoController,
                        keyboardType: TextInputType.datetime,
                      ),
                      _CampoTexto(
                        label: 'Telefone:',
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
          const Icon(Icons.menu, size: 28),
        ],
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _CampoTexto({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
        decoration: InputDecoration(
          labelText: "$label *",
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
