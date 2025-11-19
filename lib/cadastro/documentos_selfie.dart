import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';
import 'cadastro_concluido.dart';

class DocumentosSelfieScreen extends StatelessWidget {
  const DocumentosSelfieScreen({Key? key}) : super(key: key);

  void _proximo(BuildContext context) {
    // aqui também poderia abrir a câmera antes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CadastroConcluidoScreen(),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Documentos',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text('Tire uma foto sua'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Dicas para a selfie',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('✓ Esteja em um lugar iluminado'),
                    const SizedBox(height: 8),
                    const Text('✓ Retire óculos, boné e máscara'),
                    const SizedBox(height: 8),
                    const Text('✓ Centralize seu rosto na tela'),
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
                        child: const Text('Tirar a selfie'),
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
