import 'dart:async';
import 'package:flutter/material.dart';

import '../config.dart';
import '../data/store.dart';
import '../models/baby_event.dart';
import '../services/foreground.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'refeicao_sheet.dart';

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
    try {
      if (type == EventType.refeicao) {
        final ok = await showRefeicaoSheet(context);
        if (ok == true) _snack('Refeição registrada');
      } else {
        final msg = await AppStore.I.toggle(type);
        _snack(msg);
      }
    } catch (_) {
      _snack('Falhou. Tenta de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _notifCard(),
          const SizedBox(height: 16),
          _resumo(s),
          ..._ongoing(s),
          const SizedBox(height: 6),
          const _SectionTitle('Registrar'),
          _actSoneca(s),
          _actSono(s),
          _actDespertar(s),
          _actMamada(s),
          _actRefeicao(),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.accent,
        title: const Text('Botões fixos na tela de bloqueio',
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'Soneca, Mamada e Despertar num toque, mesmo com o app fechado.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        value: _notifOn,
        onChanged: _toggleNotif,
      ),
    );
  }

  // ---- resumo do dia ----
  Widget _resumo(AppStore s) {
    final today = s.babyDayKey(DateTime.now());
    final ev = s.events.where((e) => s.babyDayKey(e.ts) == today).toList();
    final sonecas =
        ev.where((e) => e.type == 'soneca' && e.end != null).toList();
    final sonoMs = sonecas.fold<int>(0, (a, e) => a + e.duration!.inMilliseconds);
    final mamadas = ev.where((e) => e.type == 'mamada').length;
    final desped = s.events
        .where((e) =>
            e.type == 'despertar' &&
            s.babyDayKey(e.ts) == s.babyDayKey(DateTime.now()))
        .length;
    final cards = [
      ('${sonecas.length}', 'sonecas'),
      (sonoMs > 0 ? fmtDurMs(sonoMs) : '0', 'soneca (dia)'),
      ('$mamadas', 'mamadas'),
      ('$desped', 'despertares'),
    ];
    return Row(
      children: [
        for (final c in cards)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  FittedBox(
                    child: Text(c.$1,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(c.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- sessões em andamento ----
  List<Widget> _ongoing(AppStore s) {
    final items = <Widget>[];
    void add(BabyEvent? e, String emoji, String label, String btn,
        List<Color> grad) {
      if (e == null) return;
      items.add(_OngoingCard(
        emoji: emoji,
        title: '$label desde ${fmtH(e.ts)}',
        sub: 'há ${fmtDur(DateTime.now().difference(e.ts))}',
        button: btn,
        gradient: grad,
        onTap: _busy ? null : () => _tap(_typeOf(e.type)),
      ));
    }

    add(s.activeSono, '🛌', 'Sono da noite', 'Começar o dia',
        [const Color(0xFF3B3F9E), const Color(0xFF272A73)]);
    add(s.activeDespertar, '🌙', 'Acordado', 'Voltou a dormir',
        [const Color(0xFF7B4F9E), const Color(0xFF5A3475)]);
    add(s.activeSoneca, '😴', 'Soneca', 'Acordou',
        [const Color(0xFF2F6DC0), const Color(0xFF1C4F9E)]);
    add(s.activeMamada, '🍼', 'Mamando', 'Terminou',
        [const Color(0xFFB9742F), const Color(0xFF8A531D)]);

    if (items.isEmpty) return [];
    return [
      const SizedBox(height: 18),
      const _SectionTitle('Em andamento'),
      ...items,
    ];
  }

  EventType _typeOf(String id) => EventTypeX.fromId(id)!;

  // ---- botões de ação ----
  Widget _actSoneca(AppStore s) {
    final a = s.activeSoneca;
    return _ActCard(
      emoji: '😴',
      title: a != null ? 'Acordou da soneca' : 'Iniciar soneca',
      desc: a != null
          ? 'Dormindo desde ${fmtH(a.ts)}'
          : 'Cochilo de dia. Marca quando pega no sono',
      color: AppColors.soneca,
      active: a != null,
      onTap: _busy ? null : () => _tap(EventType.soneca),
    );
  }

  Widget _actSono(AppStore s) {
    final a = s.activeSono;
    return _ActCard(
      emoji: '🛌',
      title: a != null ? 'Começar o dia' : 'Iniciar sono noturno',
      desc: a != null
          ? 'Dormindo desde ${fmtH(a.ts)}'
          : 'A dormida da noite. Encerra de manhã',
      color: AppColors.sono,
      active: a != null,
      onTap: _busy ? null : () => _tap(EventType.sono),
    );
  }

  Widget _actDespertar(AppStore s) {
    final a = s.activeDespertar;
    return _ActCard(
      emoji: '🌙',
      title: a != null ? 'Voltou a dormir' : 'Despertar',
      desc: a != null ? 'Acordado desde ${fmtH(a.ts)}' : 'Acordou de noite',
      color: AppColors.despertar,
      active: a != null,
      onTap: _busy ? null : () => _tap(EventType.despertar),
    );
  }

  Widget _actMamada(AppStore s) {
    final a = s.activeMamada;
    return _ActCard(
      emoji: '🍼',
      title: a != null ? 'Terminou de mamar' : 'Mamada',
      desc: a != null ? 'Mamando desde ${fmtH(a.ts)}' : 'Começar a mamar',
      color: AppColors.mamada,
      active: a != null,
      onTap: _busy ? null : () => _tap(EventType.mamada),
    );
  }

  Widget _actRefeicao() {
    return _ActCard(
      emoji: '🥣',
      title: 'Refeição',
      desc: 'Quanto comeu e quem serviu',
      color: AppColors.refeicao,
      active: false,
      onTap: _busy ? null : () => _tap(EventType.refeicao),
    );
  }
}

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

class _ActCard extends StatelessWidget {
  final String emoji, title, desc;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  const _ActCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? color : color.withValues(alpha: 0.45),
                width: active ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (active)
                  Icon(Icons.stop_circle, color: color, size: 22)
                else
                  Icon(Icons.chevron_right,
                      color: color.withValues(alpha: 0.7), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final String emoji, title, sub, button;
  final List<Color> gradient;
  final VoidCallback? onTap;
  const _OngoingCard({
    required this.emoji,
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
          Text(emoji, style: const TextStyle(fontSize: 24)),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
