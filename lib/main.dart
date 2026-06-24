import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'services/foreground.dart';
import 'services/session_store.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

const Color kBg = Color(0xFF0B1220);
const Color kCard = Color(0xFF111A2E);
const Color kAccent = Color(0xFF4F7DF0);
const Color kText = Color(0xFFE8ECF4);
const Color kMuted = Color(0xFF9AA7BE);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Canal de comunicacao com o isolate do servico (botoes da notificacao).
  FlutterForegroundTask.initCommunicationPort();
  await initializeDateFormatting('pt_BR', null);
  await ForegroundController.init();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseKey,
  );
  // Espelha o token de login no disco pra o servico em primeiro plano usar.
  await _syncSession(Supabase.instance.client.auth.currentSession);
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    _syncSession(data.session);
  });
  runApp(const BabyApp());
}

Future<void> _syncSession(Session? s) async {
  if (s == null) {
    await SessionStore.clear();
  } else {
    await SessionStore.saveTokens(
      accessToken: s.accessToken,
      refreshToken: s.refreshToken ?? '',
      userId: s.user.id,
    );
  }
}

class BabyApp extends StatelessWidget {
  const BabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Diário do Bebê',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: base.colorScheme.copyWith(
          surface: kBg,
          primary: kAccent,
          secondary: kAccent,
        ),
        cardColor: kCard,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => _session = data.session);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _session == null ? const AuthScreen() : const HomeScreen();
  }
}
