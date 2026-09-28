package com.projectink.overseer.ink_overseer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootSentinelReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootSentinel", "Device reboot detected. Checking active session status...")
            val prefs = context.getSharedPreferences("OverseerPrefs", Context.MODE_PRIVATE)
            val isSessionActive = prefs.getBoolean("is_session_active", false)
            val sessionEndMs = prefs.getLong("session_end_time_ms", 0L)
            val now = System.currentTimeMillis()

            if (isSessionActive && now < sessionEndMs) {
                Log.d("BootSentinel", "Active writing session persists! Resuming Overseer Watchdog.")
                val serviceIntent = Intent(context, OverseerWatchdogService::class.java).apply {
                    action = OverseerWatchdogService.ACTION_RESUME_BOOT
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }

                // Redirect to Pure Writer or main launcher
                val launchIntent = context.packageManager.getLaunchIntentForPackage("com.raincat.purewriter")
                    ?: Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            } else if (isSessionActive && now >= sessionEndMs) {
                // Session expired while phone was off
                prefs.edit().putBoolean("is_session_active", false).apply()
            }
        }
    }
}
