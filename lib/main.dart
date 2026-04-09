import 'package:app/perfil/perfil_motorista.dart';
import 'package:app/screen/cadastro.dart';
import 'package:app/screen/chat_page.dart';
import 'package:app/screen/chats_list_page.dart';
import 'package:app/screen/homePage.dart';
import 'package:app/screen/login.dart';
import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zabeesixaloyyhrsqqne.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphYmVlc2l4YWxveXlocnNxcW5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwODE5NzksImV4cCI6MjA3NjY1Nzk3OX0.SkdD21HGrUrK6DCmN3t-9jtRCt5gjRWr5Ysw_JIyznM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = Supabase.instance.client.auth.currentSession == null
        ? '/login'
        : '/home';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: GlmColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GlmColors.accent,
          primary: GlmColors.accent,
          secondary: GlmColors.accentStrong,
          surface: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFBF7),
          labelStyle: const TextStyle(color: GlmColors.textMuted),
          hintStyle: const TextStyle(color: GlmColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: GlmColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: GlmColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: GlmColors.accent, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlmColors.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: GlmColors.accentStrong,
            side: const BorderSide(color: GlmColors.border),
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? GlmColors.accent
                : GlmColors.textMuted,
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastroMotorista': (_) => const SignupPage(),
        '/home': (context) => const HomeMotoristaScreen(),
        '/perfilMotorista': (context) => const PerfilMotoristaScreen(),
        '/chats': (context) => const ChatsListPage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}
