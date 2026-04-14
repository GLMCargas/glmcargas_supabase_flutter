import 'dart:io';

import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cadastro_concluido.dart';

class DocumentosSelfieScreen extends StatefulWidget {
  const DocumentosSelfieScreen({super.key});

  @override
  State<DocumentosSelfieScreen> createState() => _DocumentosSelfieScreenState();
}

class _DocumentosSelfieScreenState extends State<DocumentosSelfieScreen> {
  File? _selfieFile;
  Uint8List? _selfieBytesWeb;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _tirarSelfie() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selfieBytesWeb = bytes;
        _selfieFile = null;
      });
    } else {
      setState(() {
        _selfieFile = File(image.path);
        _selfieBytesWeb = null;
      });
    }
  }

  Future<void> _enviarSelfie() async {
    if (_selfieFile == null && _selfieBytesWeb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tire a selfie antes de continuar.')),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: usuário não autenticado.')),
        );
        return;
      }

      final path = 'selfies/${user.id}.jpg';
      final bytes = kIsWeb
          ? _selfieBytesWeb!
          : await _selfieFile!.readAsBytes();

      await supabase.storage
          .from('selfies_motoristas')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      await supabase.from('Documentos_Motorista').insert({
        'motorista_id': user.id,
        'tipo': 'Selfie',
        'url': path,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroConcluidoScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar selfie: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _previewSelfie() {
    if (kIsWeb && _selfieBytesWeb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _selfieBytesWeb!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!kIsWeb && _selfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _selfieFile!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlmColors.border),
        color: const Color(0xFFFFFBF7),
      ),
      child: const Text(
        'Nenhuma selfie registrada',
        style: TextStyle(color: GlmColors.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Validação facial',
      subtitle: 'Tire uma selfie clara para validar sua identidade.',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlmInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dicas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GlmColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text('- Esteja em local iluminado'),
                Text('- Retire óculos, boné e máscara'),
                Text('- Centralize o rosto na imagem'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const GlmInfoCard(
            child: Text(
              'Se estiver no computador, o envio por arquivo pode ser a opção mais estável.',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _previewSelfie(),
          const SizedBox(height: 16),
          GlmOutlinedAction(
            label: 'Tirar ou enviar selfie',
            icon: Icons.camera_alt_outlined,
            onPressed: _tirarSelfie,
          ),
          const SizedBox(height: 24),
          GlmPrimaryButton(
            label: 'Enviar selfie',
            icon: Icons.check_circle_outline_rounded,
            loading: _isUploading,
            onPressed: _enviarSelfie,
          ),
        ],
      ),
    );
  }
}
