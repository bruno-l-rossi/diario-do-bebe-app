import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../main.dart' show kCard, kMuted, kText;
import '../services/events_repo.dart';
import 'home_screen.dart' show kTypeColor;

/// Historico simples: lista os registros do mais novo pro mais antigo,
/// agrupados pelo dia do ciclo do bebe (do acordar ao acordar; fallback 5h).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = EventsRepo.recent(limit: 300);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snap.data!;
          if (events.isEmpty) {
            return const Center(
              child: Text('Nada registrado ainda.',
                  style: TextStyle(color: kMuted)),
            );
          }
          final groups = _groupByBabyDay(events);
          final keys = groups.keys.toList();
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: keys.length,
            itemBuilder: (_, i) => _dayBlock(keys[i], groups[keys[i]]!),
          );
        },
      ),
    );
  }

  Widget _dayBlock(String day, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(day,
              style: const TextStyle(
                  color: kText, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        ...items.map(_row),
      ],
    );
  }

  Widget _row(Map<String, dynamic> e) {
    final type = e['type'] as String? ?? '';
    final color = kTypeColor[type] ?? kMuted;
    final ts = DateTime.tryParse(e['ts'] as String? ?? '')?.toLocal();
    final endTs = e['end_ts'] != null
        ? DateTime.tryParse(e['end_ts'] as String)?.toLocal()
        : null;
    final hhmm = ts != null ? DateFormat('HH:mm').format(ts) : '--:--';
    final label = EventTypeX.fromId(type)?.label ?? type;
    String trailing = '';
    if (endTs != null && ts != null) {
      final mins = endTs.difference(ts).inMinutes;
      trailing = mins >= 60 ? '${mins ~/ 60}h${mins % 60}m' : '${mins}m';
    } else if (type == 'refeicao') {
      const q = ['recusou', 'pouco', 'médio', 'bem'];
      final qi = e['quality'] as int?;
      trailing = qi != null && qi < q.length ? q[qi] : '';
    } else if (e['end_ts'] == null && type != 'refeicao') {
      trailing = 'em andamento';
    }
    return Card(
      color: kCard,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 6),
        title: Text(label, style: const TextStyle(color: kText)),
        subtitle: Text(hhmm, style: const TextStyle(color: kMuted)),
        trailing: Text(trailing, style: const TextStyle(color: kMuted)),
      ),
    );
  }

  /// Agrupa pelo dia do ciclo do bebe. Sem sono pra ancorar, corta as 5h
  /// (DAY_RESET_HOUR), igual o app web.
  Map<String, List<Map<String, dynamic>>> _groupByBabyDay(
      List<Map<String, dynamic>> events) {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final ts = DateTime.tryParse(e['ts'] as String? ?? '')?.toLocal();
      if (ts == null) continue;
      var day = DateTime(ts.year, ts.month, ts.day);
      if (ts.hour < Config.dayResetHour) {
        day = day.subtract(const Duration(days: 1));
      }
      final key = DateFormat("EEE, d 'de' MMM", 'pt_BR').format(day);
      out.putIfAbsent(key, () => []).add(e);
    }
    return out;
  }
}
