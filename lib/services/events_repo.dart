import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'session_store.dart';

/// Resultado de um toggle: a frase de feedback e o que aconteceu, pra dar
/// pra desfazer (apagar o evento aberto ou reabrir o encerrado).
class ToggleInfo {
  final String msg;
  final String? openedId;
  final String? closedId;
  const ToggleInfo(this.msg, {this.openedId, this.closedId});
}

/// Grava e le eventos direto na REST do Supabase, usando o token guardado.
/// Mesma logica que o servico nativo da notificacao roda em Kotlin
/// (SupabaseApi.kt): a fonte da verdade e o Supabase, pra app e notificacao
/// nunca divergirem.
class EventsRepo {
  static const _msgOpen = {
    'soneca': 'Soneca iniciada',
    'mamada': 'Mamada iniciada',
    'despertar': 'Despertar registrado',
    'sono': 'Sono noturno iniciado',
  };
  static const _msgClose = {
    'soneca': 'Acordou da soneca',
    'mamada': 'Mamada encerrada',
    'despertar': 'Voltou a dormir',
    'sono': 'Sono encerrado. Bom dia!',
  };

  /// Toca um botao de sessao (soneca/mamada/despertar/sono): se nao ha sessao
  /// aberta no servidor, abre uma (ts=agora); se ha, encerra (end_ts=agora).
  static Future<ToggleInfo> toggleSession(EventType type) async {
    final open = await _openEvent(type);
    if (open == null) {
      final row = await _insert({
        'type': type.id,
        'ts': DateTime.now().toUtc().toIso8601String(),
      });
      return ToggleInfo(
        _msgOpen[type.id] ?? '${type.label} iniciada',
        openedId: row?['id'] as String?,
      );
    } else {
      final id = open['id'] as String;
      await _patch(id, {
        'end_ts': DateTime.now().toUtc().toIso8601String(),
      });
      return ToggleInfo(
        _msgClose[type.id] ?? '${type.label} encerrada',
        closedId: id,
      );
    }
  }

  /// Diz se ha sessao aberta de cada tipo (pro app mostrar "Encerrar").
  static Future<Map<String, bool>> openSessions() async {
    final res = await _send(
      'GET',
      '${Config.restEvents}?select=type&end_ts=is.null'
      '&type=in.(soneca,mamada,despertar,sono)',
    );
    final out = {'soneca': false, 'mamada': false, 'despertar': false, 'sono': false};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      for (final e in (jsonDecode(res.body) as List)) {
        final t = e['type'] as String?;
        if (t != null && out.containsKey(t)) out[t] = true;
      }
    }
    return out;
  }

  static Future<Map<String, dynamic>?> _openEvent(EventType type) async {
    final res = await _send(
      'GET',
      '${Config.restEvents}?select=id&type=eq.${type.id}'
      '&end_ts=is.null&order=ts.desc&limit=1',
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List;
      if (list.isNotEmpty) return list.first as Map<String, dynamic>;
    }
    return null;
  }

  /// Registra uma refeicao (evento unico com qualidade e quem serviu).
  static Future<void> insertRefeicao({
    required int quality, // 0 recusou, 1 pouco, 2 medio, 3 bem
    required String servedBy, // mae / pai / outro
    String? note,
    DateTime? at,
  }) async {
    await _insert({
      'type': 'refeicao',
      'ts': (at ?? DateTime.now()).toUtc().toIso8601String(),
      'quality': quality,
      'served_by': servedBy,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Le os ultimos eventos (pra historico e resumo). Ordenado do mais novo.
  static Future<List<Map<String, dynamic>>> recent({int limit = 200}) async {
    final res = await _send(
      'GET',
      '${Config.restEvents}?select=*&order=ts.desc&limit=$limit',
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ---- internos ----

  static Future<Map<String, dynamic>?> _insert(
      Map<String, dynamic> body) async {
    final res = await _send(
      'POST',
      Config.restEvents,
      body: jsonEncode(body),
      extraHeaders: {'Prefer': 'return=representation'},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body);
      if (list is List && list.isNotEmpty) {
        return list.first as Map<String, dynamic>;
      }
    }
    return null;
  }

  static Future<void> _patch(String id, Map<String, dynamic> body) async {
    await _send(
      'PATCH',
      '${Config.restEvents}?id=eq.$id',
      body: jsonEncode(body),
    );
  }

  /// Faz a chamada REST com o token atual. Se der 401, tenta um refresh do
  /// token (igual o PWA) e repete uma vez.
  static Future<http.Response> _send(
    String method,
    String url, {
    String? body,
    Map<String, String>? extraHeaders,
  }) async {
    var res = await _raw(method, url, body: body, extraHeaders: extraHeaders);
    if (res.statusCode == 401) {
      final ok = await _refresh();
      if (ok) {
        res = await _raw(method, url, body: body, extraHeaders: extraHeaders);
      }
    }
    return res;
  }

  static Future<http.Response> _raw(
    String method,
    String url, {
    String? body,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await SessionStore.accessToken();
    final headers = <String, String>{
      'apikey': Config.supabaseKey,
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };
    final uri = Uri.parse(url);
    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers, body: body);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: body);
      default:
        return http.get(uri, headers: headers);
    }
  }

  /// Renova o token usando o refresh_token guardado. Atualiza o disco.
  static Future<bool> _refresh() async {
    final refresh = await SessionStore.refreshToken();
    if (refresh == null) return false;
    final res = await http.post(
      Uri.parse('${Config.authToken}?grant_type=refresh_token'),
      headers: {
        'apikey': Config.supabaseKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refresh_token': refresh}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      final user = (data['user'] as Map<String, dynamic>?)?['id'] as String?;
      if (access != null && newRefresh != null) {
        await SessionStore.saveTokens(
          accessToken: access,
          refreshToken: newRefresh,
          userId: user ?? (await SessionStore.userId()) ?? '',
        );
        return true;
      }
    }
    return false;
  }
}
