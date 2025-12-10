import 'package:app/perfil/perfil_motorista.dart';
import 'package:app/screen/cadastro.dart';
import 'package:app/screen/homePage.dart';
import 'package:app/screen/login.dart';
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
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastroMotorista': (_) => const SignupPage(),
        '/home': (context) => const HomeMotoristaScreen(),
        '/perfilMotorista': (context) => const PerfilMotoristaScreen(),
      },
      home: const LoginPage(),
    );
  }
}
