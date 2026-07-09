import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do app, guardadas no disco do aparelho.
/// `currentTimeFmt` é lido pela formatação de hora em todo o app.
String currentTimeFmt = '24h'; // '24h' | '12h'

/// Se este aparelho já viu o tour do primeiro login.
bool onboarded = false;

class Settings {
  static const _kTimeFmt = 'db_timefmt';
  static const _kOnboarded = 'db_onboarded';

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    currentTimeFmt = p.getString(_kTimeFmt) ?? '24h';
    onboarded = p.getBool(_kOnboarded) ?? false;
  }

  static Future<void> setTimeFmt(String fmt) async {
    currentTimeFmt = fmt;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTimeFmt, fmt);
  }

  static Future<void> setOnboarded() async {
    onboarded = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, true);
  }
}
