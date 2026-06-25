import 'package:shared_preferences/shared_preferences.dart';

/// Preferências do app (por enquanto, só o formato de hora). Guardadas no disco.
/// `currentTimeFmt` é lido pela formatação de hora em todo o app.
String currentTimeFmt = '24h'; // '24h' | '12h'

class Settings {
  static const _kTimeFmt = 'db_timefmt';

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    currentTimeFmt = p.getString(_kTimeFmt) ?? '24h';
  }

  static Future<void> setTimeFmt(String fmt) async {
    currentTimeFmt = fmt;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTimeFmt, fmt);
  }
}
