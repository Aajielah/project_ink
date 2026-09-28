package com.projectink.overseer.ink_overseer

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class FloatingHudManager(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var hudView: View? = null
    private var isShowing = false
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    @SuppressLint("ClickableViewAccessibility")
    fun showHud(sessionTimeStr: String, allowanceTimeStr: String?) {
        if (isShowing && hudView != null) {
            updateHud(sessionTimeStr, allowanceTimeStr)
            return
        }

        val layoutParams = WindowManager.LayoutParams().apply {
            width = WindowManager.LayoutParams.WRAP_CONTENT
            height = WindowManager.LayoutParams.WRAP_CONTENT
            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            format = PixelFormat.TRANSLUCENT
            gravity = Gravity.TOP or Gravity.END
            x = 24
            y = 120
        }

        val pillLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#E6161B22")) // Semi-transparent Obsidian
                cornerRadius = 32f
                setStroke(2, Color.parseColor("#E5A93C")) // Gold border
            }
            background = bg
            setPadding(28, 14, 28, 14)
            elevation = 12f
        }

        val sessionText = TextView(context).apply {
            tag = "hud_session_text"
            text = "⏳ $sessionTimeStr"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#F8FAFC"))
            setPadding(0, 0, if (allowanceTimeStr != null) 16 else 0, 0)
        }
        pillLayout.addView(sessionText)

        val allowanceText = TextView(context).apply {
            tag = "hud_allowance_text"
            text = allowanceTimeStr ?: ""
            visibility = if (allowanceTimeStr != null) View.VISIBLE else View.GONE
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#F59E0B")) // Amber
        }
        pillLayout.addView(allowanceText)

        // Make HUD draggable
        pillLayout.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams.x
                    initialY = layoutParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    layoutParams.x = initialX - (event.rawX - initialTouchX).toInt()
                    layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                    try {
                        windowManager.updateViewLayout(pillLayout, layoutParams)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            windowManager.addView(pillLayout, layoutParams)
            hudView = pillLayout
            isShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun updateHud(sessionTimeStr: String, allowanceTimeStr: String?) {
        hudView?.let { view ->
            val sessionText = view.findViewWithTag<TextView>("hud_session_text")
            val allowanceText = view.findViewWithTag<TextView>("hud_allowance_text")

            sessionText?.text = "⏳ $sessionTimeStr"
            if (allowanceTimeStr != null) {
                allowanceText?.text = " • $allowanceTimeStr"
                allowanceText?.visibility = View.VISIBLE
            } else {
                allowanceText?.visibility = View.GONE
            }
        }
    }

    fun hideHud() {
        if (isShowing && hudView != null) {
            try {
                windowManager.removeView(hudView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            hudView = null
            isShowing = false
        }
    }
}
