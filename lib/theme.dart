import 'package:flutter/material.dart';

/// Design system do app, adaptado do DESIGN-meta.md pro nosso mundo:
/// superfícies calmas, botões pílula, cartões bem arredondados (20-24px),
/// borda hairline de 1px, elevação flat e UMA cor de ação usada com
/// parcimônia. Duas paletas: clara aconchegante (dia) e escura de
/// madrugada (noite), trocadas pelo modo do celular.
///
/// As telas continuam usando `AppColors.x`; por baixo, os getters leem a
/// paleta ativa. Por isso cores NUNCA entram em expressão `const`.
class Palette {
  final Color bg, bg2, card, card2, ink, muted, line;
  final Color accent, accentSoft, onAccent;
  final Color soneca, sono, mamada, refeicao, despertar, nota;
  final Color dotSoneca, dotSono, dotMamada, dotRefeicao, dotDespertar, dotNota;
  final Color qBad, qOk, qMid, qGood;
  final Color sMae, sPai, sOutro;
  final Color grid; // linhas-guia dos gráficos

  const Palette({
    required this.bg,
    required this.bg2,
    required this.card,
    required this.card2,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.soneca,
    required this.sono,
    required this.mamada,
    required this.refeicao,
    required this.despertar,
    required this.nota,
    required this.dotSoneca,
    required this.dotSono,
    required this.dotMamada,
    required this.dotRefeicao,
    required this.dotDespertar,
    required this.dotNota,
    required this.qBad,
    required this.qOk,
    required this.qMid,
    required this.qGood,
    required this.sMae,
    required this.sPai,
    required this.sOutro,
    required this.grid,
  });
}

/// Madrugada: o tema escuro de sempre, com o azul de ação um tom mais quente.
const Palette kDarkPalette = Palette(
  bg: Color(0xFF0D1B2A),
  bg2: Color(0xFF0A1622),
  card: Color(0xFF16263A),
  card2: Color(0xFF1D3148),
  ink: Color(0xFFEEF4FB),
  muted: Color(0xFF8EA6C0),
  line: Color(0xFF26405B),
  accent: Color(0xFF6C93F2),
  accentSoft: Color(0xFFC7D6FB),
  onAccent: Color(0xFF0A1524),
  soneca: Color(0xFF6FA8FF),
  sono: Color(0xFF8A9BFF),
  mamada: Color(0xFFE6A866),
  refeicao: Color(0xFF86CF73),
  despertar: Color(0xFFC79BE0),
  nota: Color(0xFFE29AD0),
  dotSoneca: Color(0xFF1B3559),
  dotSono: Color(0xFF222A55),
  dotMamada: Color(0xFF4A331D),
  dotRefeicao: Color(0xFF243F1D),
  dotDespertar: Color(0xFF3A2647),
  dotNota: Color(0xFF44273C),
  qBad: Color(0xFFE5705F),
  qOk: Color(0xFFE0B056),
  qMid: Color(0xFF9FCE6A),
  qGood: Color(0xFF62C46F),
  sMae: Color(0xFFE29AD0),
  sPai: Color(0xFF7FA8E0),
  sOutro: Color(0xFF9AA7B8),
  grid: Color(0x12FFFFFF),
);

/// Dia: branco quente (não estéril), tinta café, pastéis com contraste.
const Palette kLightPalette = Palette(
  bg: Color(0xFFFAF6F1),
  bg2: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  card2: Color(0xFFF2EBE2),
  ink: Color(0xFF33302B),
  muted: Color(0xFF8A8175),
  line: Color(0xFFEAE2D8),
  accent: Color(0xFF4E7DE0),
  accentSoft: Color(0xFF3B62BC),
  onAccent: Color(0xFFFFFFFF),
  soneca: Color(0xFF4A7CD6),
  sono: Color(0xFF6B77D9),
  mamada: Color(0xFFC97F2E),
  refeicao: Color(0xFF55963F),
  despertar: Color(0xFF9A64BE),
  nota: Color(0xFFC75FA5),
  dotSoneca: Color(0xFFE4EDFC),
  dotSono: Color(0xFFE7E9FA),
  dotMamada: Color(0xFFF8ECDB),
  dotRefeicao: Color(0xFFE6F2DE),
  dotDespertar: Color(0xFFF1E6F8),
  dotNota: Color(0xFFF9E3F0),
  qBad: Color(0xFFCE4B3C),
  qOk: Color(0xFFBE8A1F),
  qMid: Color(0xFF6FA23E),
  qGood: Color(0xFF3C9A55),
  sMae: Color(0xFFC75FA5),
  sPai: Color(0xFF4A7CD6),
  sOutro: Color(0xFF8D857A),
  grid: Color(0x1433302B),
);

/// Paleta ativa. Trocada pelo modo do celular (ver main.dart).
Palette kP = kDarkPalette;
bool kIsDark = true;

void setPaletteFor(Brightness b) {
  kIsDark = b == Brightness.dark;
  kP = kIsDark ? kDarkPalette : kLightPalette;
}

/// Mesmos nomes de sempre; agora leem a paleta ativa.
/// NUNCA usar dentro de expressão `const`.
class AppColors {
  static Color get bg => kP.bg;
  static Color get bg2 => kP.bg2;
  static Color get card => kP.card;
  static Color get card2 => kP.card2;
  static Color get ink => kP.ink;
  static Color get muted => kP.muted;
  static Color get line => kP.line;
  static Color get accent => kP.accent;
  static Color get accentSoft => kP.accentSoft;
  static Color get onAccent => kP.onAccent;

  static Color get soneca => kP.soneca;
  static Color get sono => kP.sono;
  static Color get mamada => kP.mamada;
  static Color get refeicao => kP.refeicao;
  static Color get despertar => kP.despertar;
  static Color get nota => kP.nota;

  static Color get qBad => kP.qBad;
  static Color get qOk => kP.qOk;
  static Color get qMid => kP.qMid;
  static Color get qGood => kP.qGood;

  static Color get sMae => kP.sMae;
  static Color get sPai => kP.sPai;
  static Color get sOutro => kP.sOutro;

  static Color get dotSoneca => kP.dotSoneca;
  static Color get dotSono => kP.dotSono;
  static Color get dotMamada => kP.dotMamada;
  static Color get dotRefeicao => kP.dotRefeicao;
  static Color get dotDespertar => kP.dotDespertar;
  static Color get dotNota => kP.dotNota;
}

/// Cor "principal" de cada tipo (borda do botão, linha do gráfico).
/// 'nota' fica fora de propósito: é diário, não entra em gráfico.
Map<String, Color> get kTypeColor => {
      'soneca': kP.soneca,
      'sono': kP.sono,
      'mamada': kP.mamada,
      'refeicao': kP.refeicao,
      'despertar': kP.despertar,
    };

/// Cor da nota (ícone e histórico; não entra em análise).
Color get kNotaColor => kP.nota;

Map<String, Color> get kDotColor => {
      'soneca': kP.dotSoneca,
      'sono': kP.dotSono,
      'mamada': kP.dotMamada,
      'refeicao': kP.dotRefeicao,
      'despertar': kP.dotDespertar,
      'nota': kP.dotNota,
    };

const Map<String, String> kTypeEmoji = {
  'soneca': '😴',
  'sono': '🛌',
  'mamada': '🍼',
  'refeicao': '🥣',
  'despertar': '🌙',
  'nota': '📝',
};

/// Ícones por tipo, mesma família visual da notificação.
const Map<String, IconData> kTypeIcon = {
  'soneca': Icons.bedtime,
  'sono': Icons.bed,
  'mamada': Icons.local_drink,
  'refeicao': Icons.restaurant,
  'despertar': Icons.auto_awesome,
  'nota': Icons.favorite,
};

/// Qualidade da refeição (0..3), igual ao site.
List<({String nome, String emoji, Color cor})> get kQuality => [
      (nome: 'Recusou', emoji: '🚫', cor: kP.qBad),
      (nome: 'Pouco', emoji: '😕', cor: kP.qOk),
      (nome: 'Médio', emoji: '🙂', cor: kP.qMid),
      (nome: 'Bem', emoji: '😋', cor: kP.qGood),
    ];

List<({String v, String nome, String emoji, Color cor})> get kServers => [
      (v: 'mae', nome: 'Mãe', emoji: '👩', cor: kP.sMae),
      (v: 'pai', nome: 'Pai', emoji: '👨', cor: kP.sPai),
      (v: 'outro', nome: 'Outro', emoji: '🧑', cor: kP.sOutro),
    ];

/// Raios do sistema (escala do DESIGN-meta, enxugada pro app):
/// input 14 · cartão 20 · cartão-destaque 24 · pílula 100.
class AppRadius {
  static const double input = 14;
  static const double card = 20;
  static const double feature = 24;
  static const double pill = 100;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? kDarkPalette : kLightPalette;
  final base = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      surface: p.bg,
      primary: p.accent,
      secondary: p.accent,
      onPrimary: p.onAccent,
      outline: p.line,
    ),
    cardColor: p.card,
    dividerColor: p.line,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
    ),
    // Botões sempre pílula (assinatura do sistema).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: p.accent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: p.ink,
        side: BorderSide(color: p.line, width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: p.accent, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.bg2,
      indicatorColor: p.accent.withValues(alpha: 0.16),
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: p.muted)),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: p.ink, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.card2,
      contentTextStyle: TextStyle(color: p.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.feature),
      ),
      titleTextStyle: TextStyle(
          color: p.ink, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: TextStyle(color: p.muted, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.feature)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide(color: p.line),
    ),
    listTileTheme: ListTileThemeData(
      textColor: p.ink,
      iconColor: p.muted,
    ),
  );
}
