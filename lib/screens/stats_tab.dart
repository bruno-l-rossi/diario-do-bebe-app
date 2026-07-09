import 'package:flutter/material.dart';

import '../data/store.dart';
import '../models/baby_event.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';

/// Estatísticas: resumo em frases (sem precisar ler gráfico), padrão dos
/// últimos 7 dias numa linha do tempo, e cards por tipo com a tendência
/// contra o período anterior. As análises abrem depois de 1 semana de
/// registros, quando há dado suficiente pra ser consistente.
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  String _period = 'week'; // week | month | quarter | all

  static const _labels = {
    'week': 'Semana',
    'month': 'Mês',
    'quarter': 'Trimestre',
    'all': 'Tudo',
  };

  int? get _days => switch (_period) {
        'week' => 7,
        'month' => 30,
        'quarter' => 90,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final diasDeUso = s.events.map((e) => s.babyDayKey(e.ts)).toSet().length;

    if (s.events.length < 2) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: const [
          _Empty(
            emoji: '📊',
            text:
                'As estatísticas aparecem conforme você registra.\nAlguns dias de uso e os padrões aparecem aqui.',
          ),
        ],
      );
    }

    if (diasDeUso < 7) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [_earlyDays(diasDeUso)],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _periodSelector(),
        ..._cards(s),
      ],
    );
  }

  /// Primeira semana: em vez de gráfico raso, uma contagem de progresso.
  Widget _earlyDays(int dias) {
    final resta = 7 - dias;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('As análises estão amadurecendo',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'As estatísticas abrem com 1 semana de registros: com mais '
            'dias de dados, os padrões que aparecem aqui são de verdade, '
            'e não coincidência de um dia atípico.\n\n'
            'Você está no dia $dias de 7. '
            '${resta == 1 ? 'Falta só 1 dia!' : 'Faltam $resta dias.'}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.muted, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: dias / 7,
              minHeight: 8,
              backgroundColor: AppColors.line,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodSelector() {
    Widget seg(String id) {
      final active = _period == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _period = id),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _labels[id]!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppColors.onAccent : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
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
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(children: [
        seg('week'),
        seg('month'),
        seg('quarter'),
        seg('all'),
      ]),
    );
  }

  // ---- janela de datas ----
  ({String start, String end, List<String> keys}) _window(AppStore s) {
    final endKey = s.babyDayKey(DateTime.now());
    final days = _days;
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
      keys.add('${cur.year}-${_p(cur.month)}-${_p(cur.day)}');
      cur = DateTime(cur.year, cur.month, cur.day + 1);
      g++;
    }
    return (start: startKey, end: endKey, keys: keys);
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  List<BabyEvent> _inWindow(
      AppStore s, String start, String end) {
    return s.events.where((e) {
      final k = s.babyDayKey(e.ts);
      return k.compareTo(start) >= 0 && k.compareTo(end) <= 0;
    }).toList();
  }

  /// Eventos da janela anterior de mesmo tamanho (pra tendência).
  List<BabyEvent>? _prevEvents(AppStore s, String startKey) {
    final days = _days;
    if (days == null) return null;
    final start = s.keyToDate(startKey);
    final prevEnd = start.subtract(const Duration(days: 1));
    final prevStart = start.subtract(Duration(days: days));
    final a = '${prevStart.year}-${_p(prevStart.month)}-${_p(prevStart.day)}';
    final b = '${prevEnd.year}-${_p(prevEnd.month)}-${_p(prevEnd.day)}';
    final ev = _inWindow(s, a, b);
    return ev.isEmpty ? null : ev;
  }

  List<Widget> _cards(AppStore s) {
    final W = _window(s);
    final pev = _inWindow(s, W.start, W.end);
    final prev = _prevEvents(s, W.start);
    return [
      _statResumo(s, pev),
      _statTimeline(s),
      _statSono(s, pev, prev, W),
      _statDespertares(s, pev, prev, W),
      _statRefeicoes(s, pev, W),
      _statSonecas(s, pev, prev, W),
      _statMamadas(s, pev, prev, W),
    ].whereType<Widget>().toList();
  }

  // ---------- resumo inteligente ----------
  Widget? _statResumo(AppStore s, List<BabyEvent> pev) {
    final nome = s.babyName.isEmpty ? 'seu bebê' : s.babyName;
    final lines = <Widget>[];

    // Sono da última noite vs média do período.
    final noites =
        pev.where((e) => e.type == 'sono' && e.end != null).toList()
          ..sort((a, b) => a.ts.compareTo(b.ts));
    if (noites.length >= 2) {
      final last = noites.last;
      final resto = noites.sublist(0, noites.length - 1);
      final lastNet = s.sonoLiquido(last).net;
      final avg = resto.fold<int>(0, (a, e) => a + s.sonoLiquido(e).net) ~/
          resto.length;
      final diff = lastNet - avg;
      const tol = 20 * 60000; // 20 min é ruído, não tendência
      if (diff.abs() < tol) {
        lines.add(_insight(Icons.bed, AppColors.sono,
            'Essa noite: ${fmtDurMs(lastNet)} de sono líquido, dentro do normal de $nome.'));
      } else {
        final up = diff > 0;
        lines.add(_insight(
          Icons.bed,
          AppColors.sono,
          'Essa noite: ${fmtDurMs(lastNet)} de sono líquido, '
          '${fmtDurMs(diff.abs())} ${up ? 'a mais' : 'a menos'} que a média.',
          trend: up ? 1 : -1,
          good: up,
        ));
      }

      // Despertares na última noite vs média.
      final desp = pev.where((e) => e.type == 'despertar').toList();
      if (desp.isNotEmpty) {
        final byNight = <String, int>{};
        for (final e in desp) {
          final k = s.babyDayKey(e.ts);
          byNight[k] = (byNight[k] ?? 0) + 1;
        }
        final lastKey = s.babyDayKey(last.ts);
        final n = byNight[lastKey] ?? 0;
        final media = desp.length / byNight.length;
        final d = n - media;
        if (d.abs() >= 0.8) {
          final up = d > 0;
          lines.add(_insight(
            Icons.auto_awesome,
            AppColors.despertar,
            '$n despertar${n == 1 ? '' : 'es'} essa noite '
            '(a média é ${media.toStringAsFixed(1)} por noite).',
            trend: up ? 1 : -1,
            good: !up,
          ));
        }
      }
    }

    // Mamadas de hoje vs média por dia.
    final mam = pev.where((e) => e.type == 'mamada').toList();
    if (mam.isNotEmpty) {
      final byDay = <String, int>{};
      for (final e in mam) {
        final k = s.babyDayKey(e.ts);
        byDay[k] = (byDay[k] ?? 0) + 1;
      }
      final hoje = s.babyDayKey(DateTime.now());
      final n = byDay[hoje] ?? 0;
      final media = mam.length / byDay.length;
      lines.add(_insight(
        Icons.local_drink,
        AppColors.mamada,
        '$n mamada${n == 1 ? '' : 's'} hoje até agora '
        '(o ritmo de $nome é ${media.toStringAsFixed(1)} por dia).',
      ));
    }

    if (lines.isEmpty) return null;
    return _card('✨', 'Hoje vs o normal',
        'Como o dia está em relação à média do período', lines);
  }

  Widget _insight(IconData icon, Color color, String text,
      {int trend = 0, bool good = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.ink, fontSize: 13, height: 1.45)),
          ),
          if (trend != 0)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6),
              child: Icon(
                trend > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 15,
                color: good ? AppColors.qGood : AppColors.qOk,
              ),
            ),
        ],
      ),
    );
  }

  // ---------- linha do tempo dos últimos 7 dias ----------
  Widget _statTimeline(AppStore s) {
    final now = DateTime.now();
    const nDias = 7;
    final labels = <String>[];
    final rows = <List<TimelineSeg>>[];
    const wd = ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb'];

    for (var i = nDias - 1; i >= 0; i--) {
      final d0 = DateTime(now.year, now.month, now.day - i);
      final d1 = DateTime(d0.year, d0.month, d0.day + 1);
      labels.add(i == 0 ? 'hoje' : wd[d0.weekday % 7]);

      final segs = <TimelineSeg>[];
      for (final e in s.events) {
        final color = kTypeColor[e.type];
        if (color == null) continue;
        // Sessões viram bloco (aberta corre até agora); o resto vira traço.
        final fim = e.isSession ? (e.end ?? now) : e.ts;
        if (fim.isBefore(d0) || !e.ts.isBefore(d1)) continue;
        final a = e.ts.isBefore(d0) ? d0 : e.ts;
        final b = fim.isAfter(d1) ? d1 : fim;
        final f0 = a.difference(d0).inMinutes / 1440;
        final f1 = b.difference(d0).inMinutes / 1440;
        segs.add(TimelineSeg(f0, f1 > f0 ? f1 : f0 + 0.003, color));
      }
      rows.add(segs);
    }

    return _card('🕐', 'A semana num olhar',
        'Cada faixa é um dia: sonos em bloco, mamadas e refeições em traços', [
      DayTimeline(dayLabels: labels, rows: rows),
      const SizedBox(height: 10),
      Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _legend('Sono da noite', AppColors.sono),
          _legend('Soneca', AppColors.soneca),
          _legend('Mamada', AppColors.mamada),
          _legend('Refeição', AppColors.refeicao),
          _legend('Despertar', AppColors.despertar),
        ],
      ),
    ]);
  }

  Widget _legend(String t, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(t, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }

  // ---------- tendência vs período anterior ----------
  Widget? _trendChip({
    required double atual,
    required double? anterior,
    required String Function(double abs) fmt,
    required bool maisEhBom,
    double tolerancia = 0,
  }) {
    if (anterior == null) return null;
    final d = atual - anterior;
    if (d.abs() <= tolerancia) {
      return _Trend(
          icon: Icons.trending_flat,
          color: AppColors.muted,
          text: 'no mesmo ritmo do período anterior');
    }
    final up = d > 0;
    final good = up == maisEhBom;
    return _Trend(
      icon: up ? Icons.trending_up : Icons.trending_down,
      color: good ? AppColors.qGood : AppColors.qOk,
      text: '${fmt(d.abs())} ${up ? 'a mais' : 'a menos'} que o período anterior',
    );
  }

  // ---------- cards ----------
  Widget _statSono(AppStore s, List<BabyEvent> pev, List<BabyEvent>? prev,
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

    // tendência: sono líquido médio vs período anterior
    double? prevAvg;
    if (prev != null) {
      final pn = prev.where((e) => e.type == 'sono' && e.end != null).toList();
      if (pn.isNotEmpty) {
        prevAvg = pn.fold<int>(0, (a, e) => a + s.sonoLiquido(e).net) /
            pn.length;
      }
    }
    final chip = _trendChip(
      atual: avgNet.toDouble(),
      anterior: prevAvg,
      fmt: (abs) => fmtDurMs(abs.round()),
      maisEhBom: true,
      tolerancia: 600000, // 10 min é ruído, não tendência
    );

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
      if (chip != null) chip,
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
      List<BabyEvent>? prev,
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

    // tendência: despertares por noite vs período anterior
    double? prevMedia;
    if (prev != null) {
      final pd = prev.where((e) => e.type == 'despertar').toList();
      if (pd.isNotEmpty) {
        final pByNight = <String, int>{};
        for (final e in pd) {
          final k = s.babyDayKey(e.ts);
          pByNight[k] = (pByNight[k] ?? 0) + 1;
        }
        prevMedia = pd.length / pByNight.length;
      }
    }
    final chip = _trendChip(
      atual: media,
      anterior: prevMedia,
      fmt: (abs) => abs.toStringAsFixed(1),
      maisEhBom: false,
      tolerancia: 0.3,
    );

    return _card('🌙', 'Despertares noturnos',
        'Quantas vezes acorda, e quanto demora pra voltar?', [
      _Big(media.toStringAsFixed(1), 'despertares / noite'),
      if (chip != null) chip,
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

  Widget _statSonecas(AppStore s, List<BabyEvent> pev, List<BabyEvent>? prev,
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

    // tendência: total de soneca por dia vs período anterior
    double? prevTotalDia;
    if (prev != null) {
      final ps =
          prev.where((e) => e.type == 'soneca' && e.end != null).toList();
      if (ps.isNotEmpty) {
        final pByDay = <String, int>{};
        for (final e in ps) {
          final k = s.babyDayKey(e.ts);
          pByDay[k] = (pByDay[k] ?? 0) + e.duration!.inMilliseconds;
        }
        prevTotalDia =
            pByDay.values.fold<int>(0, (a, b) => a + b) / pByDay.length;
      }
    }
    final totalDia =
        byDay.values.fold<int>(0, (a, b) => a + b) / byDay.length;
    final chip = _trendChip(
      atual: totalDia,
      anterior: prevTotalDia,
      fmt: (abs) => fmtDurMs(abs.round()),
      maisEhBom: true,
      tolerancia: 600000, // 10 min é ruído, não tendência
    );

    return _card('😴', 'Sonecas do dia', 'Melhores horários e tempo médio de cochilo', [
      _Big(fmtDurMs(mediaMs), 'por soneca'),
      if (chip != null) chip,
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

  Widget? _statMamadas(AppStore s, List<BabyEvent> pev, List<BabyEvent>? prev,
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

    // tendência: mamadas por dia vs período anterior (informativo, sem juízo)
    double? prevMedia;
    if (prev != null) {
      final pm = prev.where((e) => e.type == 'mamada').toList();
      if (pm.isNotEmpty) {
        final pByDay = <String, int>{};
        for (final e in pm) {
          final k = s.babyDayKey(e.ts);
          pByDay[k] = (pByDay[k] ?? 0) + 1;
        }
        prevMedia = pm.length / pByDay.length;
      }
    }
    Widget? chip;
    if (prevMedia != null && (mediaDia - prevMedia).abs() > 0.5) {
      final up = mediaDia > prevMedia;
      chip = _Trend(
        icon: up ? Icons.trending_up : Icons.trending_down,
        color: AppColors.accentSoft,
        text:
            '${(mediaDia - prevMedia).abs().toStringAsFixed(1)} ${up ? 'a mais' : 'a menos'} por dia que o período anterior',
      );
    }

    final children = <Widget>[
      _Big(mediaDia.toStringAsFixed(1), 'mamadas / dia'),
      if (chip != null) chip,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji  $title',
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(question,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 14),
          ...body,
        ],
      ),
    );
  }
}

/// Chip de tendência: setinha + comparação com o período anterior.
class _Trend extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Trend({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
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
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            TextSpan(
                text: '  $label',
                style: TextStyle(
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
            style: TextStyle(
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
            style: TextStyle(
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
                style: TextStyle(color: AppColors.muted, fontSize: 14)),
          ],
        ),
      );
}
