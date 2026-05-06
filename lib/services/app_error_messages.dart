import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorMessages {
  const AppErrorMessages._();

  static String _normalized(Object? value) {
    return (value?.toString() ?? '').toLowerCase();
  }

  static String authLogin(Object error) {
    if (error is AuthException) {
      final message = _normalized(error.message);

      if (message.contains('invalid login credentials') ||
          message.contains('email not confirmed') ||
          message.contains('invalid_credentials')) {
        return 'E-mail ou senha incorretos. Confira os dados e tente novamente.';
      }

      if (message.contains('user not found')) {
        return 'Não encontramos uma conta com este e-mail.';
      }

      if (message.contains('too many requests')) {
        return 'Você fez muitas tentativas de login. Aguarde um momento e tente novamente.';
      }

      return 'Não foi possível entrar na conta agora. Tente novamente em instantes.';
    }

    return 'Não foi possível entrar na conta agora. Tente novamente em instantes.';
  }

  static String signup(Object error) {
    if (error is AuthException) {
      final message = _normalized(error.message);

      if (message.contains('user already registered')) {
        return 'Já existe uma conta cadastrada com este e-mail.';
      }

      if (message.contains('password')) {
        return 'Não foi possível criar a conta com a senha informada. Verifique os dados e tente novamente.';
      }

      return 'Não foi possível concluir o cadastro agora. Tente novamente em instantes.';
    }

    if (error is PostgrestException) {
      final message = _normalized(error.message);
      final details = _normalized(error.details);
      final code = _normalized(error.code);

      if (code == '23505' ||
          message.contains('duplicate key') ||
          details.contains('already exists')) {
        if (_containsAny(message, details, const [
          'email',
          'usuario_caminhoneiro_email_key',
        ])) {
          return 'Já existe uma conta cadastrada com este e-mail.';
        }

        if (_containsAny(message, details, const [
          'telefone',
          'usuario_caminhoneiro_telefone_key',
        ])) {
          return 'Já existe uma conta cadastrada com este telefone.';
        }

        if (_containsAny(message, details, const [
          'cpf_cnpj',
          'cpf/cnpj',
          'usuario_caminhoneiro_cpf/cnpj_key',
        ])) {
          return 'Já existe uma conta cadastrada com este CPF/CNPJ.';
        }

        if (_containsAny(message, details, const [
          'placaveiculo',
          'veiculo_placaveiculo_key',
        ])) {
          return 'Já existe um veiculo cadastrado com esta placa.';
        }

        if (_containsAny(message, details, const [
          'rntrc_antt',
          'veiculo_rntrc',
        ])) {
          return 'Já existe um cadastro com este RNTRC.';
        }

        return 'Já existe um cadastro com um dos dados informados.';
      }

      return 'Não foi possível salvar seus dados agora. Tente novamente em instantes.';
    }

    if (error is StorageException) {
      return 'Não foi possível enviar a imagem agora. Tente novamente em instantes.';
    }

    return 'Não foi possível concluir o cadastro agora. Tente novamente em instantes.';
  }

  static bool _containsAny(String message, String details, List<String> terms) {
    for (final term in terms) {
      if (message.contains(term) || details.contains(term)) {
        return true;
      }
    }

    return false;
  }
}
