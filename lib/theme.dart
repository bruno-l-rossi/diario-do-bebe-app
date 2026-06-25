import 'package:flutter/material.dart';

/// Paleta exata do app web (index.html), pra o nativo ficar idêntico.
class AppColors {
  static const bg = Color(0xFF0D1B2A);
  static const bg2 = Color(0xFF0A1622);
  static const card = Color(0xFF16263A);
  static const card2 = Color(0xFF1D3148);
  static const ink = Color(0xFFEEF4FB);
  static const muted = Color(0xFF8EA6C0);
  static const line = Color(0xFF26405B);
  static const accent = Color(0xFF4F9DFF);
  static const accentSoft = Color(0xFFBCD8FF);

  // por tipo
  static const soneca = Color(0xFF6FA8FF);
  static const sono = Color(0xFF8A9BFF);
  static const mamada = Color(0xFFE6A866);
  static const refeicao = Color(0xFF86CF73);
  static const despertar = Color(0xFFC79BE0);

  // qualidade da refeicao
  static const qBad = Color(0xFFE5705F);
  static const qOk = Color(0xFFE0B056);
  static const qMid = Color(0xFF9FCE6A);
  static const qGood = Color(0xFF62C46F);

  // quem serviu
  static const sMae = Color(0xFFE29AD0);
  static const sPai = Color(0xFF7FA8E0);
  static const sOutro = Color(0xFF9AA7B8);

  // fundo do dot no historico
  static const dotSoneca = Color(0xFF1B3559);
  static const dotSono = Color(0xFF222A55);
  static const dotMamada = Color(0xFF4A331D);
  static const dotRefeicao = Color(0xFF243F1D);
  static const dotDespertar = Color(0xFF3A2647);
}

/// Cor "principal" de cada tipo (borda do botao, linha do grafico).
const Map<String, Color> kTypeColor = {
  'soneca': AppColors.soneca,
  'sono': AppColors.sono,
  'mamada': AppColors.mamada,
  'refeicao': AppColors.refeicao,
  'despertar': AppColors.despertar,
};

const Map<String, Color> kDotColor = {
  'soneca': AppColors.dotSoneca,
  'sono': AppColors.dotSono,
  'mamada': AppColors.dotMamada,
  'refeicao': AppColors.dotRefeicao,
  'despertar': AppColors.dotDespertar,
};

const Map<String, String> kTypeEmoji = {
  'soneca': '😴',
  'sono': '🛌',
  'mamada': '🍼',
  'refeicao': '🥣',
  'despertar': '🌙',
};

/// Qualidade da refeicao (0..3), igual ao site.
const List<({String nome, String emoji, Color cor})> kQuality = [
  (nome: 'Recusou', emoji: '🚫', cor: AppColors.qBad),
  (nome: 'Pouco', emoji: '😕', cor: AppColors.qOk),
  (nome: 'Médio', emoji: '🙂', cor: AppColors.qMid),
  (nome: 'Bem', emoji: '😋', cor: AppColors.qGood),
];

const List<({String v, String nome, String emoji, Color cor})> kServers = [
  (v: 'mae', nome: 'Mãe', emoji: '👩', cor: AppColors.sMae),
  (v: 'pai', nome: 'Pai', emoji: '👨', cor: AppColors.sPai),
  (v: 'outro', nome: 'Outro', emoji: '🧑', cor: AppColors.sOutro),
];

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      onPrimary: const Color(0xFF06121F),
    ),
    cardColor: AppColors.card,
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.card2,
      contentTextStyle: TextStyle(color: AppColors.ink),
    ),
  );
}
