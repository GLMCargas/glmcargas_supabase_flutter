import 'dart:io';

import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'documentos_selfie.dart';

class DocumentosCnhScreen extends StatefulWidget {
  const DocumentosCnhScreen({super.key});

  @override
  State<DocumentosCnhScreen> createState() => _DocumentosCnhScreenState();
}

class _DocumentosCnhScreenState extends State<DocumentosCnhScreen> {
  File? _imagemLocal;
  Uint8List? _imagemBytesWeb;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarDocumento() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      _imagemBytesWeb = await picked.readAsBytes();
    } else {
      _imagemLocal = File(picked.path);
    }

    setState(() {});
  }

  Future<void> _uploadDocumento() async {
    if (_imagemLocal == null && _imagemBytesWeb == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Envie a imagem da CNH antes de continuar.'),
        ),
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

      final path = 'cnh_motoristas/${user.id}.jpg';
      final bytes = kIsWeb
          ? _imagemBytesWeb!
          : await _imagemLocal!.readAsBytes();

      await supabase.storage
          .from('cnh_motoristas')
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
        'tipo': 'CNH',
        'url': path,
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosSelfieScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar documento: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildPreview() {
    if (kIsWeb && _imagemBytesWeb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _imagemBytesWeb!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!kIsWeb && _imagemLocal != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _imagemLocal!,
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
        'Nenhuma imagem selecionada',
        style: TextStyle(color: GlmColors.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Documentos',
      subtitle: 'Envie uma foto nítida da CNH para validação.',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlmInfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instruções',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: GlmColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text('- Documento fora do plástico e aberto'),
                Text('- Todos os campos legíveis'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildPreview(),
          const SizedBox(height: 16),
          GlmOutlinedAction(
            label: 'Selecionar arquivo',
            icon: Icons.upload_file_rounded,
            onPressed: _selecionarDocumento,
          ),
          const SizedBox(height: 24),
          GlmPrimaryButton(
            label: 'Enviar documento',
            icon: Icons.arrow_forward_rounded,
            loading: _isUploading,
            onPressed: _uploadDocumento,
          ),
        ],
      ),
    );
  }
}
