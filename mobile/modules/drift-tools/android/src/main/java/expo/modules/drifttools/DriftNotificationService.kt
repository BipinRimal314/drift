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
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import java.util.Calendar

class DriftNotificationService : Service() {
  private val handler = Handler(Looper.getMainLooper())
  private var receiverRegistered = false
  private val tick = object : Runnable {
    override fun run() {
      if (!canShow(this@DriftNotificationService)) {
        stopSelf()
        return
      }
      val now = Calendar.getInstance()
      try {
        getSystemService(NotificationManager::class.java).notify(ID, notification(DriftClock.read(now)))
      } catch (error: RuntimeException) {
        android.util.Log.e("DriftTools", "Cannot update status icon", error)
        stopSelf()
        return
      }
      if (getSystemService(PowerManager::class.java).isInteractive) {
        handler.postDelayed(this, DriftClock.nextUpdateDelay(now))
      }
    }
  }
  private val screenReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      handler.removeCallbacks(tick)
      if (intent.action != Intent.ACTION_SCREEN_OFF) tick.run()
    }
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    try {
      ensureChannel(this)
      startForeground(ID, notification(DriftClock.read()))
    } catch (error: RuntimeException) {
      android.util.Log.e("DriftTools", "Cannot show status icon", error)
      stopSelf()
      return START_NOT_STICKY
    }
    if (intent?.action == STOP || !canShow(this)) {
      stopSelf()
      return START_NOT_STICKY
    }
    if (running) return START_NOT_STICKY
    try {
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
      android.util.Log.e("DriftTools", "Cannot show status icon", error)
      stopSelf()
    }
    return START_NOT_STICKY
  }

  private val paint by lazy {
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = Color.WHITE
      typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
      textSize = 86f
      textAlign = Paint.Align.CENTER
    }
  }
  private val stopIntent by lazy {
    PendingIntent.getService(this, 1, Intent(this, DriftNotificationService::class.java).setAction(STOP), PendingIntent.FLAG_IMMUTABLE)
  }
  private val openIntent by lazy {
    packageManager.getLaunchIntentForPackage(packageName)?.let {
      PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
  }

  private fun notification(reading: DriftReading): Notification {
    val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
    Canvas(bitmap).drawText(reading.percentage.toString(), 48f, 48f - (paint.ascent() + paint.descent()) / 2, paint)
    val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this)
    return builder.setSmallIcon(Icon.createWithBitmap(bitmap))
      .setContentTitle("${reading.percentage}% of this hour")
      .setContentText("${reading.phase} · ${reading.minutesLeft} minutes left")
      .setContentIntent(openIntent)
      .setDeleteIntent(stopIntent)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setShowWhen(false)
      .setPriority(Notification.PRIORITY_LOW)
      .addAction(Notification.Action.Builder(null, "Stop status icon", stopIntent).build())
      .build()
  }

  override fun onDestroy() {
    running = false
    handler.removeCallbacksAndMessages(null)
    if (receiverRegistered) unregisterReceiver(screenReceiver)
    stopForeground(STOP_FOREGROUND_REMOVE)
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  companion object {
    const val CHANNEL = "drift-hour-percentage"
    private const val ID = 42
    private const val STOP = "expo.modules.drifttools.STOP_NOTIFICATION"
    @Volatile var running = false
      private set

    fun ensureChannel(context: Context) {
      if (Build.VERSION.SDK_INT < 26) return
      context.getSystemService(NotificationManager::class.java).createNotificationChannel(
        NotificationChannel(CHANNEL, "Hour percentage", NotificationManager.IMPORTANCE_LOW).apply {
          description = "Live percentage of the local hour in the status bar"
          setSound(null, null)
          enableVibration(false)
          setShowBadge(false)
        })
    }

    fun canShow(context: Context): Boolean {
      val manager = context.getSystemService(NotificationManager::class.java)
      if (Build.VERSION.SDK_INT >= 26 && (manager.getNotificationChannel(CHANNEL)?.importance ?: NotificationManager.IMPORTANCE_LOW) < NotificationManager.IMPORTANCE_LOW) return false
      return manager.areNotificationsEnabled()
    }
  }
}
