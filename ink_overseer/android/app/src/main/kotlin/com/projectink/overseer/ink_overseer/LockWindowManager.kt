package com.projectink.overseer.ink_overseer

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class LockWindowManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private var isShowing = false

    private val quotes = listOf(
        "\"You can't edit a blank page. Go make words.\" — Jodi Picoult",
        "\"The scariest moment is always just before you start.\" — Stephen King",
        "\"Start writing, no matter what. The water does not flow until the faucet is turned on.\" — Louis L'Amour",
        "\"Amateurs sit and wait for inspiration, the rest of us just get up and go to work.\" — Stephen King",
        "\"Close the door. Write with no one looking over your shoulder.\" — C.J. Cherryh",
        "\"Your story matters. WhatsApp can wait; your characters cannot.\" — Focus Sanctum",
        "\"Discipline is choosing between what you want now and what you want most.\" — Abraham Lincoln"
    )

    fun showLock(appName: String, reason: String, timeRemainingStr: String) {
        if (isShowing && overlayView != null) {
            updateContent(appName, reason, timeRemainingStr)
            return
        }

        val windowLayoutParams = WindowManager.LayoutParams().apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1 && context is android.accessibilityservice.AccessibilityService) {
                WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            format = PixelFormat.TRANSLUCENT
            gravity = Gravity.CENTER
        }

        val rootLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0D1117"))
            setPadding(48, 80, 48, 80)
        }

        // Lock Icon / Shield
        val iconText = TextView(context).apply {
            text = "🛡️"
            textSize = 54f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }
        rootLayout.addView(iconText)

        // Title
        val titleText = TextView(context).apply {
            text = "FOCUS SANCTUM"
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#E5A93C")) // Parchment Gold
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }
        rootLayout.addView(titleText)

        // App Locked Label
        val appLabel = TextView(context).apply {
            id = View.generateViewId()
            tag = "app_label"
            text = "$appName is Locked"
            textSize = 20f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#F8FAFC"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 12)
        }
        rootLayout.addView(appLabel)

        // Reason description
        val reasonText = TextView(context).apply {
            id = View.generateViewId()
            tag = "reason_text"
            text = reason
            textSize = 15f
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setPadding(24, 0, 24, 24)
        }
        rootLayout.addView(reasonText)

        // Countdown / Cycle status
        val countdownText = TextView(context).apply {
            id = View.generateViewId()
            tag = "countdown_text"
            text = timeRemainingStr
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#EF4444")) // Crimson Alert
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 36)
        }
        rootLayout.addView(countdownText)

        // Motivational Card Container
        val quoteContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#161B22"))
                cornerRadius = 24f
                setStroke(2, Color.parseColor("#30363D"))
            }
            background = cardBg
            setPadding(32, 28, 32, 28)
        }

        val quoteText = TextView(context).apply {
            id = View.generateViewId()
            tag = "quote_text"
            text = quotes.random()
            textSize = 14f
            typeface = Typeface.create(Typeface.SERIF, Typeface.ITALIC)
            setTextColor(Color.parseColor("#E2E8F0"))
            gravity = Gravity.CENTER
        }
        quoteContainer.addView(quoteText)
        rootLayout.addView(quoteContainer)

        // Spacing
        val spacer = View(context)
        val spacerParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 48
        )
        rootLayout.addView(spacer, spacerParams)

        // Primary Hero Button: Return to Pure Writer
        val returnButton = Button(context).apply {
            text = "✍️  Return to Pure Writer"
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#0D1117"))
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#E5A93C")) // Gold
                cornerRadius = 24f
            }
            background = btnBg
            setPadding(40, 24, 40, 24)
            setOnClickListener {
                hideLock()
                launchPureWriter()
            }
        }
        rootLayout.addView(returnButton)

        try {
            windowManager.addView(rootLayout, windowLayoutParams)
            overlayView = rootLayout
            isShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateContent(appName: String, reason: String, timeRemainingStr: String) {
        overlayView?.let { view ->
            view.findViewWithTag<TextView>("app_label")?.text = "$appName is Locked"
            view.findViewWithTag<TextView>("reason_text")?.text = reason
            view.findViewWithTag<TextView>("countdown_text")?.text = timeRemainingStr
        }
    }

    fun hideLock() {
        if (isShowing && overlayView != null) {
            try {
                windowManager.removeView(overlayView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            overlayView = null
            isShowing = false
        }
    }

    fun isCurrentlyShowing(): Boolean = isShowing

    private fun launchPureWriter() {
        val pm = context.packageManager
        val pureWriterIntent = pm.getLaunchIntentForPackage("com.raincat.purewriter")
        if (pureWriterIntent != null) {
            pureWriterIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            context.startActivity(pureWriterIntent)
        } else {
            // Fallback to our own app dashboard if Pure Writer is not yet installed on this test device
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            context.startActivity(mainIntent)
        }
    }
}
