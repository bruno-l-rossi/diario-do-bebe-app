import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../config.dart';
import '../services/foreground.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'refeicao_sheet.dart';

/// Home repaginada: resumo 2x2 com número grande + última mamada, sessões em
/// andamento com cronômetro, e o painel de registro em grid 2 colunas com
/// botões grandes (mesma ordem e ícones da notificação) + sono noturno.
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  bool _notifOn = false;
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _checkNotif();
    // atualiza os "há X min" das sessões em andamento
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _checkNotif() async {
    final on = await ForegroundController.isRunning();
    if (mounted) setState(() => _notifOn = on);
  }

  Future<void> _toggleNotif(bool v) async {
    if (v) {
      await ForegroundController.start();
    } else {
      await ForegroundController.stop();
    }
    await _checkNotif();
  }

  Future<void> _tap(EventType type) async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    try {
      if (type == EventType.refeicao) {
        final ok = await showRefeicaoSheet(context);
        if (ok == true) _snack('Refeição registrada');
      } else {
        final msg = await AppStore.I.toggle(type);
        _snack(msg, undo: true);
      }
    } catch (_) {
      _snack('Falhou. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m, {bool undo = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        duration: Duration(seconds: undo ? 4 : 1),
        action: undo
            ? SnackBarAction(
                label: 'Desfazer',
                textColor: AppColors.accentSoft,
                onPressed: () => AppStore.I.undoLastToggle(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    if (s.loading && s.events.isEmpty) return const _Skeleton();
    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _notifCard(),
          const SizedBox(height: 14),
          _Resumo(s: s),
          ..._ongoing(s),
          const _SectionTitle('Registrar'),
          Row(children: [
            Expanded(child: _tile(s, EventType.soneca)),
            const SizedBox(width: 10),
            Expanded(child: _tile(s, EventType.mamada)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _tile(s, EventType.refeicao)),
            const SizedBox(width: 10),
            Expanded(child: _tile(s, EventType.despertar)),
          ]),
          const SizedBox(height: 10),
          _sonoTile(s),
        ],
      ),
    );
  }

  // ---- notificação ----
  Widget _notifCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.accent,
        title: const Text('Botões fixos na tela de bloqueio',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'Soneca, Mamada, Refeição e Despertar num toque, com o app fechado.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        value: _notifOn,
        onChanged: _toggleNotif,
      ),
    );
  }

  // ---- sessões em andamento ----
  List<Widget> _ongoing(AppStore s) {
    final items = <Widget>[];
    void add(BabyEvent? e, String type, String label, String btn,
        List<Color> grad) {
      if (e == null) return;
      items.add(_OngoingCard(
        icon: kTypeIcon[type] ?? Icons.circle,
        title: '$label desde ${fmtH(e.ts)}',
        sub: 'há ${fmtDur(DateTime.now().difference(e.ts))}',
        button: btn,
        gradient: grad,
        onTap: _busy ? null : () => _tap(EventTypeX.fromId(type)!),
      ));
    }

    add(s.activeSono, 'sono', 'Sono da noite', 'Começar o dia',
        [const Color(0xFF3B3F9E), const Color(0xFF272A73)]);
    add(s.activeDespertar, 'despertar', 'Acordado', 'Voltou a dormir',
        [const Color(0xFF7B4F9E), const Color(0xFF5A3475)]);
    add(s.activeSoneca, 'soneca', 'Soneca', 'Acordou',
        [const Color(0xFF2F6DC0), const Color(0xFF1C4F9E)]);
    add(s.activeMamada, 'mamada', 'Mamando', 'Terminou',
        [const Color(0xFFB9742F), const Color(0xFF8A531D)]);

    if (items.isEmpty) return [const SizedBox(height: 4)];
    return [
      const _SectionTitle('Em andamento'),
      ...items,
      const SizedBox(height: 4),
    ];
  }

  // ---- grid de registro ----
  Widget _tile(AppStore s, EventType type) {
    final color = kTypeColor[type.id]!;
    final icon = kTypeIcon[type.id]!;
    BabyEvent? active;
    String title, sub;
    switch (type) {
      case EventType.soneca:
        active = s.activeSoneca;
        title = active != null ? 'Acordou' : 'Soneca';
        sub = active != null
            ? 'dormindo desde ${fmtH(active.ts)}'
            : 'cochilo de dia';
        break;
      case EventType.mamada:
        active = s.activeMamada;
        title = active != null ? 'Terminou' : 'Mamada';
        sub = active != null
            ? 'mamando desde ${fmtH(active.ts)}'
            : 'começar a mamar';
        break;
      case EventType.despertar:
        active = s.activeDespertar;
        title = active != null ? 'Dormiu' : 'Despertar';
        sub = active != null
            ? 'acordado desde ${fmtH(active.ts)}'
            : 'acordou de noite';
        break;
      case EventType.refeicao:
        title = 'Refeição';
        sub = 'quanto comeu, quem serviu';
        break;
      case EventType.sono:
        throw StateError('sono usa _sonoTile');
    }
    return _BigTile(
      icon: icon,
      color: color,
      title: title,
      sub: sub,
      active: active != null,
      onTap: _busy ? null : () => _tap(type),
    );
  }

  Widget _sonoTile(AppStore s) {
    final a = s.activeSono;
    final color = kTypeColor['sono']!;
    return _Press(
      onTap: _busy ? null : () => _tap(EventType.sono),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: _tileDeco(color, a != null),
        child: Row(
          children: [
            _IconBubble(icon: kTypeIcon['sono']!, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a != null ? 'Começar o dia' : 'Sono noturno',
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                      a != null
                          ? 'dormindo desde ${fmtH(a.ts)}'
                          : 'a dormida da noite',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(a != null ? Icons.stop_circle : Icons.chevron_right,
                color: color.withValues(alpha: a != null ? 1 : 0.7), size: 22),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _tileDeco(Color color, bool active) => BoxDecoration(
      color: color.withValues(alpha: active ? 0.18 : 0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withValues(alpha: active ? 0.95 : 0.4),
        width: active ? 1.8 : 1.2,
      ),
    );

// ---- resumo do dia ----
class _Resumo extends StatelessWidget {
  final AppStore s;
  const _Resumo({required this.s});

  @override
  Widget build(BuildContext context) {
    final today = s.babyDayKey(DateTime.now());
    final ev = s.events.where((e) => s.babyDayKey(e.ts) == today).toList();
    final sonecas =
        ev.where((e) => e.type == 'soneca' && e.end != null).toList();
    final sonoMs =
        sonecas.fold<int>(0, (a, e) => a + e.duration!.inMilliseconds);
    final mamadas = ev.where((e) => e.type == 'mamada').toList();
    final despertares = ev.where((e) => e.type == 'despertar').length;

    // Última mamada do dia (a informação que mais decide o próximo passo).
    final ultimas = [...mamadas]..sort((a, b) => b.ts.compareTo(a.ts));
    final ultima = ultimas.isEmpty ? null : ultimas.first;
    final ultimaTxt = ultima == null
        ? 'sem mamada hoje ainda'
        : 'última mamada às ${fmtH(ultima.ts)} · há ${fmtDur(DateTime.now().difference(ultima.end ?? ultima.ts))}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(children: [
            _Stat(n: '${sonecas.length}', label: 'sonecas'),
            _Stat(
                n: sonoMs > 0 ? fmtDurMs(sonoMs) : '0',
                label: 'soneca no dia'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _Stat(n: '${mamadas.length}', label: 'mamadas'),
            _Stat(n: '$despertares', label: 'despertares'),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(kTypeIcon['mamada'],
                  size: 15, color: AppColors.mamada.withValues(alpha: 0.9)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(ultimaTxt,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String n, label;
  const _Stat({required this.n, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(n,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 1),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      );
}

// ---- widgets de apoio ----

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconBubble({required this.icon, required this.color, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}

/// Encolhe de leve enquanto o dedo está em cima (feedback de toque).
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Press({required this.child, required this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      );
}

class _BigTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool active;
  final VoidCallback? onTap;
  const _BigTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Press(
      onTap: onTap,
      child: Container(
        height: 116,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
        decoration: _tileDeco(color, active),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBubble(icon: icon, color: color),
                const Spacer(),
                if (active) Icon(Icons.stop_circle, color: color, size: 20),
              ],
            ),
            const Spacer(),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 1),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final IconData icon;
  final String title, sub, button;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const _OngoingCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.button,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text(sub,
                    style: const TextStyle(
                        color: Color(0xFFE6EEFB), fontSize: 12)),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C2A52),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: onTap,
            child: Text(button,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Placeholder de carregamento (primeira abertura, sem nada em memória).
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: [box(64), box(132), box(116), box(116), box(56)],
    );
  }
}
