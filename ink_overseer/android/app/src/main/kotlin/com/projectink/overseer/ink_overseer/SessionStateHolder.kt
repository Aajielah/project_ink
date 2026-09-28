package com.projectink.overseer.ink_overseer

import android.content.Context
import android.content.SharedPreferences

object SessionStateHolder {

    const val PREFS_NAME = "OverseerPrefs"

    var isSessionActive: Boolean = false
    var isTestMode: Boolean = false
    var sessionStartTimeMs: Long = 0L
    var sessionEndTimeMs: Long = 0L
    var totalSessionMinutes: Int = 120

    // Allowances in seconds
    var aiAllowanceRemainingSec: Int = 300 // 5 mins
    var whatsappAllowanceRemainingSec: Int = 0 // unlocked after 30m
    var utilityAllowanceRemainingSec: Int = 0 // unlocked after 30m

    var currentCycleIndex: Int = 0 // 0 = first 30m, 1 = 31-60m, etc.
    var currentForegroundPackage: String = ""

    // Packages
    const val PKG_OVERSEER = "com.projectink.overseer.ink_overseer"
    const val PKG_PURE_WRITER = "com.raincat.purewriter"
    val WHATSAPP_PACKAGES = setOf("com.whatsapp", "com.whatsapp.w4b")
    val AI_PACKAGES = setOf("com.google.android.apps.bard", "com.openai.chatgpt", "com.anthropic.claude")
    val UTILITY_PACKAGES = setOf(
        "com.android.chrome", "com.brave.browser", "com.android.email",
        "com.google.android.gm", "com.android.settings", "com.meganovel",
        "com.webnovel", "com.clone.master"
    )

    // Whitelisted apps selected by the user for strict focus
    val allowedPackages: MutableSet<String> = mutableSetOf(
        PKG_OVERSEER,
        "com.android.systemui"
    )

    fun loadFromPrefs(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        isSessionActive = prefs.getBoolean("is_session_active", false)
        isTestMode = prefs.getBoolean("is_test_mode", false)
        sessionStartTimeMs = prefs.getLong("session_start_time_ms", 0L)
        sessionEndTimeMs = prefs.getLong("session_end_time_ms", 0L)
        totalSessionMinutes = prefs.getInt("total_session_minutes", 120)
        aiAllowanceRemainingSec = prefs.getInt("ai_allowance_remaining_sec", 300)
        whatsappAllowanceRemainingSec = prefs.getInt("whatsapp_allowance_remaining_sec", 0)
        utilityAllowanceRemainingSec = prefs.getInt("utility_allowance_remaining_sec", 0)
        currentCycleIndex = prefs.getInt("current_cycle_index", 0)

        val savedAllowed = prefs.getStringSet("allowed_packages_set", null)
        allowedPackages.clear()
        allowedPackages.add(PKG_OVERSEER)
        allowedPackages.add("com.android.systemui")
        if (savedAllowed != null) {
            allowedPackages.addAll(savedAllowed)
        }
    }

    fun saveToPrefs(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putBoolean("is_session_active", isSessionActive)
            putBoolean("is_test_mode", isTestMode)
            putLong("session_start_time_ms", sessionStartTimeMs)
            putLong("session_end_time_ms", sessionEndTimeMs)
            putInt("total_session_minutes", totalSessionMinutes)
            putInt("ai_allowance_remaining_sec", aiAllowanceRemainingSec)
            putInt("whatsapp_allowance_remaining_sec", whatsappAllowanceRemainingSec)
            putInt("utility_allowance_remaining_sec", utilityAllowanceRemainingSec)
            putInt("current_cycle_index", currentCycleIndex)
            putStringSet("allowed_packages_set", allowedPackages)
            apply()
        }
    }
}
