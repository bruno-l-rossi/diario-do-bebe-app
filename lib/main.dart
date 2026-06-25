import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/store.dart';
import 'data/settings.dart';
import 'theme.dart';
import 'services/foreground.dart';
import 'services/session_store.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await initializeDateFormatting('pt_BR', null);
  await Settings.load();
  await ForegroundController.init();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseKey,
  );
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
    return MaterialApp(
      title: 'Diário do Bebê',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
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
    if (_session != null) AppStore.I.load();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() => _session = data.session);
      if (data.session != null) AppStore.I.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _session == null ? const AuthScreen() : const MainShell();
  }
}
