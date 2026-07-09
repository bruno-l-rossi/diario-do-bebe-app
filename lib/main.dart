import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/store.dart';
import 'data/settings.dart';
import 'theme.dart';
import 'services/session_store.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Settings.load();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseKey,
  );
  await _syncSession(Supabase.instance.client.auth.currentSession);
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    _syncSession(data.session);
  });
  // Paleta inicial segue o modo do celular (claro de dia, escuro de noite).
  setPaletteFor(
      WidgetsBinding.instance.platformDispatcher.platformBrightness);
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

class BabyApp extends StatefulWidget {
  const BabyApp({super.key});

  @override
  State<BabyApp> createState() => _BabyAppState();
}

class _BabyAppState extends State<BabyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Celular mudou de claro/escuro: troca a paleta e remonta a árvore
    // (a key força o rebuild de tudo que lê AppColors).
    setState(() {
      setPaletteFor(
          WidgetsBinding.instance.platformDispatcher.platformBrightness);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diário do Bebê',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: KeyedSubtree(
        key: ValueKey(kIsDark),
        child: const AuthGate(),
      ),
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
    if (_session == null) return const AuthScreen();
    // Logado: decide entre boas-vindas (perfil vazio), tour (1ª vez no
    // aparelho) e a home. Escuta o store pra reagir quando o perfil chega.
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final s = AppStore.I;
        if (s.loading && s.profile == null) return const _Splash();
        if (s.babyName.isEmpty) return const WelcomeFlow();
        if (!onboarded) return const OnboardingScreen();
        return const MainShell();
      },
    );
  }
}

/// Tela de espera enquanto o perfil carrega (evita piscar a tela errada).
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👶', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
