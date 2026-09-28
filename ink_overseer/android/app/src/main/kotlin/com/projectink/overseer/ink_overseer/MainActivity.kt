package com.projectink.overseer.ink_overseer

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.projectink.overseer/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissionsStatus" -> {
                    val status = mapOf(
                        "overlayEnabled" to checkOverlayPermission(),
                        "accessibilityEnabled" to checkAccessibilityPermission(),
                        "deviceAdminEnabled" to checkDeviceAdminPermission(),
                        "usageStatsEnabled" to checkUsageStatsPermission()
                    )
                    result.success(status)
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }

                "requestDeviceAdminPermission" -> {
                    val component = ComponentName(this, AntiUninstallAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
                        putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "Enable Device Administrator to prevent accidental or compulsive uninstallation during writing lockouts."
                        )
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "requestUsageStatsPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }

                "startSession" -> {
                    val durationMinutes = call.argument<Int>("durationMinutes") ?: 120
                    val isTestMode = call.argument<Boolean>("isTestMode") ?: false

                    val now = System.currentTimeMillis()
                    val durationMs = if (isTestMode) {
                        durationMinutes * 60 * 1000L // e.g. 5 minutes total
                    } else {
                        durationMinutes * 60 * 1000L // 60 to 180 minutes
                    }

                    SessionStateHolder.isSessionActive = true
                    SessionStateHolder.isTestMode = isTestMode
                    SessionStateHolder.totalSessionMinutes = durationMinutes
                    SessionStateHolder.sessionStartTimeMs = now
                    SessionStateHolder.sessionEndTimeMs = now + durationMs
                    SessionStateHolder.currentCycleIndex = 0

                    if (isTestMode) {
                        SessionStateHolder.aiAllowanceRemainingSec = 30 // 30 sec for rapid test
                        SessionStateHolder.whatsappAllowanceRemainingSec = 0 // locked in cycle 0
                        SessionStateHolder.utilityAllowanceRemainingSec = 0
                    } else {
                        SessionStateHolder.aiAllowanceRemainingSec = 300 // 5 mins
                        SessionStateHolder.whatsappAllowanceRemainingSec = 0 // locked in cycle 0
                        SessionStateHolder.utilityAllowanceRemainingSec = 0
                    }
                    SessionStateHolder.saveToPrefs(this)

                    // Start Watchdog Service
                    val serviceIntent = Intent(this, OverseerWatchdogService::class.java).apply {
                        action = OverseerWatchdogService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }

                    // Launch Pure Writer immediately
                    openPureWriter()

                    result.success(true)
                }

                "stopSession" -> {
                    val force = call.argument<Boolean>("force") ?: false
                    if (SessionStateHolder.isTestMode || force) {
                        val serviceIntent = Intent(this, OverseerWatchdogService::class.java).apply {
                            action = OverseerWatchdogService.ACTION_STOP
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } else {
                        result.error("LOCKED", "Active sessions cannot be stopped early in production mode.", null)
                    }
                }

                "getSessionState" -> {
                    SessionStateHolder.loadFromPrefs(this)
                    val now = System.currentTimeMillis()
                    val remainingSec = if (SessionStateHolder.isSessionActive && now < SessionStateHolder.sessionEndTimeMs) {
                        ((SessionStateHolder.sessionEndTimeMs - now) / 1000).toInt()
                    } else {
                        0
                    }

                    val state = mapOf(
                        "isSessionActive" to SessionStateHolder.isSessionActive,
                        "isTestMode" to SessionStateHolder.isTestMode,
                        "remainingSec" to remainingSec,
                        "currentCycleIndex" to SessionStateHolder.currentCycleIndex,
                        "aiAllowanceRemainingSec" to SessionStateHolder.aiAllowanceRemainingSec,
                        "whatsappAllowanceRemainingSec" to SessionStateHolder.whatsappAllowanceRemainingSec,
                        "utilityAllowanceRemainingSec" to SessionStateHolder.utilityAllowanceRemainingSec,
                        "totalSessionMinutes" to SessionStateHolder.totalSessionMinutes
                    )
                    result.success(state)
                }

                "openPureWriter" -> {
                    openPureWriter()
                    result.success(true)
                }

                "scheduleSessionAlarm" -> {
                    val triggerAtMs = call.argument<Long>("triggerAtMs") ?: 0L
                    scheduleAlarm(triggerAtMs)
                    result.success(true)
                }

                "cancelSessionAlarm" -> {
                    cancelAlarm()
                    result.success(true)
                }

                "launchPackage" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val success = launchPackage(pkg)
                    result.success(success)
                }

                "getInstalledApps" -> {
                    val list = getInstalledAppList()
                    result.success(list)
                }

                "setAllowedPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    SessionStateHolder.allowedPackages.clear()
                    SessionStateHolder.allowedPackages.add(packageName)
                    SessionStateHolder.allowedPackages.add("com.android.systemui")
                    SessionStateHolder.allowedPackages.addAll(packages)
                    SessionStateHolder.saveToPrefs(this)
                    result.success(true)
                }

                "getAllowedPackages" -> {
                    SessionStateHolder.loadFromPrefs(this)
                    result.success(SessionStateHolder.allowedPackages.toList())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun checkAccessibilityPermission(): Boolean {
        val expectedServiceName = "$packageName/${OverseerAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedServiceName, ignoreCase = true) ||
                componentName.contains(OverseerAccessibilityService::class.java.simpleName)) {
                return true
            }
        }
        return false
    }

    private fun checkDeviceAdminPermission(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, AntiUninstallAdminReceiver::class.java)
        return dpm.isAdminActive(adminComponent)
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openPureWriter() {
        val pm = packageManager
        val intent = pm.getLaunchIntentForPackage("com.raincat.purewriter")
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
        }
    }

    private fun scheduleAlarm(triggerAtMs: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SessionAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            2001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
        }
    }

    private fun cancelAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SessionAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            2001,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun launchPackage(pkgName: String): Boolean {
        val pm = packageManager
        var intent = pm.getLaunchIntentForPackage(pkgName)
        if (intent == null) {
            if (pkgName.contains("dialer") || pkgName.contains("phone")) {
                intent = Intent(Intent.ACTION_DIAL)
            } else if (pkgName.contains("messaging") || pkgName.contains("mms")) {
                intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_APP_MESSAGING)
                }
            }
        }
        return if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
            true
        } else {
            false
        }
    }

    private fun getInstalledAppList(): List<Map<String, String>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveList = pm.queryIntentActivities(mainIntent, 0)
        val appList = mutableListOf<Map<String, String>>()
        for (resolveInfo in resolveList) {
            val pkg = resolveInfo.activityInfo.packageName
            val label = resolveInfo.loadLabel(pm).toString()
            if (pkg != packageName) {
                appList.add(mapOf("packageName" to pkg, "displayName" to label))
            }
        }
        return appList.sortedBy { it["displayName"] }
    }
}
