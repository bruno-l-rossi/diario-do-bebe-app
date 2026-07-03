package com.rideblan.diario_do_bebe

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Religa a notificação fixa depois de reiniciar o celular ou atualizar o app,
 * se o Bruno deixou ela ligada (flag db_notif_on gravada pelo Flutter).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        val on = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.db_notif_on", false)
        if (!on) return

        val i = Intent(ctx, NotifService::class.java).setAction(NotifService.ACTION_START)
        if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(i) else ctx.startService(i)
    }
}
