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

    // Hardcoded Iron Blacklist of Banned Distractions
    val BLACKLIST_PACKAGES = setOf(
        "com.google.android.youtube",
        "com.google.android.apps.youtube.music",
        "app.revanced.android.youtube",
        "com.instagram.android",
        "com.instagram.threadsapp",
        "com.zhiliaoapp.musically",
        "com.zhiliaoapp.musically.go",
        "com.ss.android.ugc.trill",
        "com.facebook.katana",
        "com.facebook.lite",
        "com.facebook.orca",
        "com.snapchat.android",
        "com.twitter.android",
        "com.twitter.android.lite",
        "com.reddit.frontpage",
        "com.netflix.mediaclient",
        "com.amazon.avod.thirdpartyclient"
    )

    fun isBlacklisted(pkg: String): Boolean {
        val lower = pkg.lowercase()
        if (BLACKLIST_PACKAGES.contains(lower)) return true
        if (lower.contains("youtube") ||
            lower.contains("instagram") ||
            lower.contains("tiktok") ||
            lower.contains("snapchat") ||
            lower.contains("facebook") ||
            lower.contains("reddit") ||
            lower.contains("netflix") ||
            lower.contains("twitter")) {
            return true
        }
        return false
    }

    // Tier 1: Writing Sanctuary (Unlimited 24/7)
    val tier1Packages: MutableSet<String> = mutableSetOf(
        PKG_OVERSEER,
        PKG_PURE_WRITER,
        "com.android.systemui"
    )

    // Tier 2: The Social Leash (Phase 1 Locked 100%, Phase 2 Metered)
    val tier2Packages: MutableSet<String> = mutableSetOf()

    // Tier 3: AI Assistant Pool (5-Minute Pool Throughout)
    val tier3Packages: MutableSet<String> = mutableSetOf()

    // Tier 4: Secondary Tools (Phase 1 Locked 100%, Phase 2 Unlocks)
    val tier4Packages: MutableSet<String> = mutableSetOf()

    // Combined allowed packages
    val allowedPackages: MutableSet<String> = mutableSetOf(
        PKG_OVERSEER,
        PKG_PURE_WRITER,
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

        tier1Packages.clear()
        tier1Packages.add(PKG_OVERSEER)
        tier1Packages.add(PKG_PURE_WRITER)
        tier1Packages.add("com.android.systemui")
        val savedT1 = prefs.getStringSet("tier1_packages_set", null)
        if (savedT1 != null) tier1Packages.addAll(savedT1)

        tier2Packages.clear()
        val savedT2 = prefs.getStringSet("tier2_packages_set", null)
        if (savedT2 != null) tier2Packages.addAll(savedT2)

        tier3Packages.clear()
        val savedT3 = prefs.getStringSet("tier3_packages_set", null)
        if (savedT3 != null) tier3Packages.addAll(savedT3)

        tier4Packages.clear()
        val savedT4 = prefs.getStringSet("tier4_packages_set", null)
        if (savedT4 != null) tier4Packages.addAll(savedT4)

        allowedPackages.clear()
        allowedPackages.addAll(tier1Packages)
        allowedPackages.addAll(tier2Packages)
        allowedPackages.addAll(tier3Packages)
        allowedPackages.addAll(tier4Packages)
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
            putStringSet("tier1_packages_set", tier1Packages)
            putStringSet("tier2_packages_set", tier2Packages)
            putStringSet("tier3_packages_set", tier3Packages)
            putStringSet("tier4_packages_set", tier4Packages)
            putStringSet("allowed_packages_set", allowedPackages)
            apply()
        }
    }
}
