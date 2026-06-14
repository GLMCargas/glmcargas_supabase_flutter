import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseReady = false;

Future<void> initializeSupabaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (_supabaseReady) return;

  try {
    Supabase.instance.client;
    _supabaseReady = true;
    return;
  } catch (_) {
    // Supabase is initialized lazily here because several screens read
    // Supabase.instance.client during initState.
  }

  SharedPreferences.setMockInitialValues({});

  await Supabase.initialize(
    url: 'https://test.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.test',
    debug: false,
  );

  _supabaseReady = true;
}

Future<void> pumpTestPage(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: child,
      routes: {
        '/login': (_) => const Scaffold(body: Text('login route')),
        '/home': (_) => const Scaffold(body: Text('home route')),
        '/chats': (_) => const Scaffold(body: Text('chats route')),
        '/chat': (_) => const Scaffold(body: Text('chat route')),
        '/perfilMotorista': (_) => const Scaffold(body: Text('profile route')),
      },
    ),
  );
  await tester.pump();
}

Future<void> enterTextFormField(
  WidgetTester tester,
  int index,
  String value,
) async {
  final field = find.byType(TextFormField).at(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}
