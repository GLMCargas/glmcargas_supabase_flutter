import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomePendingEmailService {
  const WelcomePendingEmailService();

  Future<void> send({
    required String email,
    required String nome,
    required String status,
  }) async {
    await Supabase.instance.client.functions.invoke(
      'send-driver-welcome',
      body: {
        'email': email,
        'nome': nome,
        'status': status,
      },
    );
  }
}
