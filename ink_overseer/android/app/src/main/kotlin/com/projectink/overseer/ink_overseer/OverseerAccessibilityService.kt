package com.projectink.overseer.ink_overseer

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class OverseerAccessibilityService : AccessibilityService() {

    companion object {
        var instance: OverseerAccessibilityService? = null
            private set
    }

    private lateinit var lockWindowManager: LockWindowManager
    private lateinit var floatingHudManager: FloatingHudManager
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        instance = this
        lockWindowManager = LockWindowManager(this)
        floatingHudManager = FloatingHudManager(this)
        SessionStateHolder.loadFromPrefs(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        lockWindowManager.hideLock()
        floatingHudManager.hideHud()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("OverseerA11y", "Overseer Accessibility Service connected and running.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return
        SessionStateHolder.currentForegroundPackage = packageName

        // If no active session, ensure lock is hidden and exit immediately
        if (!SessionStateHolder.isSessionActive) {
            mainHandler.post {
                lockWindowManager.hideLock()
                floatingHudManager.hideHud()
            }
            return
        }

        evaluateForegroundApp(packageName)
    }

    fun evaluateForegroundApp(packageName: String) {
        val now = System.currentTimeMillis()
        if (now >= SessionStateHolder.sessionEndTimeMs) {
            // Session expired naturally
            SessionStateHolder.isSessionActive = false
            SessionStateHolder.saveToPrefs(this)
            mainHandler.post {
                lockWindowManager.hideLock()
                floatingHudManager.hideHud()
            }
            return
        }

        // If the foreground app is permitted, let the user interact freely!
        if (isAppAllowed(packageName)) {
            return
        }

        // Unauthorized app, blacklisted social media, or Home Launcher!
        // Immediately redirect to Overseer Sanctum with zero flashing
        mainHandler.post {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_lockout", true)
                putExtra("blocked_pkg", packageName)
            }
            startActivity(intent)
        }
    }

    private fun isAppAllowed(pkg: String): Boolean {
        // Our app
        if (pkg == SessionStateHolder.PKG_OVERSEER) return true

        // Android System UI (Status bar, notifications, keyboard, volume panel)
        if (pkg == "com.android.systemui") return true

        // Emergency phone call in progress
        try {
            val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (tm != null && tm.callState != TelephonyManager.CALL_STATE_IDLE) {
                val lower = pkg.lowercase()
                if (lower.contains("dialer") || lower.contains("telecom") ||
                    lower.contains("phone") || lower.contains("incall")) {
                    return true
                }
            }
        } catch (_: Exception) {}

        // User's chosen allowed apps
        if (SessionStateHolder.allowedPackages.contains(pkg)) {
            val lower = pkg.lowercase()
            val isWhatsApp = SessionStateHolder.WHATSAPP_PACKAGES.contains(pkg) || lower.contains("whatsapp")
            if (isWhatsApp) {
                // Phase 1 iron-clad rule: strictly locked during first 30 minutes
                if (SessionStateHolder.currentCycleIndex == 0) {
                    return false
                }
                return SessionStateHolder.whatsappAllowanceRemainingSec > 0
            }

            val isAi = SessionStateHolder.AI_PACKAGES.contains(pkg) || lower.contains("chatgpt") || lower.contains("bard")
            if (isAi) {
                return SessionStateHolder.aiAllowanceRemainingSec > 0
            }

            return true
        }

        return false
    }

    override fun onInterrupt() {
        Log.w("OverseerA11y", "Accessibility service interrupted.")
    }

    private fun formatTime(seconds: Int): String {
        val m = seconds / 60
        val s = seconds % 60
        return String.format("%02d:%02d", m, s)
    }
}
