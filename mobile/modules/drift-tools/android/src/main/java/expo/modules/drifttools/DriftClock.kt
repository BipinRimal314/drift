package expo.modules.drifttools

import java.util.Calendar

data class DriftReading(val percentage: Int, val phase: String, val color: Int, val minutesLeft: Int)

internal object DriftClock {
  private val labels = listOf("fresh", "flowing", "ticking", "closing")
  private val colors = listOf(0xFF4ADE80.toInt(), 0xFFFACC15.toInt(), 0xFFFB923C.toInt(), 0xFFF87171.toInt())

  fun nextUpdateDelay(calendar: Calendar): Long {
    val milliseconds = (calendar.get(Calendar.MINUTE) * 60L + calendar.get(Calendar.SECOND)) * 1000 + calendar.get(Calendar.MILLISECOND)
    return minOf(36_000 - milliseconds % 36_000, 60_000 - milliseconds % 60_000)
  }

  fun read(calendar: Calendar = Calendar.getInstance()): DriftReading {
    val seconds = calendar.get(Calendar.MINUTE) * 60 + calendar.get(Calendar.SECOND)
    val phase = seconds / 900
    return DriftReading(seconds / 36, labels[phase], colors[phase], (3600 - seconds + 59) / 60)
  }
}
