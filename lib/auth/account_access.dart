import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountAccessState {
  unauthenticated,
  onboarding,
  approved,
  restricted,
}

enum OnboardingStep {
  profile,
  address,
  vehicle,
  cnh,
  selfie,
}

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.email,
    required this.nome,
    required this.status,
    required this.raw,
  });

  final String id;
  final String email;
  final String nome;
  final String status;
  final Map<String, dynamic> raw;

  bool get isApproved => isApprovedStatus(status);
  bool get isRestricted => !isApproved;

  static bool isApprovedStatus(String? status) {
    return _canonicalStatus(status) == 'Aprovado';
  }

  static bool isRestrictedStatus(String? status) {
    return !isApprovedStatus(status);
  }

  static String displayStatus(String? status) {
    return _canonicalStatus(status);
  }

  static String _canonicalStatus(String? status) {
    final value = (status ?? '').trim().toLowerCase();

    if (value.contains('aprov')) {
      return 'Aprovado';
    }

    if (value.contains('reprov')) {
      return 'Reprovado';
    }

    if (value.contains('process') ||
        value.startsWith('em an') ||
        value.contains('anal')) {
      return 'Em análise';
    }

    return 'Pendente';
  }

  factory AccountProfile.fromMap(Map<String, dynamic> map) {
    return AccountProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      nome: map['nome']?.toString() ?? 'Motorista',
      status: displayStatus(map['status']?.toString()),
      raw: map,
    );
  }
}

class AccountAccessResult {
  const AccountAccessResult({
    required this.state,
    this.profile,
    this.onboardingStep,
  });

  final AccountAccessState state;
  final AccountProfile? profile;
  final OnboardingStep? onboardingStep;
}

class AccountAccessService {
  const AccountAccessService();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<AccountAccessResult> resolveCurrentUser() async {
    final session = _supabase.auth.currentSession;
    final user = session?.user ?? _supabase.auth.currentUser;

    if (user == null) {
      return const AccountAccessResult(
        state: AccountAccessState.unauthenticated,
      );
    }

    final data = await _supabase
        .from('Usuario_Caminhoneiro')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return const AccountAccessResult(
        state: AccountAccessState.onboarding,
        onboardingStep: OnboardingStep.profile,
      );
    }

    final profile = AccountProfile.fromMap(data);

    final hasAddress = await _supabase
        .from('Endere\u00E7o')
        .select('id')
        .eq('Usuario_CaminhoneiroID', user.id)
        .maybeSingle();

    if (hasAddress == null) {
      return AccountAccessResult(
        state: AccountAccessState.onboarding,
        profile: profile,
        onboardingStep: OnboardingStep.address,
      );
    }

    final hasVehicle = await _supabase
        .from('Veiculo')
        .select('id')
        .eq('Usuario_CaminhoneiroID', user.id)
        .maybeSingle();

    if (hasVehicle == null) {
      return AccountAccessResult(
        state: AccountAccessState.onboarding,
        profile: profile,
        onboardingStep: OnboardingStep.vehicle,
      );
    }

    final docsResponse = await _supabase
        .from('Documentos_Motorista')
        .select('tipo')
        .eq('motorista_id', user.id);

    final tiposDocumentos = List<Map<String, dynamic>>.from(
      docsResponse,
    ).map((doc) => doc['tipo']?.toString() ?? '').toSet();

    if (!tiposDocumentos.contains('CNH')) {
      return AccountAccessResult(
        state: AccountAccessState.onboarding,
        profile: profile,
        onboardingStep: OnboardingStep.cnh,
      );
    }

    if (!tiposDocumentos.contains('Selfie')) {
      return AccountAccessResult(
        state: AccountAccessState.onboarding,
        profile: profile,
        onboardingStep: OnboardingStep.selfie,
      );
    }

    return AccountAccessResult(
      state: profile.isApproved
          ? AccountAccessState.approved
          : AccountAccessState.restricted,
      profile: profile,
    );
  }
}
