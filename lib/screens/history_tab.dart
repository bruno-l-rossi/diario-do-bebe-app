import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'event_edit_sheet.dart';
import 'nota_sheet.dart';

/// Histórico: um card por dia, com os registros em linhas separadas por
/// divisória (em vez de um monte de cartão solto). Tocar numa linha abre
/// as ações na cara: editar ou apagar. Nada escondido em gesto.
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    if (s.events.isEmpty) {
      return const _Empty(
        emoji: '📋',
        text: 'Nada registrado ainda.\nToque em Registrar pra começar o diário.',
      );
    }
    final sorted = [...s.events]..sort((a, b) => b.ts.compareTo(a.ts));
    final groups = <String, List<BabyEvent>>{};
    for (final e in sorted) {
      groups.putIfAbsent(s.babyDayKey(e.ts), () => []).add(e);
    }
    final keys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: keys.length,
        itemBuilder: (_, i) {
          final list = groups[keys[i]]!;
          return _DayCard(list: list);
        },
      ),
    );
  }
}

/// O dia inteiro num card só: cabeçalho com resumo + linhas com divisória.
class _DayCard extends StatelessWidget {
  final List<BabyEvent> list;
  const _DayCard({required this.list});

  String _resumo() {
    int c(String t) => list.where((e) => e.type == t).length;
    final parts = <String>[];
    void add(int n, String singular, [String? plural]) {
      if (n > 0) parts.add('$n ${n > 1 ? (plural ?? '${singular}s') : singular}');
    }

    add(c('soneca'), 'soneca');
    add(c('mamada'), 'mamada');
    add(c('refeicao'), 'refeição', 'refeições');
    add(c('despertar'), 'despertar', 'despertares');
    add(c('nota'), 'nota');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s.dayLabel(list.first.ts),
                  style: TextStyle(
                      color: AppColors.accentSoft,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_resumo(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1, indent: 60, color: AppColors.line),
                _EventRow(e: list[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final BabyEvent e;
  const _EventRow({required this.e});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final dot = kDotColor[e.type] ?? AppColors.card2;
    final icon = kTypeIcon[e.type];
    final color = e.type == 'nota' ? kNotaColor : (kTypeColor[e.type] ?? AppColors.ink);
    final (t1, t2) = _texts(s);

    return InkWell(
      onTap: () => _showActions(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: icon != null
                  ? Icon(icon, size: 18, color: color)
                  : const Text('•'),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t1,
                      style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (t2.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(t2,
                        maxLines: e.type == 'nota' ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: e.type == 'nota'
                                ? AppColors.ink.withValues(alpha: 0.85)
                                : AppColors.muted,
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(fmtH(e.ts),
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 16, color: AppColors.line),
          ],
        ),
      ),
    );
  }

  /// Ações do registro, na cara: editar ou apagar. Sem gesto escondido.
  void _showActions(BuildContext context) {
    final s = AppStore.I;
    final (t1, _) = _texts(s);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Icon(kTypeIcon[e.type], size: 18,
                      color: e.type == 'nota'
                          ? kNotaColor
                          : (kTypeColor[e.type] ?? AppColors.ink)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('$t1 · ${fmtH(e.ts)}',
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            if (e.type == 'nota')
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.accent),
                title: const Text('Editar nota'),
                onTap: () {
                  Navigator.pop(ctx);
                  showNotaSheet(context, event: e);
                },
              )
            else
              ListTile(
                leading:
                    Icon(Icons.edit_calendar, color: AppColors.accent),
                title: const Text('Editar horário'),
                onTap: () {
                  Navigator.pop(ctx);
                  showEventEditSheet(context, e);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.qBad),
              title: Text('Apagar',
                  style: TextStyle(color: AppColors.qBad)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: const Text('Apagar registro?'),
                    content: Text('$t1 · ${fmtH(e.ts)}'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.qBad),
                          onPressed: () => Navigator.pop(dctx, true),
                          child: const Text('Apagar')),
                    ],
                  ),
                );
                if (ok == true) await s.deleteEvent(e.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  (String, String) _texts(AppStore s) {
    switch (e.type) {
      case 'soneca':
        return (
          'Soneca',
          e.end != null
              ? '${fmtH(e.ts)} → ${fmtH(e.end!)} · ${fmtDur(e.duration!)}'
              : 'em andamento…'
        );
      case 'sono':
        if (e.end == null) return ('Sono noturno', 'dormindo…');
        final L = s.sonoLiquido(e);
        final extra = L.n > 0
            ? ' líq. · ${L.n}× acordado (${fmtDurMs(L.awake)})'
            : '';
        return (
          'Sono noturno',
          '${fmtH(e.ts)} → ${fmtH(e.end!)} · ${fmtDurMs(L.net)}$extra'
        );
      case 'mamada':
        return (
          'Mamada',
          e.end != null
              ? '${fmtH(e.ts)} → ${fmtH(e.end!)} · ${fmtDur(e.duration!)}'
              : 'mamando…'
        );
      case 'despertar':
        return (
          'Despertar noturno',
          e.end != null
              ? '${fmtH(e.ts)} → ${fmtH(e.end!)} · ${fmtDur(e.duration!)} acordado'
              : 'acordado desde ${fmtH(e.ts)}…'
        );
      case 'refeicao':
        final q = kQuality[(e.quality ?? 0).clamp(0, 3)];
        final sv = kServers.where((x) => x.v == e.served).toList();
        final parts = [
          if (sv.isNotEmpty) '${sv.first.emoji} ${sv.first.nome}',
          if ((e.note ?? '').isNotEmpty) e.note!,
        ];
        return ('Refeição ${q.emoji} ${q.nome}', parts.join(' · '));
      case 'nota':
        return ('Nota do dia', e.note ?? '');
      default:
        return (e.type, '');
    }
  }
}

class _Empty extends StatelessWidget {
  final String emoji, text;
  const _Empty({required this.emoji, required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
      );
}
