package com.projectink.project_ink

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.projectink.project_ink/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val iconName = call.argument<String>("iconName") ?: "pen"
                    try {
                        val pm = packageManager
                        val pkgName = packageName
                        val penAlias = ComponentName(pkgName, "$pkgName.MainActivityAliasPen")
                        val bottleAlias = ComponentName(pkgName, "$pkgName.MainActivityAliasBottle")

                        if (iconName == "bottle") {
                            pm.setComponentEnabledSetting(
                                bottleAlias,
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )
                            pm.setComponentEnabledSetting(
                                penAlias,
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        } else {
                            pm.setComponentEnabledSetting(
                                penAlias,
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                                PackageManager.DONT_KILL_APP
                            )
                            pm.setComponentEnabledSetting(
                                bottleAlias,
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getCurrentIcon" -> {
                    try {
                        val pm = packageManager
                        val pkgName = packageName
                        val bottleAlias = ComponentName(pkgName, "$pkgName.MainActivityAliasBottle")
                        val state = pm.getComponentEnabledSetting(bottleAlias)
                        if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                            result.success("bottle")
                        } else {
                            result.success("pen")
                        }
                    } catch (e: Exception) {
                        result.success("pen")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
