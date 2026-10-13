package expo.modules.drifttools

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs

class DriftOverlayService : Service() {
  private val handler = Handler(Looper.getMainLooper())
  private lateinit var manager: WindowManager
  private lateinit var layout: WindowManager.LayoutParams
  private var capsule: LinearLayout? = null
  private var percentage: TextView? = null
  private var receiverRegistered = false

  private val tick = object : Runnable {
    override fun run() {
      if (!Settings.canDrawOverlays(this@DriftOverlayService)) {
        stopSelf()
        return
      }
      if (!getSystemService(PowerManager::class.java).isInteractive) return
      val reading = DriftClock.read()
      percentage?.apply {
        text = "${reading.percentage}%"
        setTextColor(reading.color)
        contentDescription = "${reading.percentage} percent of this hour, ${reading.phase}, ${reading.minutesLeft} minutes left. Tap to open Drift. Drag to move."
      }
      handler.postDelayed(this, 1000)
    }
  }

  private val screenReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      handler.removeCallbacks(tick)
      if (intent.action != Intent.ACTION_SCREEN_OFF) tick.run()
    }
  }

  override fun onCreate() {
    super.onCreate()
    manager = getSystemService(WindowManager::class.java)
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    try {
      startForeground(ID, notification())
    } catch (error: RuntimeException) {
      android.util.Log.e("DriftTools", "Cannot show floating clock", error)
      stopSelf()
      return START_NOT_STICKY
    }
    if (intent?.action == STOP || !Settings.canDrawOverlays(this)) {
      stopSelf()
      return START_NOT_STICKY
    }
    if (capsule != null) return START_NOT_STICKY
    try {
      showCapsule()
      val filter = IntentFilter().apply {
        addAction(Intent.ACTION_SCREEN_ON)
        addAction(Intent.ACTION_SCREEN_OFF)
        addAction(Intent.ACTION_TIME_CHANGED)
        addAction(Intent.ACTION_TIMEZONE_CHANGED)
      }
      if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
      else registerReceiver(screenReceiver, filter)
      receiverRegistered = true
      running = true
      tick.run()
    } catch (error: RuntimeException) {
      android.util.Log.e("DriftTools", "Cannot show floating clock", error)
      stopSelf()
    }
    return START_NOT_STICKY
  }

  private fun notification(): Notification {
    if (Build.VERSION.SDK_INT >= 26) getSystemService(NotificationManager::class.java).createNotificationChannel(
        NotificationChannel(CHANNEL, "Drift floating clock", NotificationManager.IMPORTANCE_LOW)
      )
    val stop = PendingIntent.getService(this, 0, Intent(this, DriftOverlayService::class.java).setAction(STOP), PendingIntent.FLAG_IMMUTABLE)
    val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
    return builder
      .setSmallIcon(R.drawable.drift_notification)
      .setContentTitle("Drift floating clock is on")
      .setContentText("Drag the clock to move it. Tap × or Stop to close it.")
      .setOngoing(true)
      .setContentIntent(openIntent())
      .addAction(Notification.Action.Builder(null, "Stop", stop).build())
      .build()
  }

  private fun openIntent(): PendingIntent? = packageManager.getLaunchIntentForPackage(packageName)?.let {
    PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
  }

  private fun showCapsule() {
    val prefs = getSharedPreferences("driftOverlay", MODE_PRIVATE)
    layout = WindowManager.LayoutParams(
      WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.WRAP_CONTENT,
      if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE,
      WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
      PixelFormat.TRANSLUCENT
    ).apply {
      gravity = Gravity.TOP or Gravity.LEFT
      x = prefs.getInt("x", dp(12))
      y = prefs.getInt("y", dp(12))
      if (Build.VERSION.SDK_INT >= 28) layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
    }
    val container = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      background = GradientDrawable().apply {
        setColor(Color.rgb(18, 18, 18))
        cornerRadius = dp(28).toFloat()
        setStroke(dp(1), Color.rgb(90, 90, 90))
      }
      elevation = dp(6).toFloat()
    }
    percentage = TextView(this).apply {
      textSize = 24f
      typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
      setPadding(dp(16), 0, dp(12), 0)
      gravity = Gravity.CENTER
      minHeight = dp(48)
      isClickable = true
      setOnClickListener { openIntent()?.send() }
    }
    container.addView(percentage)
    container.addView(TextView(this).apply {
      text = "×"
      textSize = 24f
      setTextColor(Color.WHITE)
      gravity = Gravity.CENTER
      contentDescription = "Close Drift floating clock"
      isClickable = true
      setOnClickListener { stopSelf() }
    }, LinearLayout.LayoutParams(dp(48), dp(48)))
    attachDrag(requireNotNull(percentage))
    capsule = container
    manager.addView(container, layout)
    container.post { clampPosition() }
  }

  private fun attachDrag(view: TextView) {
    var downX = 0f
    var downY = 0f
    var initialX = 0
    var initialY = 0
    var dragging = false
    val slop = ViewConfiguration.get(this).scaledTouchSlop
    view.setOnTouchListener { target, event ->
      when (event.actionMasked) {
        MotionEvent.ACTION_DOWN -> {
          downX = event.rawX
          downY = event.rawY
          initialX = layout.x
          initialY = layout.y
          dragging = false
          true
        }
        MotionEvent.ACTION_MOVE -> {
          val deltaX = event.rawX - downX
          val deltaY = event.rawY - downY
          if (abs(deltaX) > slop || abs(deltaY) > slop) dragging = true
          if (dragging) {
            layout.x = initialX + deltaX.toInt()
            layout.y = initialY + deltaY.toInt()
            clampPosition()
          }
          true
        }
        MotionEvent.ACTION_UP -> {
          if (!dragging) target.performClick()
          else getSharedPreferences("driftOverlay", MODE_PRIVATE).edit().putInt("x", layout.x).putInt("y", layout.y).apply()
          true
        }
        MotionEvent.ACTION_CANCEL -> true
        else -> false
      }
    }
  }

  private fun clampPosition() {
    val view = capsule ?: return
    val usable = if (Build.VERSION.SDK_INT >= 30) {
      val metrics = manager.currentWindowMetrics
      val insets = metrics.windowInsets.getInsetsIgnoringVisibility(
        android.view.WindowInsets.Type.systemBars() or android.view.WindowInsets.Type.displayCutout()
      )
      Rect(0, 0, metrics.bounds.width() - insets.left - insets.right, metrics.bounds.height() - insets.top - insets.bottom)
    } else Rect().apply { manager.defaultDisplay.getRectSize(this) }
    layout.x = layout.x.coerceIn(0, (usable.width() - view.width).coerceAtLeast(0))
    layout.y = layout.y.coerceIn(0, (usable.height() - view.height).coerceAtLeast(0))
    try {
      manager.updateViewLayout(view, layout)
    } catch (error: RuntimeException) {
      android.util.Log.e("DriftTools", "Floating clock window became unavailable", error)
      stopSelf()
    }
  }

  override fun onConfigurationChanged(newConfig: Configuration) {
    super.onConfigurationChanged(newConfig)
    capsule?.post { clampPosition() }
  }

  override fun onDestroy() {
    running = false
    handler.removeCallbacksAndMessages(null)
    if (receiverRegistered) unregisterReceiver(screenReceiver)
    capsule?.let { view -> if (view.isAttachedToWindow) manager.removeView(view) }
    capsule = null
    percentage = null
    stopForeground(STOP_FOREGROUND_REMOVE)
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null
  private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

  companion object {
    @Volatile var running = false
      private set
    private const val ID = 41
    private const val CHANNEL = "drift-floating-clock"
    private const val STOP = "expo.modules.drifttools.STOP_OVERLAY"
  }
}
