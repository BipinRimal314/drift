package expo.modules.drifttools

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.functions.Queues
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class DriftToolsModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("DriftTools")

    AsyncFunction("getState") {
      val context = requireNotNull(appContext.reactContext) { "Drift is not active." }
      val permission = Settings.canDrawOverlays(context)
      if (!permission && DriftOverlayService.running) context.stopService(Intent(context, DriftOverlayService::class.java))
      val notificationPermission = DriftNotificationService.canShow(context)
      if (!notificationPermission && DriftNotificationService.running) context.stopService(Intent(context, DriftNotificationService::class.java))
      mapOf("overlayEnabled" to (permission && DriftOverlayService.running), "overlayPermission" to permission,
        "notificationEnabled" to (notificationPermission && DriftNotificationService.running), "notificationPermission" to notificationPermission)
    }
    AsyncFunction("requestOverlayPermission") {
      val activity = requireNotNull(appContext.currentActivity) { "Open Drift before changing this permission." }
      activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${activity.packageName}")))
    }.runOnQueue(Queues.MAIN)
    AsyncFunction("startOverlay") Coroutine { ->
      startTool(DriftOverlayService::class.java, { DriftOverlayService.running }, { Settings.canDrawOverlays(it) },
        "Open Drift before starting the floating display.", "Keep Drift open while starting the floating display.",
        "Allow display over other apps first.", "Android could not show the floating clock. Check the display permission and try again.")
    }
    AsyncFunction("stopOverlay") Coroutine { ->
      stopTool(DriftOverlayService::class.java, { DriftOverlayService.running }, "Android could not stop the floating clock.")
    }
    AsyncFunction("openNotificationSettings") {
      val activity = requireNotNull(appContext.currentActivity) { "Open Drift before changing notification settings." }
      DriftNotificationService.ensureChannel(activity)
      val intent = if (Build.VERSION.SDK_INT >= 26) {
        val appEnabled = activity.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
        Intent(if (appEnabled) Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS else Settings.ACTION_APP_NOTIFICATION_SETTINGS)
          .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
          .putExtra(Settings.EXTRA_CHANNEL_ID, DriftNotificationService.CHANNEL)
      } else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
      activity.startActivity(intent)
    }.runOnQueue(Queues.MAIN)
    AsyncFunction("startNotification") Coroutine { ->
      startTool(DriftNotificationService::class.java, { DriftNotificationService.running },
        { DriftNotificationService.ensureChannel(it); DriftNotificationService.canShow(it) },
        "Open Drift before starting the status icon.", "Keep Drift open while starting the status icon.",
        "Allow the Hour percentage notification first.", "Android could not show the status icon. Check notification settings and try again.")
    }
    AsyncFunction("stopNotification") Coroutine { ->
      stopTool(DriftNotificationService::class.java, { DriftNotificationService.running }, "Android could not stop the status icon.")
    }
    AsyncFunction("requestWidget") {
      val activity = requireNotNull(appContext.currentActivity) { "Open Drift before adding the widget." }
      val manager = AppWidgetManager.getInstance(activity)
      if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported) {
        manager.requestPinAppWidget(ComponentName(activity, DriftWidgetProvider::class.java), null, null)
      } else false
    }.runOnQueue(Queues.MAIN)
  }

  private suspend fun startTool(
    service: Class<*>, running: () -> Boolean, allowed: (Context) -> Boolean,
    openFirst: String, keepOpen: String, notAllowed: String, failed: String,
  ) {
    withContext(Dispatchers.Main) {
      val activity = requireNotNull(appContext.currentActivity) { openFirst }
      check(activity is androidx.lifecycle.LifecycleOwner &&
        activity.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED)) { keepOpen }
      check(allowed(activity)) { notAllowed }
      val intent = Intent(activity, service)
      if (Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent)
      else activity.startService(intent)
      val started = withTimeoutOrNull(3000) {
        while (!running()) delay(50)
        true
      } ?: false
      if (!started) {
        activity.stopService(intent)
        error(failed)
      }
    }
  }

  private suspend fun stopTool(service: Class<*>, running: () -> Boolean, failed: String) {
    withContext(Dispatchers.Main) {
      val context = requireNotNull(appContext.reactContext) { "Drift is not active." }
      context.stopService(Intent(context, service))
      check(withTimeoutOrNull(3000) {
        while (running()) delay(50)
        true
      } == true) { failed }
    }
  }
}
