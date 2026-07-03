import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/baby_event.dart';
import '../services/events_repo.dart';
import '../services/foreground.dart';
import '../services/session_store.dart';

/// Cérebro do app: carrega todos os eventos e o perfil em memória e calcula os
/// derivados (dia do bebê, sessões abertas, sono líquido), igual o app web fazia
/// com a variável EV. Notifica as telas quando algo muda.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  final SupabaseClient _sb = Supabase.instance.client;

  List<BabyEvent> events = [];
  Map<String, dynamic>? profile;
  bool loading = true;

  String get babyName => (profile?['baby_name'] as String?) ?? '';
  String? get babyBirth => profile?['baby_birth'] as String?;
  String get motherName => (profile?['mother_name'] as String?) ?? '';
  String? get babyPhoto => profile?['baby_photo'] as String?;

  Future<void> load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows =
          await _sb.from('events').select().order('ts').limit(5000);
      events = (rows as List)
          .map((r) => BabyEvent.fromRow(r as Map<String, dynamic>))
          .toList();
      final p = await _sb.from('profiles').select().eq('user_id', uid).limit(1);
      profile = (p as List).isNotEmpty ? p.first as Map<String, dynamic> : null;
      if (babyName.isNotEmpty) await SessionStore.saveBabyName(babyName);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile({
    required String name,
    String? birth,
    String? mother,
    String? photo,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    await _sb.from('profiles').upsert({
      'user_id': uid,
      'baby_name': name,
      if (birth != null) 'baby_birth': birth,
      if (mother != null) 'mother_name': mother,
      if (photo != null) 'baby_photo': photo,
    });
    await SessionStore.saveBabyName(name);
    await load();
  }

  // ---- sessões abertas ----
  BabyEvent? _active(String type) {
    for (final e in events) {
      if (e.type == type && e.end == null) return e;
    }
    return null;
  }

  BabyEvent? get activeSoneca => _active('soneca');
  BabyEvent? get activeSono => _active('sono');
  BabyEvent? get activeDespertar => _active('despertar');
  BabyEvent? get activeMamada => _active('mamada');

  // ---- dia do bebê (do acordar ao acordar; fallback 5h) ----
  String _dayKey(DateTime d) =>
      '${d.year}-${_p(d.month)}-${_p(d.day)}';
  String _p(int n) => n.toString().padLeft(2, '0');

  /// Acordar da manhã num dia (fim de sono noturno antes do meio-dia).
  DateTime? _morningWake(String dk) {
    final cand = events
        .where((e) =>
            e.type == 'sono' &&
            e.end != null &&
            _dayKey(e.end!) == dk &&
            e.end!.hour < 12)
        .map((e) => e.end!)
        .toList()
      ..sort();
    return cand.isEmpty ? null : cand.first;
  }

  DateTime dayStart(String dk) {
    final w = _morningWake(dk);
    if (w != null) return w;
    final parts = dk.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2], Config.dayResetHour);
  }

  /// A que dia do bebê um instante pertence.
  String babyDayKey(DateTime ts) {
    var dk = _dayKey(ts);
    if (ts.isBefore(dayStart(dk))) {
      dk = _dayKey(ts.subtract(const Duration(days: 1)));
    }
    return dk;
  }

  DateTime keyToDate(String k) {
    final p = k.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  String dayLabel(DateTime ts) {
    final today = babyDayKey(DateTime.now());
    final yest = babyDayKey(DateTime.now().subtract(const Duration(days: 1)));
    final k = babyDayKey(ts);
    if (k == today) return 'Hoje';
    if (k == yest) return 'Ontem';
    return _longLabel(keyToDate(k));
  }

  static const _dias = [
    'domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'
  ];
  static const _meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  String _longLabel(DateTime dt) =>
      '${_dias[dt.weekday % 7]}, ${dt.day} ${_meses[dt.month - 1]}';

  // ---- sono líquido ----
  List<BabyEvent> despertaresNa(BabyEvent sono) {
    final fim = sono.end ?? DateTime.now();
    return events
        .where((e) =>
            e.type == 'despertar' &&
            e.end != null &&
            !e.ts.isBefore(sono.ts) &&
            !e.ts.isAfter(fim))
        .toList();
  }

  ({int gross, int awake, int net, int n}) sonoLiquido(BabyEvent sono) {
    final fim = sono.end ?? DateTime.now();
    final gross = fim.difference(sono.ts).inMilliseconds;
    final ds = despertaresNa(sono);
    final awake =
        ds.fold<int>(0, (s, d) => s + d.end!.difference(d.ts).inMilliseconds);
    return (
      gross: gross,
      awake: awake,
      net: (gross - awake).clamp(0, gross),
      n: ds.length,
    );
  }

  // ---- ações (escrevem pela REST, igual a notificação) ----

  /// Último toggle, guardado pro Desfazer do snackbar.
  ToggleInfo? _lastToggle;

  Future<String> toggle(EventType type) async {
    final r = await EventsRepo.toggleSession(type);
    _lastToggle = r;
    await load();
    ForegroundController.refresh();
    return r.msg;
  }

  /// Desfaz o último toggle: apaga a sessão recém-aberta ou reabre a
  /// recém-encerrada. Um nível só, suficiente pro toque errado.
  Future<void> undoLastToggle() async {
    final t = _lastToggle;
    if (t == null) return;
    _lastToggle = null;
    if (t.openedId != null) {
      await _sb.from('events').delete().eq('id', t.openedId!);
    } else if (t.closedId != null) {
      await _sb.from('events').update({'end_ts': null}).eq('id', t.closedId!);
    }
    await load();
    ForegroundController.refresh();
  }

  Future<void> addRefeicao({
    required int quality,
    required String servedBy,
    String? note,
  }) async {
    await EventsRepo.insertRefeicao(
        quality: quality, servedBy: servedBy, note: note);
    await load();
  }

  Future<void> deleteEvent(String id) async {
    await _sb.from('events').delete().eq('id', id);
    await load();
    ForegroundController.refresh();
  }

  Future<void> updateEventTime(String id, DateTime ts, DateTime? end) async {
    await _sb.from('events').update({
      'ts': ts.toUtc().toIso8601String(),
      if (end != null) 'end_ts': end.toUtc().toIso8601String(),
    }).eq('id', id);
    await load();
    ForegroundController.refresh();
  }
}
