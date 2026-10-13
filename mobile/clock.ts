export const phases = [
  { label: 'fresh', color: '#4ADE80', range: '0–25%' },
  { label: 'flowing', color: '#FACC15', range: '25–50%' },
  { label: 'ticking', color: '#FB923C', range: '50–75%' },
  { label: 'closing', color: '#F87171', range: '75–100%' },
];

export type ShiftConfig = { actualWake: string; idealWake: string; enabled: boolean };
export const storageKey = 'driftShift';

export function timeMinutes(value: string): number | null {
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) return null;
  return Number(value.slice(0, 2)) * 60 + Number(value.slice(3));
}

export function createShift(actualWake: string, idealWake: string): ShiftConfig | null {
  if (timeMinutes(actualWake) === null || timeMinutes(idealWake) === null) return null;
  return { actualWake, idealWake, enabled: true };
}

export function parseStoredShift(raw: string | null): ShiftConfig | null {
  if (raw === null) return null;
  const value: unknown = JSON.parse(raw);
  if (typeof value !== 'object' || value === null ||
      !('actualWake' in value) || typeof value.actualWake !== 'string' ||
      !('idealWake' in value) || typeof value.idealWake !== 'string' ||
      !('enabled' in value) || typeof value.enabled !== 'boolean') {
    throw new Error('Saved time shift is invalid.');
  }
  const shift = createShift(value.actualWake, value.idealWake);
  if (!shift) throw new Error('Saved wake times are invalid.');
  return { ...shift, enabled: value.enabled };
}

export function offsetMinutes(shift: ShiftConfig): number {
  const actual = timeMinutes(shift.actualWake);
  const ideal = timeMinutes(shift.idealWake);
  if (actual === null || ideal === null) throw new Error('Invalid wake time.');
  const difference = actual - ideal;
  if (difference > 720) return difference - 1440;
  if (difference < -720) return difference + 1440;
  return difference;
}

export function formatOffset(minutes: number): string {
  const absolute = Math.abs(minutes);
  return `${minutes >= 0 ? '+' : '-'}${Math.floor(absolute / 60)}h ${String(absolute % 60).padStart(2, '0')}m`;
}

export function clockText(date: Date): string {
  const hour = date.getHours();
  return `${hour % 12 || 12}:${String(date.getMinutes()).padStart(2, '0')} ${hour < 12 ? 'AM' : 'PM'}`;
}

export function snapshot(now: Date, shift: ShiftConfig | null) {
  const seconds = now.getMinutes() * 60 + now.getSeconds();
  const percentage = seconds / 36;
  const phase = phases[Math.floor(seconds / 900)];
  const active = shift?.enabled ?? false;
  const offset = shift && active ? offsetMinutes(shift) : 0;
  return {
    percentage,
    displayPercentage: Math.floor(percentage),
    phase,
    minutesLeft: Math.ceil((3600 - seconds) / 60),
    clock: clockText(new Date(now.getTime() - offset * 60_000)),
    localClock: clockText(now),
    active,
    offset,
  };
}
