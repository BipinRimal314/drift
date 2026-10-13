package expo.modules.drifttools

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import expo.modules.kotlin.functions.Coroutine
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
      mapOf("overlayEnabled" to (permission && DriftOverlayService.running), "overlayPermission" to permission)
    }
    AsyncFunction("requestOverlayPermission") {
      val activity = requireNotNull(appContext.currentActivity) { "Open Drift before changing this permission." }
      activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${activity.packageName}")))
    }.runOnQueue(expo.modules.kotlin.functions.Queues.MAIN)
    AsyncFunction("startOverlay") Coroutine { ->
      withContext(Dispatchers.Main) {
        val activity = requireNotNull(appContext.currentActivity) { "Open Drift before starting the floating display." }
        check(activity is androidx.lifecycle.LifecycleOwner &&
          activity.lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED)) {
          "Keep Drift open while starting the floating display."
        }
        check(Settings.canDrawOverlays(activity)) { "Allow display over other apps first." }
        val intent = Intent(activity, DriftOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent)
        else activity.startService(intent)
        val started = withTimeoutOrNull(3000) {
          while (!DriftOverlayService.running) delay(50)
          true
        } ?: false
        if (!started) {
          activity.stopService(intent)
          error("Android could not show the floating clock. Check the display permission and try again.")
        }
      }
    }
    AsyncFunction("stopOverlay") Coroutine { ->
      withContext(Dispatchers.Main) {
        val context = requireNotNull(appContext.reactContext) { "Drift is not active." }
        context.stopService(Intent(context, DriftOverlayService::class.java))
        check(withTimeoutOrNull(3000) {
          while (DriftOverlayService.running) delay(50)
          true
        } == true) { "Android could not stop the floating clock." }
      }
    }
    AsyncFunction("requestWidget") {
      val activity = requireNotNull(appContext.currentActivity) { "Open Drift before adding the widget." }
      val manager = AppWidgetManager.getInstance(activity)
      if (Build.VERSION.SDK_INT >= 26 && manager.isRequestPinAppWidgetSupported) {
        manager.requestPinAppWidget(ComponentName(activity, DriftWidgetProvider::class.java), null, null)
      } else false
    }.runOnQueue(expo.modules.kotlin.functions.Queues.MAIN)
  }
}
