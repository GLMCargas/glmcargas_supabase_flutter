import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'documentos_selfie.dart';

class DocumentosCnhScreen extends StatefulWidget {
  const DocumentosCnhScreen({Key? key}) : super(key: key);

  @override
  State<DocumentosCnhScreen> createState() => _DocumentosCnhScreenState();
}

class _DocumentosCnhScreenState extends State<DocumentosCnhScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _arquivoSelecionado;
  bool _isUploading = false;

  Future<void> _selecionarDocumentoEEnviar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery, // se quiser depois pode trocar por camera
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _arquivoSelecionado = File(picked.path);
    });

    await _uploadDocumento();
  }

  Future<void> _uploadDocumento() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: usuário não autenticado.")),
      );
      return;
    }

    if (_arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um arquivo primeiro.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final bytes = await _arquivoSelecionado!.readAsBytes();
      final filePath = "cnh_motoristas/${user.id}.jpg";

      await supabase.storage.from("cnh_motoristas").uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: "image/jpeg",
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from("cnh_motoristas")
          .getPublicUrl(filePath);

      print("📄 CNH enviada. URL pública: $url");
      // Se tiver coluna no banco para guardar a URL, você pode fazer um update aqui.

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Documento enviado com sucesso!"),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosSelfieScreen()),
      );
    } catch (e, stack) {
      print("❌ ERRO AO ENVIAR DOCUMENTO DE CNH:");
      print(e);
      print(stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar documento: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
              // TOPO
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Documentos',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Envie uma foto da sua CNH atual',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Siga as instruções de envio:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('• Documento fora do plástico e aberto'),
                      const SizedBox(height: 4),
                      const Text('• Todos os campos legíveis'),
                      const SizedBox(height: 4),
                      const Text('• CNH dentro da validade'),

                      const SizedBox(height: 24),

                      if (_arquivoSelecionado != null)
                        Center(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _arquivoSelecionado!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Pré-visualização do documento selecionado",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isUploading ? null : _selecionarDocumentoEEnviar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Enviar documento',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
