package com.rideblan.diario_do_bebe

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Serviço em primeiro plano com a notificação fixa de layout customizado
 * (estilo CamScanner): 4 botões com ícone redondo colorido e rótulo embaixo.
 * Soneca, Mamada e Despertar gravam na hora, mesmo pela tela bloqueada;
 * Refeição abre a ficha no app. Sessão aberta vira cronômetro no título.
 */
class NotifService : Service() {

    companion object {
        const val CHANNEL_ID = "diario_bebe_botoes_v3"
        const val NOTIF_ID = 1001
        const val ACTION_START = "com.rideblan.diario_do_bebe.START"
        const val ACTION_REFRESH = "com.rideblan.diario_do_bebe.REFRESH"
        const val ACTION_TOGGLE = "com.rideblan.diario_do_bebe.TOGGLE"
        const val EXTRA_TYPE = "type"
        const val EXTRA_LAUNCH = "launch_action"

        @Volatile
        var running = false
    }

    private lateinit var worker: HandlerThread
    private lateinit var handler: Handler

    @Volatile
    private var open: Map<String, Long> = emptyMap()

    @Volatile
    private var feedback: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        worker = HandlerThread("diario-notif").also { it.start() }
        handler = Handler(worker.looper)
        createChannel()
    }

    override fun onDestroy() {
        running = false
        worker.quitSafely()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Tem que virar foreground rápido; o conteúdo é atualizado depois.
        foreground()
        val type = if (intent?.action == ACTION_TOGGLE) intent.getStringExtra(EXTRA_TYPE) else null
        handler.post {
            if (type != null) {
                val r = SupabaseApi.toggle(this, type)
                feedback = feedbackMsg(type, r)
                handler.postDelayed({ feedback = null; update() }, 20_000)
            }
            open = SupabaseApi.openSessions(this) ?: open
            update()
        }
        return START_STICKY
    }

    // ---- conteúdo ----

    private fun feedbackMsg(type: String, r: String?): String = when (r) {
        "opened" -> when (type) {
            "soneca" -> "Soneca iniciada ✓"
            "mamada" -> "Mamada iniciada ✓"
            "despertar" -> "Despertar registrado ✓"
            "sono" -> "Sono noturno iniciado ✓"
            else -> "Registrado ✓"
        }
        "closed" -> when (type) {
            "soneca" -> "Acordou da soneca ✓"
            "mamada" -> "Mamada encerrada ✓"
            "despertar" -> "Voltou a dormir ✓"
            "sono" -> "Sono encerrado ✓"
            else -> "Encerrado ✓"
        }
        else -> "Falhou. Abre o app pra registrar."
    }

    private fun sessionTitle(type: String): String = when (type) {
        "soneca" -> "Soneca em andamento"
        "mamada" -> "Mamando agora"
        "despertar" -> "Acordado (noite)"
        "sono" -> "Sono da noite"
        else -> type
    }

    private fun build(): Notification {
        val baby = SupabaseApi.babyName(this)
        val current = open.maxByOrNull { it.value }
        val title = current?.let { sessionTitle(it.key) } ?: baby
        val sub = feedback
            ?: if (current != null) baby else "Toque registra na hora, sem desbloquear"

        val col = RemoteViews(packageName, R.layout.notif_collapsed)
        val exp = RemoteViews(packageName, R.layout.notif_expanded)
        for (v in listOf(col, exp)) {
            v.setTextViewText(R.id.n_title, title)
            v.setTextViewText(R.id.n_sub, sub)
            if (current != null) {
                v.setViewVisibility(R.id.n_chrono, View.VISIBLE)
                v.setChronometer(
                    R.id.n_chrono,
                    SystemClock.elapsedRealtime() - (System.currentTimeMillis() - current.value),
                    null,
                    true
                )
            } else {
                v.setViewVisibility(R.id.n_chrono, View.GONE)
            }
        }

        toggleBtn(exp, R.id.b_soneca, R.id.b_soneca_tx, "soneca",
            if (open.containsKey("soneca")) "Acordou" else "Soneca", 1)
        toggleBtn(exp, R.id.b_mamada, R.id.b_mamada_tx, "mamada",
            if (open.containsKey("mamada")) "Terminou" else "Mamada", 2)
        exp.setTextViewText(R.id.b_refeicao_tx, "Refeição")
        exp.setOnClickPendingIntent(R.id.b_refeicao, activityIntent("refeicao", 3))
        toggleBtn(exp, R.id.b_despertar, R.id.b_despertar_tx, "despertar",
            if (open.containsKey("despertar")) "Dormiu" else "Despertar", 4)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_lua)
            .setContentTitle(title)
            .setContentText(sub)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(col)
            .setCustomBigContentView(exp)
            .setContentIntent(activityIntent(null, 0))
            .build()
    }

    private fun toggleBtn(v: RemoteViews, id: Int, txId: Int, type: String, label: String, req: Int) {
        v.setTextViewText(txId, label)
        val i = Intent(this, NotifService::class.java)
            .setAction(ACTION_TOGGLE)
            .putExtra(EXTRA_TYPE, type)
        val pi = PendingIntent.getService(
            this, req, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        v.setOnClickPendingIntent(id, pi)
    }

    private fun activityIntent(action: String?, req: Int): PendingIntent {
        val i = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (action != null) i.putExtra(EXTRA_LAUNCH, action)
        return PendingIntent.getActivity(
            this, req, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    // ---- infra ----

    private fun foreground() {
        val fgsType = if (Build.VERSION.SDK_INT >= 34)
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
        ServiceCompat.startForeground(this, NOTIF_ID, build(), fgsType)
    }

    private fun update() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, build())
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val ch = NotificationChannel(
            CHANNEL_ID,
            "Diário do Bebê (botões fixos)",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Notificação fixa com os botões de registro do bebê."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(ch)
    }
}
