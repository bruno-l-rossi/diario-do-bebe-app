import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o token de login e os marcadores de sessao aberta em disco, pra que
/// tanto o app quanto o servico em primeiro plano (que roda noutro isolate)
/// consigam ler. Espelha o que o service worker do PWA fazia.
class SessionStore {
  static const _kAccess = 'sb_access_token';
  static const _kRefresh = 'sb_refresh_token';
  static const _kUserId = 'sb_user_id';
  static const _kBabyName = 'baby_name';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
    await p.setString(_kRefresh, refreshToken);
    await p.setString(_kUserId, userId);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kUserId);
  }

  static Future<String?> accessToken() async =>
      (await SharedPreferences.getInstance()).getString(_kAccess);

  static Future<String?> refreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_kRefresh);

  static Future<String?> userId() async =>
      (await SharedPreferences.getInstance()).getString(_kUserId);

  static Future<void> saveBabyName(String name) async =>
      (await SharedPreferences.getInstance()).setString(_kBabyName, name);

  static Future<String> babyName() async =>
      (await SharedPreferences.getInstance()).getString(_kBabyName) ?? 'Bebê';
}
