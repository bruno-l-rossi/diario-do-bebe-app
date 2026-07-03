package com.rideblan.diario_do_bebe

import android.content.Context
import android.content.SharedPreferences
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

/**
 * REST do Supabase em Kotlin, pro serviço da notificação gravar sem depender
 * do Flutter. Espelha o lib/services/events_repo.dart: mesmo endpoint, mesmo
 * refresh de token em 401, mesmos tokens (SharedPreferences do Flutter).
 */
object SupabaseApi {
    private const val BASE = "https://xvydkvqfcgfysrkmzsae.supabase.co"
    private const val KEY = "sb_publishable_Iylj-64xnspCSFg-u34jmw_sdWa2TU-"
    private const val EVENTS = "$BASE/rest/v1/events"
    private const val REFRESH_URL = "$BASE/auth/v1/token?grant_type=refresh_token"

    private val JSON = "application/json".toMediaType()
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    // O plugin shared_preferences do Flutter guarda tudo aqui, com prefixo "flutter.".
    private fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    fun babyName(ctx: Context): String =
        prefs(ctx).getString("flutter.baby_name", null)?.takeIf { it.isNotBlank() } ?: "Bebê"

    /** Sessões abertas (end_ts null): tipo -> início em millis (a mais recente de cada tipo). */
    fun openSessions(ctx: Context): Map<String, Long>? {
        val body = send(
            ctx, "GET",
            "$EVENTS?select=type,ts&end_ts=is.null&type=in.(soneca,mamada,despertar,sono)",
            null
        ) ?: return null
        return try {
            val arr = JSONArray(body)
            val out = HashMap<String, Long>()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val t = o.optString("type")
                val ts = parseIso(o.optString("ts")) ?: continue
                val cur = out[t]
                if (cur == null || ts > cur) out[t] = ts
            }
            out
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Toca a sessão do tipo: sem sessão aberta, abre (ts=agora); com sessão
     * aberta, encerra (end_ts=agora). Retorna "opened", "closed" ou null (falha).
     */
    fun toggle(ctx: Context, type: String): String? {
        val openBody = send(
            ctx, "GET",
            "$EVENTS?select=id&type=eq.$type&end_ts=is.null&order=ts.desc&limit=1",
            null
        ) ?: return null
        return try {
            val arr = JSONArray(openBody)
            if (arr.length() == 0) {
                val payload = JSONObject().put("type", type).put("ts", isoNow()).toString()
                if (send(ctx, "POST", EVENTS, payload) != null) "opened" else null
            } else {
                val id = arr.getJSONObject(0).getString("id")
                val payload = JSONObject().put("end_ts", isoNow()).toString()
                if (send(ctx, "PATCH", "$EVENTS?id=eq.$id", payload) != null) "closed" else null
            }
        } catch (_: Exception) {
            null
        }
    }

    /** Chamada com o token atual; em 401 renova e repete uma vez. Corpo da resposta ou null. */
    private fun send(ctx: Context, method: String, url: String, payload: String?): String? {
        var r = raw(ctx, method, url, payload) ?: return null
        if (r.first == 401 && refresh(ctx)) {
            r = raw(ctx, method, url, payload) ?: return null
        }
        return if (r.first in 200..299) r.second else null
    }

    private fun raw(ctx: Context, method: String, url: String, payload: String?): Pair<Int, String>? {
        return try {
            val token = prefs(ctx).getString("flutter.sb_access_token", "") ?: ""
            val b = Request.Builder().url(url)
                .header("apikey", KEY)
                .header("Authorization", "Bearer $token")
                .header("Content-Type", "application/json")
            when (method) {
                "POST" -> b.post((payload ?: "").toRequestBody(JSON))
                "PATCH" -> b.patch((payload ?: "").toRequestBody(JSON))
                else -> b.get()
            }
            client.newCall(b.build()).execute().use { res ->
                Pair(res.code, res.body?.string() ?: "")
            }
        } catch (_: Exception) {
            null
        }
    }

    /** Renova o token com o refresh_token e grava de volta pro Flutter ler. */
    private fun refresh(ctx: Context): Boolean {
        val rt = prefs(ctx).getString("flutter.sb_refresh_token", null) ?: return false
        return try {
            val req = Request.Builder().url(REFRESH_URL)
                .header("apikey", KEY)
                .header("Content-Type", "application/json")
                .post(JSONObject().put("refresh_token", rt).toString().toRequestBody(JSON))
                .build()
            client.newCall(req).execute().use { res ->
                if (res.code !in 200..299) return false
                val o = JSONObject(res.body?.string() ?: return false)
                val access = o.optString("access_token")
                val newRt = o.optString("refresh_token")
                if (access.isEmpty() || newRt.isEmpty()) return false
                prefs(ctx).edit()
                    .putString("flutter.sb_access_token", access)
                    .putString("flutter.sb_refresh_token", newRt)
                    .apply()
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isoNow(): String {
        val f = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        f.timeZone = TimeZone.getTimeZone("UTC")
        return f.format(Date())
    }

    /** "2026-07-03T08:15:00.123456+00:00" -> millis. O Supabase devolve em UTC. */
    private fun parseIso(s: String): Long? {
        if (s.length < 19) return null
        return try {
            val f = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
            f.timeZone = TimeZone.getTimeZone("UTC")
            f.parse(s.substring(0, 19))?.time
        } catch (_: Exception) {
            null
        }
    }
}
