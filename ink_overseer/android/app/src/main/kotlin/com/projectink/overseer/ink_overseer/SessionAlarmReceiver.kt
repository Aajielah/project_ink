package com.projectink.overseer.ink_overseer

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class SessionAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("SessionAlarmReceiver", "Scheduled writing session alarm fired! Engaging Focus Sanctum.")

        // First load existing state/packages from prefs so saved tier packages are not lost!
        SessionStateHolder.loadFromPrefs(context)

        // Read accurately from Flutter's shared preferences with OverseerPrefs fallback
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val overseerPrefs = context.getSharedPreferences("OverseerPrefs", Context.MODE_PRIVATE)

        val durationMinutes = if (flutterPrefs.contains("flutter.scheduled_duration_minutes")) {
            flutterPrefs.getInt("flutter.scheduled_duration_minutes", 120)
        } else {
            overseerPrefs.getInt("scheduled_duration_minutes", 120)
        }

        val isTestMode = if (flutterPrefs.contains("flutter.test_mode_enabled")) {
            flutterPrefs.getBoolean("flutter.test_mode_enabled", false)
        } else {
            overseerPrefs.getBoolean("test_mode_enabled", false)
        }

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

        // Clear scheduled alarm flag from both preferences
        overseerPrefs.edit().remove("scheduled_start_epoch").apply()
        flutterPrefs.edit().remove("flutter.scheduled_start_epoch").apply()

        // 1. Wake screen up from sleep mode
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
            val wakeLock = powerManager?.newWakeLock(
                android.os.PowerManager.FULL_WAKE_LOCK or
                android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP or
                android.os.PowerManager.ON_AFTER_RELEASE,
                "FocusSanctum:SessionAlarmWakeLock"
            )
            wakeLock?.acquire(15000L)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Physically eject user out of any distraction app back to home screen
        OverseerAccessibilityService.instance?.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)

        // 2. Start Watchdog Foreground Service
        val serviceIntent = Intent(context, OverseerWatchdogService::class.java).apply {
            action = OverseerWatchdogService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // 3. Launch Pure Writer immediately into the foreground, or Focus Sanctum if not installed
        val pm = context.packageManager
        val pureWriterIntent = pm.getLaunchIntentForPackage("com.raincat.purewriter")
        val targetIntent = if (pureWriterIntent != null) {
            pureWriterIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            pureWriterIntent
        } else {
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        }
        try {
            context.startActivity(targetIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 4. Trigger sentry evaluation to enforce lockdown immediately
        OverseerAccessibilityService.instance?.evaluateForegroundApp(SessionStateHolder.currentForegroundPackage)
    }
}
