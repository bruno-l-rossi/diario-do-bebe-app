import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
                child: Row(
                  children: [
                    Text(s.dayLabel(list.first.ts),
                        style: const TextStyle(
                            color: AppColors.accentSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(
                        '${list.length} registro${list.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              ...list.map((e) => _EventRow(e: e)),
            ],
          );
        },
      ),
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
    final emoji = kTypeEmoji[e.type] ?? '•';
    final (t1, t2) = _texts(s);
    final timeR = e.isSession ? '' : fmtH(e.ts);

    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.qBad.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Apagar registro?'),
                content: Text('$t1 — $timeR'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.qBad),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Apagar')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => s.deleteEvent(e.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t1,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (t2.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(t2,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (timeR.isNotEmpty)
              Text(timeR,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()])),
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
                  style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
      );
}
