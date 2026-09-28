package com.projectink.overseer.ink_overseer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class SessionAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SessionAlarmReceiver", "Scheduled writing session alarm fired! Engaging Overseer.")
        val prefs = context.getSharedPreferences("OverseerPrefs", Context.MODE_PRIVATE)

        val durationMinutes = prefs.getInt("scheduled_duration_minutes", 120)
        val isTestMode = prefs.getBoolean("test_mode_enabled", false)

        val now = System.currentTimeMillis()
        val durationMs = durationMinutes * 60 * 1000L

        SessionStateHolder.isSessionActive = true
        SessionStateHolder.isTestMode = isTestMode
        SessionStateHolder.totalSessionMinutes = durationMinutes
        SessionStateHolder.sessionStartTimeMs = now
        SessionStateHolder.sessionEndTimeMs = now + durationMs
        SessionStateHolder.currentCycleIndex = 0

        if (isTestMode) {
            SessionStateHolder.aiAllowanceRemainingSec = 30
            SessionStateHolder.whatsappAllowanceRemainingSec = 0
            SessionStateHolder.utilityAllowanceRemainingSec = 0
        } else {
            SessionStateHolder.aiAllowanceRemainingSec = 300
            SessionStateHolder.whatsappAllowanceRemainingSec = 0
            SessionStateHolder.utilityAllowanceRemainingSec = 0
        }
        SessionStateHolder.saveToPrefs(context)

        // Clear scheduled alarm flag
        prefs.edit().remove("scheduled_start_epoch").apply()

        // Start Watchdog Foreground Service
        val serviceIntent = Intent(context, OverseerWatchdogService::class.java).apply {
            action = OverseerWatchdogService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Launch Overseer Sanctum directly to foreground over any active distraction
        val sanctumIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(sanctumIntent)
    }
}
