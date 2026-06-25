import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String _period = 'week'; // week | month | all

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _periodSelector(),
        if (s.events.length < 2)
          const _Empty(
            emoji: '📊',
            text:
                'As estatísticas aparecem conforme você registra.\nAlguns dias de uso e os padrões aparecem aqui.',
          )
        else
          ..._cards(s),
      ],
    );
  }

  Widget _periodSelector() {
    Widget seg(String id, String label) {
      final active = _period == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _period = id),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? const Color(0xFF06121F) : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        seg('week', 'Semana'),
        seg('month', 'Mês'),
        seg('all', 'Tudo'),
      ]),
    );
  }

  // ---- janela de datas ----
  ({String start, String end, List<String> keys}) _window(AppStore s) {
    final endKey = s.babyDayKey(DateTime.now());
    final days = _period == 'week' ? 7 : (_period == 'month' ? 30 : null);
    String startKey;
    if (days != null) {
      final d = DateTime.now();
      final start = DateTime(d.year, d.month, d.day, 12)
          .subtract(Duration(days: days - 1));
      startKey = s.babyDayKey(start);
    } else {
      final all = s.events.map((e) => s.babyDayKey(e.ts)).toList()..sort();
      startKey = all.isNotEmpty ? all.first : endKey;
    }
    final keys = <String>[];
    var cur = s.keyToDate(startKey);
    final last = s.keyToDate(endKey);
    var g = 0;
    while (!cur.isAfter(last) && g < 400) {
      keys.add(
          '${cur.year}-${_p(cur.month)}-${_p(cur.day)}');
      cur = DateTime(cur.year, cur.month, cur.day + 1);
      g++;
    }
    return (start: startKey, end: endKey, keys: keys);
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  List<Widget> _cards(AppStore s) {
    final W = _window(s);
    final pev = s.events
        .where((e) {
          final k = s.babyDayKey(e.ts);
          return k.compareTo(W.start) >= 0 && k.compareTo(W.end) <= 0;
        })
        .toList();
    return [
      _statSono(s, pev, W),
      _statDespertares(s, pev, W),
      _statRefeicoes(s, pev, W),
      _statSonecas(s, pev, W),
      _statMamadas(s, pev, W),
    ].whereType<Widget>().toList();
  }

  // ---------- cards ----------
  Widget _statSono(AppStore s, List<BabyEvent> pev,
      ({String start, String end, List<String> keys}) W) {
    final noites = pev.where((e) => e.type == 'sono' && e.end != null).toList();
    if (noites.isEmpty) {
      return _card('🛌', 'Sono da noite', 'Quanto ele dorme à noite, de fato?', [
        const _Hint(
            'Sem sono noturno encerrado neste período. Use "Começar o dia" de manhã.'),
      ]);
    }
    final Ls = noites.map(s.sonoLiquido).toList();
    final avgNet = Ls.fold<int>(0, (a, L) => a + L.net) ~/ Ls.length;
    final avgAwake = Ls.fold<int>(0, (a, L) => a + L.awake) ~/ Ls.length;
    final bed = noites.map((e) {
      var m = e.ts.hour * 60 + e.ts.minute;
      if (e.ts.hour < 12) m += 1440;
      return m;
    }).toList();
    final wake = noites.map((e) => e.end!.hour * 60 + e.end!.minute).toList();
    final avgBed = bed.fold<int>(0, (a, b) => a + b) / bed.length;
    final avgWake = wake.fold<int>(0, (a, b) => a + b) / wake.length;

    final byDay = <String, List<int>>{};
    for (final e in noites) {
      byDay.putIfAbsent(s.babyDayKey(e.ts), () => []).add(s.sonoLiquido(e).net);
    }
    final vals = W.keys.map<double?>((k) {
      final l = byDay[k];
      if (l == null) return null;
      return (l.reduce((a, b) => a + b) / l.length) / 3600000;
    }).toList();

    return _card('🛌', 'Sono da noite', 'Quanto ele dorme à noite, de fato?', [
      _Big(fmtDurMs(avgNet), 'por noite (líquido)'),
      _Hint(
          'Já descontando os despertares (em média ${fmtDurMs(avgAwake)} acordado por noite). Base de ${noites.length} noite${noites.length > 1 ? 's' : ''}.'),
      const _Cap('Sono líquido por noite'),
      TrendLine(
          labels: W.keys.map((k) => shortDay(s.keyToDate(k))).toList(),
          values: vals,
          color: AppColors.sono,
          unit: 'h'),
      _Hint(
          'Costuma deitar por volta das ${fmtClock(avgBed)} e começar o dia às ${fmtClock(avgWake)}.'),
    ]);
  }

  Widget _statDespertares(AppStore s, List<BabyEvent> pev,
      ({String start, String end, List<String> keys}) W) {
    final desp = pev.where((e) => e.type == 'despertar').toList();
    if (desp.isEmpty) {
      return _card('🌙', 'Despertares noturnos',
          'Quantas vezes acorda, e quanto demora pra voltar?', [
        const _Hint('Sem despertares no período.'),
      ]);
    }
    final byNight = <String, int>{};
    for (final e in desp) {
      final k = s.babyDayKey(e.ts);
      byNight[k] = (byNight[k] ?? 0) + 1;
    }
    final total = desp.length;
    final nNoites = byNight.length;
    final media = total / nNoites;
    final closed = desp.where((e) => e.end != null).toList();
    final avgRet = closed.isEmpty
        ? 0
        : closed.fold<int>(0, (a, e) => a + e.duration!.inMilliseconds) ~/
            closed.length;
    final trend =
        W.keys.map<double?>((k) => byNight[k]?.toDouble()).toList();
    final byHour = <int, int>{};
    for (final e in desp) {
      byHour[e.ts.hour] = (byHour[e.ts.hour] ?? 0) + 1;
    }
    final horas = byHour.keys.toList()..sort();

    return _card('🌙', 'Despertares noturnos',
        'Quantas vezes acorda, e quanto demora pra voltar?', [
      _Big(media.toStringAsFixed(1), 'despertares / noite'),
      _Hint(
          'Base de $nNoites noite${nNoites > 1 ? 's' : ''} ($total no total).${closed.isNotEmpty ? ' Demora em média ${fmtDurMs(avgRet)} pra voltar a dormir.' : ''}'),
      const _Cap('Despertares por noite'),
      TrendLine(
          labels: W.keys.map((k) => shortDay(s.keyToDate(k))).toList(),
          values: trend,
          color: AppColors.despertar,
          unit: '×'),
      const _Cap('Horários que mais acorda'),
      Bars(
          labels: horas.map(hourLabel).toList(),
          values: horas.map((h) => byHour[h]!.toDouble()).toList(),
          color: AppColors.despertar,
          unit: '×'),
    ]);
  }

  Widget _statRefeicoes(AppStore s, List<BabyEvent> pev,
      ({String start, String end, List<String> keys}) W) {
    final ref = pev.where((e) => e.type == 'refeicao').toList();
    if (ref.isEmpty) {
      return _card('🥣', 'Aceitação das refeições', 'Em quais horários come melhor?', [
        const _Hint('Sem refeições no período.'),
      ]);
    }
    final byHour = <int, List<int>>{};
    for (final e in ref) {
      byHour.putIfAbsent(e.ts.hour, () => []).add(e.quality ?? 0);
    }
    final horas = byHour.keys.toList()..sort();
    int bestH = horas.first;
    double bestAvg = -1;
    final avgs = horas.map((h) {
      final arr = byHour[h]!;
      final a = arr.fold<int>(0, (x, y) => x + y) / arr.length;
      if (a > bestAvg) {
        bestAvg = a;
        bestH = h;
      }
      return a;
    }).toList();
    final dist = List<double>.generate(
        4, (v) => ref.where((e) => (e.quality ?? 0) == v).length.toDouble());
    final avgAll = ref.fold<int>(0, (a, e) => a + (e.quality ?? 0)) / ref.length;
    final qAll = kQuality[avgAll.round().clamp(0, 3)];
    final servCount = kServers
        .map((sv) => ref.where((e) => e.served == sv.v).length.toDouble())
        .toList();
    final hasServ = servCount.any((n) => n > 0);

    return _card('🥣', 'Aceitação das refeições', 'Em quais horários come melhor?', [
      _Hint(
          'No geral come ${qAll.emoji} ${qAll.nome.toLowerCase()} (${ref.length} refeições no período).'),
      const _Cap('Como come no geral'),
      Donut(
        labels: kQuality.map((q) => '${q.emoji} ${q.nome}').toList(),
        values: dist,
        colors: kQuality.map((q) => q.cor).toList(),
      ),
      const _Cap('Aceitação média por horário'),
      Bars(
        labels: horas.map(hourLabel).toList(),
        values: avgs,
        color: AppColors.refeicao,
        barColors: avgs
            .map((a) => kQuality[a.round().clamp(0, 3)].cor)
            .toList(),
      ),
      _Hint('Melhor horário: ${hourLabel(bestH)}.'),
      if (hasServ) const _Cap('Quem serviu'),
      if (hasServ)
        Donut(
          labels: kServers.map((sv) => '${sv.emoji} ${sv.nome}').toList(),
          values: servCount,
          colors: kServers.map((sv) => sv.cor).toList(),
        ),
    ]);
  }

  Widget _statSonecas(AppStore s, List<BabyEvent> pev,
      ({String start, String end, List<String> keys}) W) {
    final son = pev.where((e) => e.type == 'soneca' && e.end != null).toList();
    if (son.isEmpty) {
      return _card('😴', 'Sonecas do dia', 'Melhores horários e tempo médio de cochilo', [
        const _Hint('Sem sonecas encerradas no período.'),
      ]);
    }
    final mediaMs =
        son.fold<int>(0, (a, e) => a + e.duration!.inMilliseconds) ~/ son.length;
    final byDay = <String, int>{};
    for (final e in son) {
      final k = s.babyDayKey(e.ts);
      byDay[k] = (byDay[k] ?? 0) + e.duration!.inMilliseconds;
    }
    final byHour = <int, List<int>>{};
    for (final e in son) {
      byHour.putIfAbsent(e.ts.hour, () => []).add(e.duration!.inMilliseconds);
    }
    final horas = byHour.keys.toList()..sort();
    int bestH = horas.first;
    double bestAvg = 0;
    final avgs = horas.map((h) {
      final arr = byHour[h]!;
      final a = arr.fold<int>(0, (x, y) => x + y) / arr.length;
      if (a > bestAvg) {
        bestAvg = a;
        bestH = h;
      }
      return (a / 60000);
    }).toList();

    return _card('😴', 'Sonecas do dia', 'Melhores horários e tempo médio de cochilo', [
      _Big(fmtDurMs(mediaMs), 'por soneca'),
      _Hint('Média de ${son.length} soneca${son.length > 1 ? 's' : ''} de dia no período.'),
      const _Cap('Total de soneca por dia'),
      TrendLine(
          labels: W.keys.map((k) => shortDay(s.keyToDate(k))).toList(),
          values: W.keys
              .map<double?>((k) => byDay[k] != null ? byDay[k]! / 60000 : null)
              .toList(),
          color: AppColors.soneca,
          unit: 'm'),
      const _Cap('Duração média por hora de início'),
      Bars(
          labels: horas.map(hourLabel).toList(),
          values: avgs,
          color: AppColors.soneca,
          unit: 'm'),
      _Hint(
          'Soneca mais longa começa por volta das ${hourLabel(bestH)} (${fmtDurMs(bestAvg.round())} em média).'),
    ]);
  }

  Widget? _statMamadas(AppStore s, List<BabyEvent> pev,
      ({String start, String end, List<String> keys}) W) {
    final mam = pev.where((e) => e.type == 'mamada').toList();
    if (mam.isEmpty) return null;
    final byDay = <String, int>{};
    for (final e in mam) {
      final k = s.babyDayKey(e.ts);
      byDay[k] = (byDay[k] ?? 0) + 1;
    }
    final dias = byDay.length;
    final mediaDia = mam.length / dias;
    final closed = mam.where((e) => e.end != null).toList();

    final children = <Widget>[
      _Big(mediaDia.toStringAsFixed(1), 'mamadas / dia'),
      _Hint('Base de $dias dia${dias > 1 ? 's' : ''} (${mam.length} no total no período).'),
      const _Cap('Mamadas por dia'),
      TrendLine(
          labels: W.keys.map((k) => shortDay(s.keyToDate(k))).toList(),
          values: W.keys.map<double?>((k) => byDay[k]?.toDouble()).toList(),
          color: AppColors.mamada,
          unit: '×'),
    ];

    if (closed.isNotEmpty) {
      final avg =
          closed.fold<int>(0, (a, e) => a + e.duration!.inMilliseconds) ~/
              closed.length;
      final byHour = <int, List<int>>{};
      for (final e in closed) {
        byHour.putIfAbsent(e.ts.hour, () => []).add(e.duration!.inMilliseconds);
      }
      final horas = byHour.keys.toList()..sort();
      int bestH = horas.first;
      double bestAvg = 0;
      final avgs = horas.map((h) {
        final arr = byHour[h]!;
        final a = arr.fold<int>(0, (x, y) => x + y) / arr.length;
        if (a > bestAvg) {
          bestAvg = a;
          bestH = h;
        }
        return a / 60000;
      }).toList();
      children.addAll([
        const SizedBox(height: 4),
        _Big(fmtDurMs(avg), 'por mamada'),
        _Hint('Base de ${closed.length} mamada${closed.length > 1 ? 's' : ''} com início e fim.'),
        const _Cap('Duração média por hora'),
        Bars(
            labels: horas.map(hourLabel).toList(),
            values: avgs,
            color: AppColors.mamada,
            unit: 'm'),
        _Hint('Mama por mais tempo por volta das ${hourLabel(bestH)}.'),
      ]);
    } else {
      children.add(const _Hint(
          'Use o começar/terminar na mamada pra medir a duração e ver os melhores horários.'));
    }

    return _card('🍼', 'Mamadas', 'Quantas por dia, e qual a duração média?', children);
  }

  Widget _card(String emoji, String title, String question, List<Widget> body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji  $title',
              style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(question,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 14),
          ...body,
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final String num, label;
  const _Big(this.num, this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: num,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            TextSpan(
                text: '  $label',
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.muted, fontSize: 12.5, height: 1.5)),
      );
}

class _Cap extends StatelessWidget {
  final String text;
  const _Cap(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );
}

class _Empty extends StatelessWidget {
  final String emoji, text;
  const _Empty({required this.emoji, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          ],
        ),
      );
}
