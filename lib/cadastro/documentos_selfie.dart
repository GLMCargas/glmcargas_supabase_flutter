import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cadastro_concluido.dart';

class DocumentosSelfieScreen extends StatefulWidget {
  const DocumentosSelfieScreen({Key? key}) : super(key: key);

  @override
  State<DocumentosSelfieScreen> createState() => _DocumentosSelfieScreenState();
}

class _DocumentosSelfieScreenState extends State<DocumentosSelfieScreen> {
  File? _selfieFile;
  Uint8List? _selfieBytesWeb;

  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _tirarSelfie() async {
    final XFile? image = await _picker.pickImage(
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
        const SnackBar(content: Text("Tire a selfie antes de continuar")),
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

      final path = "selfies/${user.id}.jpg";

      if (kIsWeb) {
        await supabase.storage
            .from("selfies_motoristas")
            .uploadBinary(
              path,
              _selfieBytesWeb!,
              fileOptions: const FileOptions(
                contentType: "image/jpeg",
                upsert: true,
              ),
            );
      } else {
        final bytes = await _selfieFile!.readAsBytes();
        await supabase.storage
            .from("selfies_motoristas")
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                contentType: "image/jpeg",
                upsert: true,
              ),
            );
      }

      await supabase.from("Documentos_Motorista").insert({
        "motorista_id": user.id,
        "tipo": "Selfie",
        "url": path,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CadastroConcluidoScreen()),
      );
    } catch (e) {
      print("❌ Erro ao enviar selfie: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar selfie: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _previewSelfie() {
    if (kIsWeb && _selfieBytesWeb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_selfieBytesWeb!, height: 200),
      );
    }
    if (!kIsWeb && _selfieFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selfieFile!, height: 200),
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
      child: const Text("Nenhuma selfie tirada"),
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
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      style: TextStyle(color: Colors.orange, fontSize: 18),
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
                          "Tire uma selfie",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Dicas:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text("• Esteja em local iluminado"),
                      const Text("• Retire óculos, boné e máscara"),
                      const Text("• Centralize o rosto"),

                      const SizedBox(height: 20),
                      const Text("Se estiver no computador, apenas envio por arquivo é permitido.", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),),

                      _previewSelfie(),

                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _tirarSelfie,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Tirar ou enviar selfie",
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _enviarSelfie,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Enviar selfie",
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
