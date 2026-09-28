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

        val sessionRemainingSec = ((SessionStateHolder.sessionEndTimeMs - now) / 1000).coerceAtLeast(0).toInt()
        val sessionRemainingStr = formatTime(sessionRemainingSec)

        // 1. Unconditional Whitelist (Essential services, writing sanctuary, launchers)
        if (isUnconditionallyAllowed(packageName)) {
            mainHandler.post {
                lockWindowManager.hideLock()
                floatingHudManager.showHud(sessionRemainingStr, null)
            }
            return
        }

        // 2. AI Apps Pool (ChatGPT, Gemini, Claude)
        if (SessionStateHolder.AI_PACKAGES.contains(packageName)) {
            val aiSec = SessionStateHolder.aiAllowanceRemainingSec
            if (aiSec > 0) {
                mainHandler.post {
                    lockWindowManager.hideLock()
                    floatingHudManager.showHud(sessionRemainingStr, "🤖 ${formatTime(aiSec)}")
                }
            } else {
                mainHandler.post {
                    floatingHudManager.hideHud()
                    lockWindowManager.showLock(
                        "AI Writing Assistant",
                        "Your 5-minute AI brainstorming allowance for this block has been used up.",
                        "Refreshes in next 30m block • Session: $sessionRemainingStr"
                    )
                }
            }
            return
        }

        // 3. WhatsApp Metered Leash
        if (SessionStateHolder.WHATSAPP_PACKAGES.contains(packageName)) {
            if (SessionStateHolder.currentCycleIndex == 0) {
                // First 30 minutes: 100% Locked
                mainHandler.post {
                    floatingHudManager.hideHud()
                    lockWindowManager.showLock(
                        "WhatsApp",
                        "WhatsApp is strictly locked during your first 30 minutes of deep writing.",
                        "Unlocks in min 31 • Session: $sessionRemainingStr"
                    )
                }
            } else {
                val waSec = SessionStateHolder.whatsappAllowanceRemainingSec
                if (waSec > 0) {
                    mainHandler.post {
                        lockWindowManager.hideLock()
                        floatingHudManager.showHud(sessionRemainingStr, "💬 ${formatTime(waSec)}")
                    }
                } else {
                    mainHandler.post {
                        floatingHudManager.hideHud()
                        lockWindowManager.showLock(
                            "WhatsApp",
                            "WhatsApp allowance exhausted for this 30-minute block.",
                            "Refreshes in next block • Session: $sessionRemainingStr"
                        )
                    }
                }
            }
            return
        }

        // 4. Utility / Browsers / Novel Apps Pool
        if (SessionStateHolder.UTILITY_PACKAGES.contains(packageName)) {
            if (SessionStateHolder.currentCycleIndex == 0) {
                mainHandler.post {
                    floatingHudManager.hideHud()
                    lockWindowManager.showLock(
                        "Browser & Utility Apps",
                        "Web and secondary apps are locked during the first 30 minutes of deep focus.",
                        "Unlocks in min 31 • Session: $sessionRemainingStr"
                    )
                }
            } else {
                val utilSec = SessionStateHolder.utilityAllowanceRemainingSec
                if (utilSec > 0) {
                    mainHandler.post {
                        lockWindowManager.hideLock()
                        floatingHudManager.showHud(sessionRemainingStr, "🌐 ${formatTime(utilSec)}")
                    }
                } else {
                    mainHandler.post {
                        floatingHudManager.hideHud()
                        lockWindowManager.showLock(
                            "Browser & Utility Apps",
                            "Your 5-minute research pool is exhausted for this block.",
                            "Refreshes in next block • Session: $sessionRemainingStr"
                        )
                    }
                }
            }
            return
        }

        // 5. Default: Any unauthorized app or blacklisted social/video apps (YouTube, Reels, Games, etc.)
        mainHandler.post {
            floatingHudManager.hideHud()
            lockWindowManager.showLock(
                packageName,
                "This app is not permitted during your writing lock. Distractions are forbidden.",
                "Session remaining: $sessionRemainingStr"
            )
        }
    }

    private fun isUnconditionallyAllowed(pkg: String): Boolean {
        // Our app
        if (pkg == SessionStateHolder.PKG_OVERSEER) return true
        // Pure Writer (Sanctuary)
        if (pkg == SessionStateHolder.PKG_PURE_WRITER) return true
        // Android System UI
        if (pkg == "com.android.systemui") return true
        // Google Docs
        if (pkg == "com.google.android.apps.docs.editors.docs") return true

        // Quran apps (common package patterns)
        if (pkg.contains("quran", ignoreCase = true)) return true

        // Phone / Dialer / Call in progress
        if (pkg.contains("dialer", ignoreCase = true) ||
            pkg.contains("telecom", ignoreCase = true) ||
            pkg.contains("phone", ignoreCase = true) ||
            pkg.contains("incall", ignoreCase = true)) {
            return true
        }

        // SMS / Messaging
        if (pkg.contains("mms", ignoreCase = true) ||
            pkg == "com.google.android.apps.messaging" ||
            pkg == "com.samsung.android.messaging") {
            return true
        }

        // Check if package is the device's default launcher (Home Screen)
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val defaultLauncher = packageManager.resolveActivity(homeIntent, 0)?.activityInfo?.packageName
        if (pkg == defaultLauncher) return true

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
