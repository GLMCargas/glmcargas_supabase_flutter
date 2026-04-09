import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';

class CadastroConcluidoScreen extends StatelessWidget {
  const CadastroConcluidoScreen({super.key});

  void _voltarLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return GlmFormPage(
      title: 'Cadastro completo',
      subtitle: 'Seus dados foram enviados para analise.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlmInfoCard(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 120,
                ),
                SizedBox(height: 20),
                Text(
                  'Estamos avaliando suas informacoes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: GlmColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Agora e so aguardar o e-mail de confirmacao da sua conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: GlmColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlmPrimaryButton(
            label: 'Voltar para o login',
            icon: Icons.login_rounded,
            onPressed: () => _voltarLogin(context),
          ),
        ],
      ),
    );
  }
}
