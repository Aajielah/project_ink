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

    private fun isInputMethodOrSystemOverlay(pkg: String): Boolean {
        if (pkg == "com.android.systemui") return true
        val lower = pkg.lowercase()
        return lower.contains("inputmethod") ||
                lower.contains("keyboard") ||
                lower.contains("kika") ||
                lower.contains("ime") ||
                lower.contains("swiftkey") ||
                lower.contains("latin") ||
                lower.contains("gboard")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // If the event is a keyboard or system UI overlay, do NOT overwrite the active app!
        if (!isInputMethodOrSystemOverlay(packageName)) {
            SessionStateHolder.currentForegroundPackage = packageName
        }

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

        // If the foreground app is permitted, ensure lock is hidden and let user interact freely!
        if (isAppAllowed(packageName)) {
            mainHandler.post {
                lockWindowManager.hideLock()
            }
            return
        }

        // Unauthorized app, blacklisted social media, expired allowance, or Home Launcher!
        mainHandler.post {
            // 1. Physically eject the forbidden app by triggering Android Home action
            performGlobalAction(GLOBAL_ACTION_HOME)

            // 2. Display the full-screen LockWindowManager shield immediately over the screen
            val appLabel = try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (_: Exception) {
                packageName
            }
            lockWindowManager.showLock(
                appLabel,
                "Access blocked by Focus Sanctum.",
                "Writing session is active. Stay inside Pure Writer."
            )

            // 3. Bring MainActivity to the front
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_lockout", true)
                putExtra("blocked_pkg", packageName)
            }
            try {
                startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun isAppAllowed(pkg: String): Boolean {
        // 0. Hardcoded Blacklist of Banned Distractions (NEVER ALLOWED)
        if (SessionStateHolder.isBlacklisted(pkg)) {
            return false
        }

        // Always permit software keyboards so user can type inside permitted apps
        if (isInputMethodOrSystemOverlay(pkg)) {
            return true
        }

        // Our app
        if (pkg == SessionStateHolder.PKG_OVERSEER) return true

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

        // Calculate dynamic cycle index from real hardware clock
        val now = System.currentTimeMillis()
        val elapsedSec = if (SessionStateHolder.sessionStartTimeMs > 0) {
            ((now - SessionStateHolder.sessionStartTimeMs) / 1000).toInt()
        } else {
            0
        }
        val cycleDurationSec = if (SessionStateHolder.isTestMode) 60 else 1800
        val dynamicCycleIndex = elapsedSec / cycleDurationSec
        SessionStateHolder.currentCycleIndex = dynamicCycleIndex

        // Tier 1: Writing Sanctuary (Unlimited 24/7)
        if (SessionStateHolder.tier1Packages.contains(pkg) || pkg == SessionStateHolder.PKG_PURE_WRITER) {
            return true
        }

        // Tier 2: The Social Leash (The WhatsApp Rule)
        val isTier2 = SessionStateHolder.tier2Packages.contains(pkg) ||
                (SessionStateHolder.allowedPackages.contains(pkg) && pkg.lowercase().contains("whatsapp")) ||
                SessionStateHolder.WHATSAPP_PACKAGES.contains(pkg) ||
                pkg.lowercase().contains("whatsapp")
        if (isTier2) {
            // Phase 1 (First 30 minutes in normal mode, or minute 1 in test mode): 100% LOCKED!
            if (dynamicCycleIndex == 0) {
                return false
            }
            return SessionStateHolder.whatsappAllowanceRemainingSec > 0
        }

        // Tier 3: AI Assistant Pool (5-Minute Pool Throughout)
        val isTier3 = SessionStateHolder.tier3Packages.contains(pkg) ||
                (SessionStateHolder.allowedPackages.contains(pkg) && (pkg.lowercase().contains("chatgpt") || pkg.lowercase().contains("bard") || pkg.lowercase().contains("claude"))) ||
                SessionStateHolder.AI_PACKAGES.contains(pkg) ||
                pkg.lowercase().contains("chatgpt") || pkg.lowercase().contains("bard") || pkg.lowercase().contains("claude")
        if (isTier3) {
            return SessionStateHolder.aiAllowanceRemainingSec > 0
        }

        // Tier 4: Secondary Tools (Phase 1 Locked 100%, Phase 2 Unlocks)
        val isTier4 = SessionStateHolder.tier4Packages.contains(pkg)
        if (isTier4) {
            // Phase 1 (First 30 minutes in normal mode, or minute 1 in test mode): 100% LOCKED!
            if (dynamicCycleIndex == 0) {
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
}
