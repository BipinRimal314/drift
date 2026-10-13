package expo.modules.drifttools

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.os.Bundle
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class DriftWidgetProvider : AppWidgetProvider() {
  override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = refresh(context)

  override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) = refresh(context)

  override fun onReceive(context: Context, intent: Intent) {
    super.onReceive(context, intent)
    if (intent.action in listOf(REFRESH, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) refresh(context)
  }

  override fun onDisabled(context: Context) {
    context.getSystemService(AlarmManager::class.java).cancel(refreshIntent(context))
  }

  override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    val remaining = AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, DriftWidgetProvider::class.java))
    if (remaining.none { it !in appWidgetIds }) onDisabled(context)
  }

  companion object {
    private const val REFRESH = "expo.modules.drifttools.REFRESH_WIDGET"

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(
      context, 0, Intent(context, DriftWidgetProvider::class.java).setAction(REFRESH),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    fun refresh(context: Context) {
      val manager = AppWidgetManager.getInstance(context)
      val ids = manager.getAppWidgetIds(ComponentName(context, DriftWidgetProvider::class.java))
      if (ids.isEmpty()) return
      val now = Calendar.getInstance()
      val reading = DriftClock.read(now)
      val timestamp = SimpleDateFormat("HH:mm", Locale.getDefault()).format(now.time)
      val views = RemoteViews(context.packageName, R.layout.drift_widget).apply {
        setTextViewText(R.id.drift_percentage, "${reading.percentage}%")
        setTextColor(R.id.drift_percentage, reading.color)
        setContentDescription(R.id.drift_percentage, "${reading.percentage} percent of this hour. Open Drift.")
        setTextViewText(R.id.drift_detail, "${reading.phase} · ${reading.minutesLeft} minutes left")
        setTextViewText(R.id.drift_refresh, "Updated $timestamp · Tap to refresh")
        setContentDescription(R.id.drift_refresh, "Updated at $timestamp. Tap to refresh the clock.")
        setOnClickPendingIntent(R.id.drift_refresh, refreshIntent(context))
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
          val open = PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
          setOnClickPendingIntent(R.id.drift_percentage, open)
          setOnClickPendingIntent(R.id.drift_title, open)
        }
      }
      manager.updateAppWidget(ids, views)
      // shortcut: Android can delay inexact updates, use the timestamp and manual refresh until a platform clock format is available.
      context.getSystemService(AlarmManager::class.java).set(
        AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 60_000, refreshIntent(context)
      )
    }
  }
}
