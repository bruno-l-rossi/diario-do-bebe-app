/// Configuracao do Supabase. Mesma URL e chave publica do app web (PWA).
/// A chave publishable e publica por design; a protecao real do dado e a RLS
/// por conta (auth.uid() = user_id), igual ao app de hoje.
class Config {
  static const String supabaseUrl = 'https://xvydkvqfcgfysrkmzsae.supabase.co';
  static const String supabaseKey =
      'sb_publishable_Iylj-64xnspCSFg-u34jmw_sdWa2TU-';

  static const String restEvents = '$supabaseUrl/rest/v1/events';
  static const String authToken = '$supabaseUrl/auth/v1/token';

  /// Hora de corte do dia quando nao ha sono noturno pra ancorar (fallback).
  static const int dayResetHour = 5;
}

/// Os tipos de registro do app. Os tres primeiros viram botao na notificacao.
enum EventType { soneca, mamada, despertar, sono, refeicao }

extension EventTypeX on EventType {
  String get id {
    switch (this) {
      case EventType.soneca:
        return 'soneca';
      case EventType.mamada:
        return 'mamada';
      case EventType.despertar:
        return 'despertar';
      case EventType.sono:
        return 'sono';
      case EventType.refeicao:
        return 'refeicao';
    }
  }

  String get label {
    switch (this) {
      case EventType.soneca:
        return 'Soneca';
      case EventType.mamada:
        return 'Mamada';
      case EventType.despertar:
        return 'Despertar';
      case EventType.sono:
        return 'Sono';
      case EventType.refeicao:
        return 'Refeição';
    }
  }

  /// Tipos que sao sessao (comeca/termina). Refeicao nao e sessao.
  bool get isSession => this != EventType.refeicao;

  static EventType? fromId(String id) {
    for (final t in EventType.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}
