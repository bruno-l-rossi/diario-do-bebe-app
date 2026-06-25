/// Formatação de hora/duração, portada do app web. Respeita o formato
/// escolhido nas Configurações (24h ou AM/PM).
import '../data/settings.dart';

String _p2(int n) => n.toString().padLeft(2, '0');

String fmtHM(int h, int m) {
  if (currentTimeFmt == '12h') {
    final ap = h < 12 ? 'AM' : 'PM';
    var hh = h % 12;
    if (hh == 0) hh = 12;
    return '$hh:${_p2(m)} $ap';
  }
  return '${_p2(h)}:${_p2(m)}';
}

String fmtH(DateTime d) => fmtHM(d.hour, d.minute);

/// Rótulo curto pro eixo dos gráficos (ex.: "08h" ou "8a"/"8p").
String hourLabel(int h) {
  if (currentTimeFmt == '12h') {
    final ap = h < 12 ? 'a' : 'p';
    var hh = h % 12;
    if (hh == 0) hh = 12;
    return '$hh$ap';
  }
  return '${_p2(h)}h';
}

/// Duração legível: "menos de 1 min", "23 min", "1h 20min".
String fmtDur(Duration d) {
  final m = (d.inMilliseconds / 60000).round();
  if (m < 1) return 'menos de 1 min';
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  final r = m % 60;
  return '${h}h${r > 0 ? ' ${r}min' : ''}';
}

String fmtDurMs(int ms) => fmtDur(Duration(milliseconds: ms));

/// Minutos do dia (0..1439) em "HH:MM", tratando estouro/negativo.
String fmtClock(double minutes) {
  var min = minutes.round() % 1440;
  if (min < 0) min += 1440;
  return fmtHM(min ~/ 60, min % 60);
}

String saudacao(int hour) {
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

/// Idade do bebê a partir da data de nascimento (yyyy-MM-dd).
String ageLabel(String? birth) {
  if (birth == null || birth.isEmpty) return '';
  final b = DateTime.tryParse('${birth}T00:00:00');
  if (b == null) return '';
  final n = DateTime.now();
  int meses = (n.year - b.year) * 12 + (n.month - b.month);
  if (n.day < b.day) meses--;
  if (meses < 0) return '';
  if (meses < 1) {
    final dias = n.difference(b).inDays;
    final sem = dias ~/ 7;
    if (sem <= 0) return '$dias dias';
    return sem > 1 ? '$sem semanas' : '$sem semana';
  }
  if (meses < 24) return meses > 1 ? '$meses meses' : '$meses mês';
  final anos = meses ~/ 12;
  final rm = meses % 12;
  return '$anos anos${rm > 0 ? ' e $rm ${rm > 1 ? 'meses' : 'mês'}' : ''}';
}

const _dias = [
  'domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'
];
const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez'
];

/// "quarta, 24 jun" a partir de uma data.
String longDayLabel(DateTime dt) =>
    '${_dias[dt.weekday % 7]}, ${dt.day} ${_meses[dt.month - 1]}';

/// "24/06" pro eixo dos gráficos.
String shortDay(DateTime dt) => '${_p2(dt.day)}/${_p2(dt.month)}';
