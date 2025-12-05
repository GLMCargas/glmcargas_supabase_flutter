import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  File? _imagemLocal;
  Uint8List? _imagemBytesWeb;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarDocumento() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

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
        const SnackBar(content: Text("Envie a imagem da CNH antes de continuar.")),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: usuário não autenticado.")),
        );
        return;
      }

      final path = "documentos_cnh/${user.id}.jpg";

      if (kIsWeb) {
        await supabase.storage.from("cnh_motoristas").uploadBinary(
          path,
          _imagemBytesWeb!,
          fileOptions: const FileOptions(
            contentType: "image/jpeg",
            upsert: true,
          ),
        );
      } else {
        final bytes = await _imagemLocal!.readAsBytes();
        await supabase.storage.from("cnh_motoristas").uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: "image/jpeg",
            upsert: true,
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentosSelfieScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar documento: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildPreview() {
    if (kIsWeb && _imagemBytesWeb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_imagemBytesWeb!, height: 200, fit: BoxFit.cover),
      );
    }

    if (!kIsWeb && _imagemLocal != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_imagemLocal!, height: 200, fit: BoxFit.cover),
      );
    }

    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: const Text(
        "Nenhuma imagem selecionada",
        style: TextStyle(color: Colors.orange),
      ),
    );
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
              // TOPO FIXO
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
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

              // ÁREA ROLÁVEL
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "Documentos",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          "Envie uma foto da sua CNH",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Siga as instruções",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text("• Documento fora do plástico e aberto"),
                      const Text("• Todos os campos legíveis"),

                      const SizedBox(height: 20),

                      _buildPreview(),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _selecionarDocumento,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: const Text(
                            "Selecionar arquivo",
                            style: TextStyle(color: Colors.orange, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadDocumento,
                          style: ElevatedButton.styleFrom(
                            enabledMouseCursor: SystemMouseCursors.click,
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Enviar documento",
                                  style: TextStyle(fontSize: 18),
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
