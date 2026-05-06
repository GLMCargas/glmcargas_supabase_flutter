import 'dart:io';

import 'package:app/cadastro/cadastro_endereco.dart';
import 'package:app/services/app_error_messages.dart';
import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    this.recoveryMode = false,
  });

  final bool recoveryMode;

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
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool usandoCnpj = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  File? _fotoSelecionada;
  Uint8List? _fotoSelecionadaWeb;
  String? _generoSelecionado;

  final ImagePicker _picker = ImagePicker();

  static const _duplicatePrefix = '__duplicate__';

  bool get _isRecoveryUi => widget.recoveryMode;

  @override
  void initState() {
    super.initState();

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.email != null) {
      _emailController.text = currentUser!.email!;
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
    final supabase = Supabase.instance.client;

    if (_fotoSelecionada == null && _fotoSelecionadaWeb == null) {
      return null;
    }

    final filePath = 'fotos_motoristas/$userId.jpg';
    final fileBytes = kIsWeb
        ? _fotoSelecionadaWeb!
        : await _fotoSelecionada!.readAsBytes();

    await supabase.storage
        .from('fotos_motoristas')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return supabase.storage.from('fotos_motoristas').getPublicUrl(filePath);
  }

  Future<String?> _validarDuplicidadesCadastro({String? ignoreUserId}) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final email = (ignoreUserId != null && currentUser?.email != null)
        ? currentUser!.email!.trim()
        : _emailController.text.trim();
    final cpfCnpj = _cpfController.text.trim();
    final telefone = _telefoneController.text.trim();

    var emailQuery = supabase
        .from('Usuario_Caminhoneiro')
        .select('id')
        .eq('email', email);

    if (ignoreUserId != null) {
      emailQuery = emailQuery.neq('id', ignoreUserId);
    }

    final emailExistente = await emailQuery.maybeSingle();

    if (emailExistente != null) {
      return 'Ja existe uma conta cadastrada com este e-mail.';
    }

    var cpfQuery = supabase
        .from('Usuario_Caminhoneiro')
        .select('id')
        .eq('cpf_cnpj', cpfCnpj);

    if (ignoreUserId != null) {
      cpfQuery = cpfQuery.neq('id', ignoreUserId);
    }

    final cpfExistente = await cpfQuery.maybeSingle();

    if (cpfExistente != null) {
      return 'Ja existe uma conta cadastrada com este CPF/CNPJ.';
    }

    var telefoneQuery = supabase
        .from('Usuario_Caminhoneiro')
        .select('id')
        .eq('telefone', telefone);

    if (ignoreUserId != null) {
      telefoneQuery = telefoneQuery.neq('id', ignoreUserId);
    }

    final telefoneExistente = await telefoneQuery.maybeSingle();

    if (telefoneExistente != null) {
      return 'Ja existe uma conta cadastrada com este telefone.';
    }

    return null;
  }

  Future<bool> _isRecoveringIncompleteProfile() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return false;
    }

    final existingProfile = await supabase
        .from('Usuario_Caminhoneiro')
        .select('id')
        .eq('id', currentUser.id)
        .maybeSingle();

    return existingProfile == null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_generoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um genero.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final isRecoveryFlow = await _isRecoveringIncompleteProfile();
      final currentUser = supabase.auth.currentUser;
      final effectiveUserId = isRecoveryFlow ? currentUser?.id : null;
      final effectiveEmail =
          (isRecoveryFlow && currentUser?.email != null)
          ? currentUser!.email!.trim()
          : _emailController.text.trim();

      final erroDuplicidade = await _validarDuplicidadesCadastro(
        ignoreUserId: effectiveUserId,
      );

      if (erroDuplicidade != null) {
        throw StateError('$_duplicatePrefix$erroDuplicidade');
      }

      final partes = _nascimentoController.text.split('/');
      final dataFormatada = '${partes[2]}-${partes[1]}-${partes[0]}';
      late final String userId;

      if (isRecoveryFlow) {
        if (currentUser == null) {
          throw 'Sua sessao expirou. Entre novamente para concluir o cadastro.';
        }

        userId = currentUser.id;
      } else {
        final signUpResponse = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = signUpResponse.user;
        if (user == null) {
          throw 'Erro ao criar usuario no AUTH.';
        }

        userId = user.id;

        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      final fotoUrl = await _uploadFoto(userId);

      await supabase.from('Usuario_Caminhoneiro').insert({
        'id': userId,
        'email': effectiveEmail,
        'nome': _nomeController.text.trim(),
        'sobrenome': _sobrenomeController.text.trim(),
        'cpf_cnpj': _cpfController.text.trim(),
        'data_nascimento': dataFormatada,
        'telefone': _telefoneController.text.trim(),
        'genero': _generoSelecionado,
        'foto_url': fotoUrl,
        'status': 'Pendente',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroEnderecoScreen()),
      );
    } on StateError catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst(
        'Bad state: $_duplicatePrefix',
        '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorMessages.signup(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ImageProvider<Object>? _fotoPerfil() {
    if (kIsWeb && _fotoSelecionadaWeb != null) {
      return MemoryImage(_fotoSelecionadaWeb!);
    }

    if (!kIsWeb && _fotoSelecionada != null) {
      return FileImage(_fotoSelecionada!);
    }

    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfController.dispose();
    _nascimentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: _isRecoveryUi ? 'Concluir cadastro' : 'Criar conta',
      subtitle: _isRecoveryUi
          ? 'Complete seus dados para finalizar o cadastro da conta.'
          : 'Complete os dados para iniciar seu cadastro de motorista.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _selecionarFoto,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: GlmColors.accentSoft,
                        backgroundImage: _fotoPerfil(),
                        child:
                            (_fotoSelecionada == null &&
                                _fotoSelecionadaWeb == null)
                            ? const Icon(
                                Icons.add_a_photo_outlined,
                                size: 30,
                                color: GlmColors.accentStrong,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_isRecoveryUi)
                    TextButton(
                      onPressed: _selecionarFoto,
                      child: const Text('Adicionar foto'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildCampo(
              'Email',
              _emailController,
              type: TextInputType.emailAddress,
              enabled: !_isRecoveryUi,
            ),
            const SizedBox(height: 16),
            _buildCampo('Nome', _nomeController),
            const SizedBox(height: 16),
            _buildCampo('Sobrenome', _sobrenomeController),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: usandoCnpj ? [cnpjMask] : [cpfMask],
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo obrigatorio' : null,
              decoration: const InputDecoration(labelText: 'CPF/CNPJ *'),
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
              'Data de nascimento',
              _nascimentoController,
              mask: dataMask,
              type: TextInputType.datetime,
            ),
            const SizedBox(height: 16),
            _buildCampo(
              'Telefone',
              _telefoneController,
              mask: telefoneMask,
              type: TextInputType.phone,
            ),
            if (!_isRecoveryUi) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obrigatorio' : null,
                decoration: InputDecoration(
                  labelText: 'Senha *',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),
            const Text(
              'Com qual genero voce se identifica?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: GlmColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GlmInfoCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: RadioGroup<String>(
                groupValue: _generoSelecionado,
                onChanged: (value) {
                  setState(() => _generoSelecionado = value);
                },
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Feminino'),
                      value: 'Feminino',
                    ),
                    RadioListTile<String>(
                      title: Text('Masculino'),
                      value: 'Masculino',
                    ),
                    RadioListTile<String>(
                      title: Text('Prefiro nao informar'),
                      value: 'Nao Informar',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GlmPrimaryButton(
              label: _isRecoveryUi
                  ? 'Concluir dados do cadastro'
                  : 'Continuar cadastro',
              icon: Icons.arrow_forward_rounded,
              loading: _isLoading,
              onPressed: _signUp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(
    String label,
    TextEditingController controller, {
    TextInputFormatter? mask,
    TextInputType type = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: type,
      inputFormatters: mask != null ? [mask] : null,
      validator: (v) => v == null || v.isEmpty ? 'Campo obrigatorio' : null,
      decoration: InputDecoration(labelText: '$label *'),
    );
  }
}
