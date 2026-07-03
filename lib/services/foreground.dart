import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ponte pro serviço nativo da notificação fixa (NotifService, em Kotlin).
/// A notificação tem layout customizado: 4 botões de ícone redondo colorido
/// (Soneca, Mamada, Refeição, Despertar) e cronômetro de sessão aberta.
/// Soneca/Mamada/Despertar gravam direto pela tela bloqueada; Refeição abre
/// a ficha no app.
class ForegroundController {
  static const _ch = MethodChannel('diario/notif');

  /// Flag lida pelo BootReceiver (religa a notificação após reiniciar).
  static const _kOn = 'db_notif_on';

  static Future<bool> isRunning() async {
    try {
      return (await _ch.invokeMethod<bool>('isRunning')) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> start() async {
    await _ch.invokeMethod('start');
    (await SharedPreferences.getInstance()).setBool(_kOn, true);
  }

  static Future<void> stop() async {
    await _ch.invokeMethod('stop');
    (await SharedPreferences.getInstance()).setBool(_kOn, false);
  }

  /// Pede pro serviço reler as sessões abertas (após registro feito no app).
  static Future<void> refresh() async {
    try {
      await _ch.invokeMethod('refresh');
    } catch (_) {}
  }

  /// Ação pendente de um toque na notificação (ex.: 'refeicao'). Consome.
  static Future<String?> consumeLaunchAction() async {
    try {
      return await _ch.invokeMethod<String>('consumeLaunchAction');
    } catch (_) {
      return null;
    }
  }
}
