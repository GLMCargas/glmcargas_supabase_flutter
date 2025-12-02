import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'documentos_selfie.dart';

class DocumentosCnhScreen extends StatelessWidget {
  const DocumentosCnhScreen({Key? key}) : super(key: key);

  void _proximo(BuildContext context) {
    // aqui você pode chamar a câmera antes de ir pra próxima tela
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentosSelfieScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                      child: Text('Envie uma foto da sua CNH atual'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Siga as instruções de envio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('✓ Documento fora do plástico e aberto'),
                    const SizedBox(height: 8),
                    const Text('✓ Todos os campos legíveis'),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC7B2D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _proximo(context),
                        child: const Text('Tirar a foto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
