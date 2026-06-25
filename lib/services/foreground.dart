import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../config.dart';
import '../theme.dart';
import 'events_repo.dart';
import 'session_store.dart';

/// O servico em primeiro plano: a notificacao fixa com os botoes.
/// Tocar um botao roda aqui (noutro isolate), grava no Supabase e atualiza o
/// texto da notificacao. Soneca/Mamada/Despertar gravam direto, sem abrir o
/// app, mesmo pela tela bloqueada. Sono e Refeicao abrem o app.

/// Os 3 botoes em destaque na notificacao (decisao do Bruno).
const List<EventType> kNotifButtons = [
  EventType.soneca,
  EventType.mamada,
  EventType.despertar,
];

/// Cor do texto de cada botao na notificacao (mesma paleta do app).
Color _btnColor(EventType t) {
  switch (t) {
    case EventType.soneca:
      return AppColors.soneca;
    case EventType.mamada:
      return AppColors.mamada;
    case EventType.despertar:
      return AppColors.despertar;
    default:
      return AppColors.accent;
  }
}

/// Emoji de cada tipo, pra notificacao nao ficar sem graca.
String _emoji(EventType t) {
  switch (t) {
    case EventType.soneca:
      return '😴';
    case EventType.mamada:
      return '🍼';
    case EventType.despertar:
      return '🌙';
    case EventType.sono:
      return '🛌';
    case EventType.refeicao:
      return '🥣';
  }
}

List<NotificationButton> _notifButtons() => [
      for (final t in kNotifButtons)
        NotificationButton(
          id: t.id,
          text: '${_emoji(t)} ${t.label}',
          textColor: _btnColor(t),
        ),
    ];

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BabyTaskHandler());
}

class BabyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _refreshNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  /// Botao tocado na notificacao. id = 'soneca' | 'mamada' | 'despertar'.
  @override
  Future<void> onNotificationButtonPressed(String id) async {
    final type = EventTypeX.fromId(id);
    if (type == null) return;
    String msg;
    try {
      msg = await EventsRepo.toggleSession(type);
    } catch (_) {
      msg = 'Falhou. Abre o app pra registrar.';
    }
    final baby = await SessionStore.babyName();
    FlutterForegroundTask.updateService(
      notificationTitle: '👶 $baby — $msg',
      notificationText: '😴 Soneca · 🍼 Mamada · 🌙 Despertar',
      notificationButtons: _notifButtons(),
    );
  }

  /// Toque no corpo da notificacao abre o app.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}

  Future<void> _refreshNotification() async {
    final baby = await SessionStore.babyName();
    FlutterForegroundTask.updateService(
      notificationTitle: '👶 $baby — diário aberto',
      notificationText: '😴 Soneca · 🍼 Mamada · 🌙 Despertar',
      notificationButtons: _notifButtons(),
    );
  }
}

/// Liga/desliga e configura o servico. Chamado pelo app.
class ForegroundController {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        // Canal novo (v2): a importancia so e aplicada na criacao do canal.
        // DEFAULT faz a notificacao aparecer na tela de bloqueio; sem som/vibra.
        channelId: 'diario_bebe_lockscreen_v2',
        channelName: 'Diário do Bebê (botões fixos)',
        channelDescription:
            'Notificação fixa com os botões de registro do bebê.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  static Future<void> start() async {
    await requestPermissions();
    final baby = await SessionStore.babyName();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '👶 $baby — diário aberto',
        notificationText: '😴 Soneca · 🍼 Mamada · 🌙 Despertar',
        notificationButtons: _notifButtons(),
        callback: startCallback,
      );
    }
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<void> requestPermissions() async {
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}
