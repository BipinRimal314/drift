import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  clockText, createShift, formatOffset, offsetMinutes, parseStoredShift, snapshot, timeMinutes,
} from '../clock.ts';

test('every quarter changes phase at its exact local boundary', () => {
  for (const [minute, second, percent, phase, left] of [
    [0, 0, 0, 'fresh', 60],
    [14, 59, 24, 'fresh', 46],
    [15, 0, 25, 'flowing', 45],
    [29, 59, 49, 'flowing', 31],
    [30, 0, 50, 'ticking', 30],
    [44, 59, 74, 'ticking', 16],
    [45, 0, 75, 'closing', 15],
    [59, 59, 99, 'closing', 1],
  ] satisfies [number, number, number, string, number][]) {
    const result = snapshot(new Date(2026, 9, 13, 23, minute, second), null);
    assert.equal(result.displayPercentage, percent);
    assert.equal(result.phase.label, phase);
    assert.equal(result.minutesLeft, left);
  }
  const midnight = snapshot(new Date(2026, 9, 14, 0, 0, 0), null);
  assert.equal(midnight.displayPercentage, 0);
  assert.equal(midnight.minutesLeft, 60);
  assert.equal(midnight.clock, '12:00 AM');
});

test('local timezone determines percentage, including fractional hour offsets', () => {
  const previous = process.env.TZ;
  try {
    process.env.TZ = 'Asia/Kathmandu';
    const result = snapshot(new Date('2026-10-13T00:00:00Z'), null);
    assert.equal(result.clock, '5:45 AM');
    assert.equal(result.displayPercentage, 75);
    assert.equal(result.phase.label, 'closing');
    process.env.TZ = 'America/New_York';
    const newYork = snapshot(new Date('2026-10-13T00:15:00Z'), null);
    assert.equal(newYork.clock, '8:15 PM');
    assert.equal(newYork.displayPercentage, 25);
  } finally {
    if (previous === undefined) delete process.env.TZ;
    else process.env.TZ = previous;
  }
});

test('wake times reject invalid external values', () => {
  for (const value of ['6:00', '24:00', '00:60', '12:3', '-1:00', ' 06:00', 'aa:bb', '']) {
    assert.equal(timeMinutes(value), null);
    assert.equal(createShift(value, '06:00'), null);
    assert.equal(createShift('06:00', value), null);
  }
  assert.equal(timeMinutes('00:00'), 0);
  assert.equal(timeMinutes('23:59'), 1439);
});

test('shift uses the shortest difference and preserves the local hour percentage', () => {
  for (const [actualWake, idealWake, offset] of [
    ['10:00', '06:00', 240],
    ['23:00', '01:00', -120],
    ['01:00', '23:00', 120],
    ['12:00', '00:00', 720],
    ['00:00', '12:00', -720],
    ['06:00', '06:00', 0],
  ] satisfies [string, string, number][]) {
    const shift = createShift(actualWake, idealWake);
    assert.ok(shift);
    assert.equal(offsetMinutes(shift), offset);
  }
  const shift = createShift('10:30', '06:00');
  assert.ok(shift);
  const now = new Date(2026, 9, 13, 2, 45, 30);
  const result = snapshot(now, shift);
  assert.equal(result.clock, '10:15 PM');
  assert.equal(result.localClock, '2:45 AM');
  assert.equal(result.displayPercentage, 75);
  assert.equal(result.percentage, 75 + 30 / 36);
  assert.equal(result.active, true);
  assert.equal(snapshot(now, { ...shift, enabled: false }).clock, '2:45 AM');
  assert.equal(snapshot(now, { ...shift, enabled: false }).active, false);
  assert.equal(formatOffset(270), '+4h 30m');
  assert.equal(formatOffset(-75), '-1h 15m');
});

test('stored settings round trip and reject malformed payloads without silent reset', () => {
  const shift = createShift('10:00', '06:00');
  assert.ok(shift);
  assert.deepEqual(parseStoredShift(JSON.stringify(shift)), shift);
  assert.deepEqual(parseStoredShift(JSON.stringify({ ...shift, enabled: false })), { ...shift, enabled: false });
  assert.equal(parseStoredShift(null), null);
  for (const raw of ['{', '{}', 'null', '[]', 'true',
    '{"actualWake":"24:00","idealWake":"06:00","enabled":true}',
    '{"actualWake":"10:00","idealWake":"06:00","enabled":"true"}',
  ]) assert.throws(() => parseStoredShift(raw));
});

test('clock text handles noon and midnight', () => {
  assert.equal(clockText(new Date(2026, 9, 13, 0, 5)), '12:05 AM');
  assert.equal(clockText(new Date(2026, 9, 13, 12, 0)), '12:00 PM');
  assert.equal(clockText(new Date(2026, 9, 13, 23, 59)), '11:59 PM');
});
