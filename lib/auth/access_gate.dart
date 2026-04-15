import 'package:app/auth/account_access.dart';
import 'package:app/cadastro/cadastro_endereco.dart';
import 'package:app/cadastro/cadastro_tipo_veiculo.dart';
import 'package:app/cadastro/documentos_cnh.dart';
import 'package:app/cadastro/documentos_selfie.dart';
import 'package:app/screen/cadastro.dart';
import 'package:app/screen/account_status_page.dart';
import 'package:app/screen/login.dart';
import 'package:flutter/material.dart';

class AccessGate extends StatelessWidget {
  const AccessGate({
    super.key,
    required this.approvedBuilder,
  });

  final Widget Function(AccountProfile profile) approvedBuilder;

  Widget _buildOnboarding(OnboardingStep? step) {
    switch (step) {
      case OnboardingStep.profile:
        return const SignupPage(recoveryMode: true);
      case OnboardingStep.address:
        return const CadastroEnderecoScreen();
      case OnboardingStep.vehicle:
        return const CadastroTipoVeiculoScreen();
      case OnboardingStep.cnh:
        return const DocumentosCnhScreen();
      case OnboardingStep.selfie:
        return const DocumentosSelfieScreen();
      case null:
        return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccountAccessResult>(
      future: const AccountAccessService().resolveCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const LoginPage();
        }

        final result = snapshot.data;
        switch (result?.state) {
          case AccountAccessState.onboarding:
            return _buildOnboarding(result?.onboardingStep);
          case AccountAccessState.approved:
            return approvedBuilder(result!.profile!);
          case AccountAccessState.restricted:
            return AccountStatusPage(profile: result!.profile!);
          case AccountAccessState.unauthenticated:
          default:
            return const LoginPage();
        }
      },
    );
  }
}
