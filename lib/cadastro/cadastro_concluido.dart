import 'package:flutter/material.dart';
import 'cadastro_dados_pessoais.dart';

class CadastroConcluidoScreen extends StatelessWidget {
  const CadastroConcluidoScreen({Key? key}) : super(key: key);

  void _voltarLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
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
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 140,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cadastro completo!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estamos avaliando suas informações...\n'
                      'Agora é só aguardar até receber o e-mail\n'
                      'de confirmação da sua conta!',
                      textAlign: TextAlign.center,
                    ),
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
                        onPressed: () => _voltarLogin(context),
                        child: const Text('Tela inicial'),
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
