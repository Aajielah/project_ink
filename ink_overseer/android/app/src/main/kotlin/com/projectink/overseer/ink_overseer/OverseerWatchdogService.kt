package com.projectink.overseer.ink_overseer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class OverseerWatchdogService : Service() {

    companion object {
        const val CHANNEL_ID = "overseer_focus_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_RESUME_BOOT = "ACTION_RESUME_BOOT"

        var isRunning: Boolean = false
            private set
    }

    private val tickerHandler = Handler(Looper.getMainLooper())
    private var lastWarnedApp: String = ""

    private val tickerRunnable = object : Runnable {
        override fun run() {
            if (!SessionStateHolder.isSessionActive) {
                stopSelf()
                return
            }

            val now = System.currentTimeMillis()
            if (now >= SessionStateHolder.sessionEndTimeMs) {
                onSessionCompleted()
                return
            }

            val elapsedSec = ((now - SessionStateHolder.sessionStartTimeMs) / 1000).toInt()
            val remainingSec = ((SessionStateHolder.sessionEndTimeMs - now) / 1000).toInt()

            // Cycle duration: 30 minutes in normal mode, 60 seconds in test mode
            val cycleDurationSec = if (SessionStateHolder.isTestMode) 60 else 1800
            val newCycleIndex = elapsedSec / cycleDurationSec

            // Detect cycle transition (e.g. entering min 31)
            if (newCycleIndex != SessionStateHolder.currentCycleIndex) {
                SessionStateHolder.currentCycleIndex = newCycleIndex
                refreshAllowancesForNewCycle(newCycleIndex)
            }

            // Meter active app usage
            val currentPkg = SessionStateHolder.currentForegroundPackage
            val lowerPkg = currentPkg.lowercase()

            val isAi = SessionStateHolder.tier3Packages.contains(currentPkg) ||
                    SessionStateHolder.AI_PACKAGES.contains(currentPkg) ||
                    lowerPkg.contains("chatgpt") || lowerPkg.contains("bard") || lowerPkg.contains("claude")

            val isWhatsApp = SessionStateHolder.tier2Packages.contains(currentPkg) ||
                    SessionStateHolder.WHATSAPP_PACKAGES.contains(currentPkg) ||
                    lowerPkg.contains("whatsapp")

            if (isAi) {
                if (SessionStateHolder.aiAllowanceRemainingSec > 0) {
                    SessionStateHolder.aiAllowanceRemainingSec--
                    if (SessionStateHolder.aiAllowanceRemainingSec == 60) {
                        triggerWarning("1 minute left of AI assistance!")
                    }
                    if (SessionStateHolder.aiAllowanceRemainingSec <= 0) {
                        OverseerAccessibilityService.instance?.evaluateForegroundApp(currentPkg)
                    }
                }
            } else if (isWhatsApp) {
                if (SessionStateHolder.whatsappAllowanceRemainingSec > 0) {
                    SessionStateHolder.whatsappAllowanceRemainingSec--
                    if (SessionStateHolder.whatsappAllowanceRemainingSec == 60) {
                        triggerWarning("1 minute left of WhatsApp!")
                    }
                    if (SessionStateHolder.whatsappAllowanceRemainingSec <= 0) {
                        OverseerAccessibilityService.instance?.evaluateForegroundApp(currentPkg)
                    }
                }
            }

            // Update notification
            updateNotification(remainingSec)

            // Periodic save every 5 seconds
            if (elapsedSec % 5 == 0) {
                SessionStateHolder.saveToPrefs(this@OverseerWatchdogService)
            }

            tickerHandler.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START, ACTION_RESUME_BOOT -> {
                SessionStateHolder.loadFromPrefs(this)
                startForeground(NOTIFICATION_ID, buildNotification("Focus Sanctum Activated"))
                tickerHandler.removeCallbacks(tickerRunnable)
                tickerHandler.post(tickerRunnable)
            }
            ACTION_STOP -> {
                stopSession()
            }
        }
        return START_STICKY
    }

    private fun refreshAllowancesForNewCycle(cycleIndex: Int) {
        if (SessionStateHolder.isTestMode) {
            // Fast-testing mode: 30s allowances for rapid verification
            SessionStateHolder.aiAllowanceRemainingSec = 30
            SessionStateHolder.whatsappAllowanceRemainingSec = 30
            SessionStateHolder.utilityAllowanceRemainingSec = 30
        } else {
            // Production mode:
            // AI Pool: fresh 5 minutes (300s)
            SessionStateHolder.aiAllowanceRemainingSec = 300
            // Utility Pool: 5 minutes (300s)
            SessionStateHolder.utilityAllowanceRemainingSec = 300

            // WhatsApp:
            if (cycleIndex == 1) {
                // Minute 31-60: If total session >= 2 hours, 10 mins (600s), else 5 mins (300s)
                SessionStateHolder.whatsappAllowanceRemainingSec =
                    if (SessionStateHolder.totalSessionMinutes >= 120) 600 else 300
            } else if (cycleIndex > 1) {
                // Subsequent 30-min cycles: 5 mins (300s)
                SessionStateHolder.whatsappAllowanceRemainingSec = 300
            }
        }
        SessionStateHolder.saveToPrefs(this)
    }

    private fun triggerWarning(message: String) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(500)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun onSessionCompleted() {
        SessionStateHolder.isSessionActive = false
        SessionStateHolder.saveToPrefs(this)
        OverseerAccessibilityService.instance?.evaluateForegroundApp(SessionStateHolder.currentForegroundPackage)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun stopSession() {
        SessionStateHolder.isSessionActive = false
        SessionStateHolder.saveToPrefs(this)
        tickerHandler.removeCallbacks(tickerRunnable)
        OverseerAccessibilityService.instance?.evaluateForegroundApp(SessionStateHolder.currentForegroundPackage)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        tickerHandler.removeCallbacks(tickerRunnable)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Sanctum Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live remaining writing session and allowance timers."
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(status: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Sanctum Active")
            .setContentText(status)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(remainingSec: Int) {
        val h = remainingSec / 3600
        val m = (remainingSec % 3600) / 60
        val s = remainingSec % 60
        val timeStr = if (h > 0) String.format("%02d:%02d:%02d", h, m, s) else String.format("%02d:%02d", m, s)
        val text = "⏳ $timeStr remaining • Stay inside Pure Writer"

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }
}
