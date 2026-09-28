package com.projectink.overseer.ink_overseer

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class AntiUninstallAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Overseer Device Administrator Enabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        val prefs = context.getSharedPreferences("OverseerPrefs", Context.MODE_PRIVATE)
        val isSessionActive = prefs.getBoolean("is_session_active", false)
        if (isSessionActive) {
            return "A writing session is currently locked! You cannot disable the Administrator until your scheduled session finishes."
        }
        return "Disabling device administrator will remove anti-procrastination protection."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Overseer Device Administrator Disabled", Toast.LENGTH_SHORT).show()
    }
}
