package expo.modules.drifttools

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class DriftClockTest {
  @Test fun updateAtPercentageAndMinuteBoundaries() {
    val calendar = Calendar.getInstance(TimeZone.getTimeZone("Asia/Kathmandu"))
    calendar.set(2026, Calendar.OCTOBER, 13, 9, 0, 0)
    calendar.set(Calendar.MILLISECOND, 0)
    assertEquals(36_000L, DriftClock.nextUpdateDelay(calendar))
    calendar.set(Calendar.SECOND, 36)
    assertEquals(24_000L, DriftClock.nextUpdateDelay(calendar))
    calendar.set(Calendar.MINUTE, 59)
    calendar.set(Calendar.SECOND, 59)
    calendar.set(Calendar.MILLISECOND, 999)
    assertEquals(1L, DriftClock.nextUpdateDelay(calendar))
    calendar.add(Calendar.MILLISECOND, 1)
    assertEquals(0, DriftClock.read(calendar).percentage)
    assertEquals(36_000L, DriftClock.nextUpdateDelay(calendar))
  }

  @Test fun localHourBoundaries() {
    val calendar = Calendar.getInstance(TimeZone.getTimeZone("Asia/Kathmandu"))
    calendar.set(2026, Calendar.OCTOBER, 13, 9, 0, 0)
    assertEquals(DriftReading(0, "fresh", 0xFF4ADE80.toInt(), 60), DriftClock.read(calendar))
    calendar.set(Calendar.MINUTE, 15)
    assertEquals(DriftReading(25, "flowing", 0xFFFACC15.toInt(), 45), DriftClock.read(calendar))
    calendar.set(Calendar.MINUTE, 30)
    assertEquals(DriftReading(50, "ticking", 0xFFFB923C.toInt(), 30), DriftClock.read(calendar))
    calendar.set(Calendar.MINUTE, 45)
    assertEquals(DriftReading(75, "closing", 0xFFF87171.toInt(), 15), DriftClock.read(calendar))
    calendar.set(Calendar.MINUTE, 59)
    calendar.set(Calendar.SECOND, 59)
    assertEquals(DriftReading(99, "closing", 0xFFF87171.toInt(), 1), DriftClock.read(calendar))
    calendar.add(Calendar.SECOND, 1)
    assertEquals(DriftReading(0, "fresh", 0xFF4ADE80.toInt(), 60), DriftClock.read(calendar))
  }
}
