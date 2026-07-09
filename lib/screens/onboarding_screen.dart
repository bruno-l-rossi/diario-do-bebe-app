import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../data/store.dart';
import '../theme.dart';

/// Tour do primeiro login: 4 telas curtas mostrando o essencial.
/// Aparece 1 vez por aparelho (flag no disco) e fica reacessível nas
/// configurações em "Ver as dicas de novo".
class OnboardingScreen extends StatefulWidget {
  /// `standalone: true` quando aberto pelas configurações (volta com pop).
  final bool standalone;
  const OnboardingScreen({super.key, this.standalone = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _step = 0;

  static final _pages = <_TipPage>[
    _TipPage(
      icon: Icons.touch_app,
      color: AppColors.accent,
      title: 'Tudo num toque',
      text: 'Soneca, mamada, refeição, despertar: toca no botão quando '
          'começa, toca de novo quando termina. Errou? O Desfazer aparece '
          'na hora, e dá pra corrigir tudo no Histórico depois. E a Nota '
          'do dia guarda as lembranças ("hoje ficou de pé sozinho!").',
    ),
    _TipPage(
      icon: Icons.lock_outline,
      color: AppColors.soneca,
      title: 'Registre sem desbloquear o celular',
      text: 'Ligue os botões fixos na tela de bloqueio (o interruptor no '
          'topo da home). Eles ficam na notificação e gravam direto, '
          'mesmo com o app fechado, no meio da madrugada.',
    ),
    _TipPage(
      icon: Icons.bedtime,
      color: AppColors.sono,
      title: 'A noite tem começo e fim',
      text: 'Quando o bebê dormir à noite, toque em "Sono noturno". '
          'De manhã, "Começar o dia". Acordou de madrugada? "Despertar". '
          'É assim que o app entende o dia do seu bebê.',
    ),
    _TipPage(
      icon: Icons.insights,
      color: AppColors.refeicao,
      title: 'Os padrões aparecem com o tempo',
      text: 'A aba Estatísticas mostra quanto dorme por noite, os horários '
          'que come melhor e a evolução semana a semana. Com 1 semana de '
          'registros, as análises ficam consistentes.',
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await Settings.setOnboarded();
    if (!mounted) return;
    if (widget.standalone) {
      Navigator.pop(context);
    } else {
      // Acorda o AuthGate (que escuta o store) pra trocar pra home.
      AppStore.I.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _done,
                child: Text('Pular',
                    style: TextStyle(color: AppColors.muted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _step = i),
                itemBuilder: (_, i) => _TipView(page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final on = i == _step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? AppColors.accent : AppColors.line,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: last
                      ? _done
                      : () => _page.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut),
                  child: Text(last ? 'Começar' : 'Próxima',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipPage {
  final IconData icon;
  final Color color;
  final String title, text;
  const _TipPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });
}

class _TipView extends StatelessWidget {
  final _TipPage page;
  const _TipView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: page.color, size: 40),
          ),
          const SizedBox(height: 26),
          Text(page.title,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(page.text,
              style: TextStyle(
                  color: AppColors.muted, fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }
}
