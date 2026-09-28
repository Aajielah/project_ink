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
        // 0. Hardcoded Blacklist of Banned Distractions (NEVER ALLOWED)
        if (SessionStateHolder.isBlacklisted(pkg)) {
            return false
        }

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

        // Tier 1: Writing Sanctuary (Unlimited 24/7)
        if (SessionStateHolder.tier1Packages.contains(pkg)) {
            return true
        }

        // Tier 2: The Social Leash (The WhatsApp Rule)
        val isTier2 = SessionStateHolder.tier2Packages.contains(pkg) ||
                (SessionStateHolder.allowedPackages.contains(pkg) && pkg.lowercase().contains("whatsapp"))
        if (isTier2) {
            // Phase 1 (First 30 minutes in normal mode, or minute 1 in test mode): 100% LOCKED!
            if (SessionStateHolder.currentCycleIndex == 0) {
                return false
            }
            return SessionStateHolder.whatsappAllowanceRemainingSec > 0
        }

        // Tier 3: AI Assistant Pool (5-Minute Pool Throughout)
        val isTier3 = SessionStateHolder.tier3Packages.contains(pkg) ||
                (SessionStateHolder.allowedPackages.contains(pkg) && (pkg.lowercase().contains("chatgpt") || pkg.lowercase().contains("bard") || pkg.lowercase().contains("claude")))
        if (isTier3) {
            return SessionStateHolder.aiAllowanceRemainingSec > 0
        }

        // Tier 4: Secondary Tools (Phase 1 Locked 100%, Phase 2 Unlocks)
        val isTier4 = SessionStateHolder.tier4Packages.contains(pkg)
        if (isTier4) {
            // Phase 1 (First 30 minutes in normal mode, or minute 1 in test mode): 100% LOCKED!
            if (SessionStateHolder.currentCycleIndex == 0) {
                return false
            }
            // Phase 2: Fully unlocked for writing secondary tools/docs
            return true
        }

        // Fallback for general allowed apps
        if (SessionStateHolder.allowedPackages.contains(pkg)) {
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
