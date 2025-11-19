import 'package:flutter/material.dart';
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
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _dataNascController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  String? _genero;

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfCnpjController.dispose();
    _dataNascController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _proximo() {
    if (_formKey.currentState!.validate()) {
      // aqui você pode guardar os dados em algum modelo/global se quiser
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CadastroEnderecoScreen(),
        ),
      );
    }
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
                      // avatar
                      Center(
                        child: Stack(
                          children: [
                            const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 50),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Olá, Motorista !',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Criar conta',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
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
                        controller: _cpfCnpjController,
                      ),
                      _CampoTexto(
                        label: 'Data de Nascimento: *',
                        controller: _dataNascController,
                        keyboardType: TextInputType.datetime,
                      ),
                      _CampoTexto(
                        label: 'Telefone: *',
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _CampoTexto(
                        label: 'Senha: *',
                        controller: _senhaController,
                        obscureText: true,
                        suffixIcon: const Icon(Icons.visibility),
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
                        child: _BotaoSetaGrande(onTap: _proximo),
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
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              Text(
                'CARGAS',
                style: TextStyle(color: kPrimaryColor),
              ),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.menu, size: 28),
            ],
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
          CircleAvatar(
            radius: 6,
            backgroundColor: kPrimaryColor,
          ),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 40, color: kPrimaryColor),
          SizedBox(width: 4),
          Icon(Icons.play_arrow, size: 50, color: Color(0xFFFFC89C)),
        ],
      ),
    );
  }
}
