package com.rideblan.diario_do_bebe

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Ponte entre o Flutter e o serviço da notificação (canal "diario/notif").
 * Também recebe o toque no botão Refeição da notificação (extra launch_action)
 * e entrega pro Dart abrir a ficha.
 */
class MainActivity : FlutterActivity() {

    private var launchAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchAction = intent?.getStringExtra(NotifService.EXTRA_LAUNCH)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "diario/notif")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        ensurePermissions()
                        startSvc(NotifService.ACTION_START)
                        result.success(true)
                    }
                    "stop" -> {
                        stopService(Intent(this, NotifService::class.java))
                        result.success(true)
                    }
                    "isRunning" -> result.success(NotifService.running)
                    "refresh" -> {
                        if (NotifService.running) startSvc(NotifService.ACTION_REFRESH)
                        result.success(true)
                    }
                    "consumeLaunchAction" -> {
                        result.success(launchAction)
                        launchAction = null
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(NotifService.EXTRA_LAUNCH)?.let { launchAction = it }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        // Se a permissão de notificação chegou depois do serviço subir, reposta.
        if (requestCode == 100 && NotifService.running) startSvc(NotifService.ACTION_REFRESH)
    }

    private fun startSvc(action: String) {
        val i = Intent(this, NotifService::class.java).setAction(action)
        if (Build.VERSION.SDK_INT >= 26) startForegroundService(i) else startService(i)
    }

    private fun ensurePermissions() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 100
            )
        }
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        if (Build.VERSION.SDK_INT >= 23 && !pm.isIgnoringBatteryOptimizations(packageName)) {
            try {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        .setData(Uri.parse("package:$packageName"))
                )
            } catch (_: Exception) {
                // Alguns aparelhos não têm essa tela; segue sem.
            }
        }
    }
}
