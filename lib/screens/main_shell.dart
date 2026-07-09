import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../services/foreground.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'today_tab.dart';
import 'history_tab.dart';
import 'notas_tab.dart';
import 'stats_tab.dart';
import 'refeicao_sheet.dart';
import 'settings_screen.dart';
import 'help_sheet.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AppStore.I.events.isEmpty) AppStore.I.load();
    // App aberto pelo botão Refeição da notificação: abre a ficha direto.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLaunchAction());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pode ter registro novo feito pela notificação enquanto o app dormia.
      AppStore.I.load();
      _checkLaunchAction();
    }
  }

  Future<void> _checkLaunchAction() async {
    final action = await ForegroundController.consumeLaunchAction();
    if (action == 'refeicao' && mounted) {
      final ok = await showRefeicaoSheet(context);
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Refeição registrada'),
              duration: Duration(seconds: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: AppStore.I,
          builder: (context, _) {
            return Column(
              children: [
                const _Header(),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: const [
                      TodayTab(),
                      HistoryTab(),
                      NotasTab(),
                      StatsTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bg2,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Hoje'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Histórico'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Notas'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Estatísticas'),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final baby = s.babyName;
    final mae = s.motherName;
    final idade = ageLabel(s.babyBirth);
    final quem = mae.isNotEmpty
        ? mae
        : (baby.isEmpty ? '' : 'você e $baby');
    final greet = quem.isEmpty
        ? saudacao(DateTime.now().hour)
        : '${saudacao(DateTime.now().hour)}, $quem';
    final title = baby.isEmpty
        ? 'Diário do Bebê'
        : (idade.isEmpty ? baby : '$baby · $idade');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Um véu de cor no topo: azul de noite, areia quente de dia.
          colors: [
            kIsDark ? const Color(0xFF16335A) : const Color(0xFFF1E7DA),
            AppColors.bg,
          ],
          stops: const [0, 0.9],
        ),
      ),
      child: Row(
        children: [
          _Avatar(name: baby, photo: s.profile?['baby_photo'] as String?),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greet,
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 12.5)),
                Text(title,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.muted),
            tooltip: 'Ajuda',
            onPressed: () => showHelpSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.muted),
            tooltip: 'Configurações',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photo;
  const _Avatar({required this.name, this.photo});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (photo != null && photo!.isNotEmpty) {
      try {
        final b64 = photo!.contains(',') ? photo!.split(',').last : photo!;
        inner = ClipOval(
          child: Image.memory(base64Decode(b64),
              width: 50, height: 50, fit: BoxFit.cover),
        );
      } catch (_) {
        inner = _initial();
      }
    } else {
      inner = _initial();
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card2,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }

  Widget _initial() => Text(
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '🍼',
        style: TextStyle(
            color: AppColors.accentSoft, fontSize: 22, fontWeight: FontWeight.w700),
      );
}
