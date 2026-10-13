import { useEffect, useState } from 'react';
import {
  AppState, KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView,
  StyleSheet, Text, TextInput, View, useWindowDimensions,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useFonts } from 'expo-font';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Circle, Line } from 'react-native-svg';
import OutsideClock from './OutsideClock';
import {
  createShift, formatOffset, offsetMinutes, parseStoredShift, phases, snapshot, storageKey,
  type ShiftConfig,
} from './clock';

export default function App() {
  return <SafeAreaProvider><Drift /></SafeAreaProvider>;
}

function Drift() {
  const [fontsLoaded, fontError] = useFonts({
    Space: require('./assets/fonts/SpaceGrotesk-Regular.ttf'),
    SpaceMedium: require('./assets/fonts/SpaceGrotesk-Medium.ttf'),
    Mono: require('./assets/fonts/JetBrainsMono-Light.ttf'),
  });
  const [now, setNow] = useState(() => new Date());
  const [shift, setShift] = useState<ShiftConfig | null>(null);
  const [ready, setReady] = useState(false);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [sheet, setSheet] = useState<'info' | 'shift' | 'outside' | null>(null);
  const [actualWake, setActualWake] = useState('10:00');
  const [idealWake, setIdealWake] = useState('06:00');
  const [formError, setFormError] = useState<string | null>(null);
  const { width, height } = useWindowDimensions();
  const clock = snapshot(now, shift);
  const ringSize = Math.max(180, Math.min(width - 64, height * 0.46, 340));
  const preview = createShift(actualWake, idealWake);
  const useCustomFonts = fontsLoaded && !fontError;
  const bodyFont = useCustomFonts ? { fontFamily: 'Space' } : undefined;
  const monoFont = useCustomFonts ? { fontFamily: 'Mono' } : undefined;

  useEffect(() => {
    let mounted = true;
    AsyncStorage.getItem(storageKey)
      .then(raw => {
        const saved = parseStoredShift(raw);
        if (mounted) setShift(saved);
      })
      .catch(() => {
        if (mounted) setNotice('Your saved time shift could not be loaded. Set it again to save a new shift.');
      })
      .finally(() => { if (mounted) setReady(true); });
    return () => { mounted = false; };
  }, []);

  useEffect(() => {
    let timer: ReturnType<typeof setInterval> | undefined;
    function updateTimer() {
      if (timer) clearInterval(timer);
      timer = undefined;
      if (AppState.currentState === 'active') {
        setNow(new Date());
        timer = setInterval(() => setNow(new Date()), 1000);
      }
    }
    updateTimer();
    const subscription = AppState.addEventListener('change', updateTimer);
    return () => { if (timer) clearInterval(timer); subscription.remove(); };
  }, []);

  async function saveShift(next: ShiftConfig) {
    if (saving || !ready) return;
    setSaving(true);
    setFormError(null);
    try {
      await AsyncStorage.setItem(storageKey, JSON.stringify(next));
      setShift(next);
      setNotice(null);
      setSheet(null);
    } catch {
      setFormError('Could not save the time shift. Your current setting has not changed. Try again.');
    } finally {
      setSaving(false);
    }
  }

  function openShift() {
    setActualWake(shift?.actualWake ?? '10:00');
    setIdealWake(shift?.idealWake ?? '06:00');
    setFormError(null);
    setSheet('shift');
  }

  const closeSheet = () => { if (!saving) setSheet(null); };
  const circumference = 2 * Math.PI * 43;

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar style="light" />
      <ScrollView contentContainerStyle={styles.page}>
        <View style={styles.header}>
          <Text style={[styles.brand, useCustomFonts && { fontFamily: 'SpaceMedium' }]}>drift<Text style={{ color: clock.phase.color }}>.</Text></Text>
          <Text style={[styles.eyebrow, bodyFont]}>A DIFFERENT KIND OF CLOCK</Text>
        </View>
        <View style={styles.clockArea}>
          <Text style={[styles.eyebrow, bodyFont]}>THIS HOUR</Text>
          <View style={{ width: ringSize, height: ringSize, marginVertical: 24 }}
            accessible accessibilityRole="progressbar"
            accessibilityValue={{ min: 0, max: 100, now: clock.displayPercentage }}
            accessibilityLabel={`${clock.displayPercentage} percent of this hour complete. ${clock.phase.label}. ${clock.minutesLeft} minutes left.`}>
            <Svg width={ringSize} height={ringSize} viewBox="0 0 100 100" accessible={false}>
              <Circle cx="50" cy="50" r="43" fill="none" stroke="#18181B" strokeWidth="2.2" />
              <Circle cx="50" cy="50" r="43" fill="none" stroke={clock.phase.color} strokeWidth="2.2"
                strokeLinecap="round" strokeDasharray={`${circumference} ${circumference}`}
                strokeDashoffset={circumference * (1 - clock.percentage / 100)} rotation="-90" origin="50, 50" />
              {Array.from({ length: 60 }, (_, index) => {
                const angle = index * Math.PI / 30;
                const inner = index % 15 === 0 ? 36 : 38;
                return <Line key={index} x1={50 + Math.sin(angle) * inner} y1={50 - Math.cos(angle) * inner}
                  x2={50 + Math.sin(angle) * 39.5} y2={50 - Math.cos(angle) * 39.5}
                  stroke={index % 15 === 0 ? '#71717A' : '#303035'} strokeWidth={index % 15 === 0 ? 0.65 : 0.35} />;
              })}
            </Svg>
            <View style={styles.ringCenter} pointerEvents="none" accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
              <Text maxFontSizeMultiplier={1.25} style={[styles.percentage, monoFont, { fontSize: ringSize * 0.225 }]}>
                {clock.displayPercentage}<Text style={{ fontSize: ringSize * 0.10, color: '#A1A1AA' }}>%</Text>
              </Text>
              <Text maxFontSizeMultiplier={1.4} style={[styles.phase, bodyFont, { color: clock.phase.color }]}>{clock.phase.label}</Text>
            </View>
          </View>
          <Text style={[styles.remaining, bodyFont]}><Text style={{ color: '#FAFAFA' }}>{clock.minutesLeft}</Text> minutes left in this hour</Text>
          <View style={styles.segmentBar} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
            {Array.from({ length: 20 }, (_, index) => <View key={index} style={[styles.segment, { backgroundColor: clock.percentage >= (index + 1) * 5 ? clock.phase.color : '#202023' }]} />)}
          </View>
          <Text style={[styles.time, monoFont]}>{clock.clock}</Text>
          {clock.active ? <View style={styles.shiftDetail}>
            <Text style={[styles.smallText, monoFont, { color: '#4ADE80' }]}>shift {formatOffset(clock.offset)}</Text>
            <Text style={[styles.smallText, bodyFont]}>Local time {clock.localClock}</Text>
          </View> : <Text style={[styles.smallText, bodyFont]}>local time</Text>}
        </View>
        <View style={styles.legend}>
          {phases.map(phase => <View key={phase.label} style={styles.legendItem}>
            <View style={[styles.dot, { backgroundColor: phase.color }]} />
            <Text style={[styles.legendLabel, bodyFont]}>{phase.label}</Text>
            <Text style={[styles.range, monoFont]}>{phase.range}</Text>
          </View>)}
        </View>
        {notice && <Text accessibilityRole="alert" style={[styles.error, bodyFont]}>{notice}</Text>}
        <View style={styles.actions}>
          <Pressable accessibilityRole="button" accessibilityLabel="Why percentages?" testID="why-percentages" style={styles.button} onPress={() => setSheet('info')}>
            <Text style={[styles.buttonText, bodyFont]}>Why percentages?</Text>
          </Pressable>
          <Pressable accessibilityRole="button" accessibilityLabel="Time shift" testID="time-shift" disabled={!ready} accessibilityState={{ disabled: !ready }}
            style={[styles.button, !ready && styles.disabled]} onPress={openShift}>
            <Text style={[styles.buttonText, bodyFont]}>Time shift {clock.active ? 'on' : 'off'}</Text>
          </Pressable>
          <Pressable accessibilityRole="button" accessibilityLabel="Clock outside Drift" testID="outside-clock" style={styles.button} onPress={() => setSheet('outside')}>
            <Text style={[styles.buttonText, bodyFont]}>Clock outside Drift</Text>
          </Pressable>
        </View>
      </ScrollView>
      <Modal visible={sheet !== null} transparent animationType="none" onRequestClose={closeSheet}>
        <SafeAreaView style={styles.modalRoot}>
          <KeyboardAvoidingView style={styles.modalKeyboard} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
            <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.modalScroll}>
              <View style={styles.sheet} accessibilityViewIsModal>
                <View style={styles.sheetHeader}>
                  <Text accessibilityRole="header" style={[styles.sheetTitle, bodyFont]}>{sheet === 'info' ? 'Why percentages?' : sheet === 'outside' ? 'Clock outside Drift' : 'Time shift'}</Text>
                  <Pressable accessibilityRole="button" accessibilityLabel="Close" testID="close-sheet" disabled={saving} onPress={closeSheet} style={styles.closeButton}>
                    <Text style={[styles.buttonText, bodyFont]}>Close</Text>
                  </Pressable>
                </View>
                {sheet === 'outside' ? <OutsideClock now={now} /> : sheet === 'info' ? <>
                  <Text style={[styles.paragraph, bodyFont]}>At :30, half of the hour has passed. Drift shows this as 50%.</Text>
                  <Text style={[styles.paragraph, bodyFont]}>The ring fills through four phases, then starts again at the next hour. The percentage always follows your local time.</Text>
                  <Text style={[styles.paragraph, bodyFont]}>Time shift changes the clock below the ring. It does not change the percentage.</Text>
                </> : <>
                  <Text style={[styles.paragraph, bodyFont]}>See what time it would be if you woke up on schedule.</Text>
                  <Text style={[styles.fieldLabel, bodyFont]}>I actually wake up at</Text>
                  <TextInput testID="actual-wake" accessibilityLabel="Actual wake time, 24 hour format HH colon mm" value={actualWake}
                    onChangeText={setActualWake} placeholder="10:00" placeholderTextColor="#71717A" maxLength={5}
                    autoCorrect={false} autoCapitalize="none" editable={!saving} style={[styles.input, monoFont]} />
                  <Text style={[styles.fieldLabel, bodyFont]}>I want to wake up at</Text>
                  <TextInput testID="ideal-wake" accessibilityLabel="Ideal wake time, 24 hour format HH colon mm" value={idealWake}
                    onChangeText={setIdealWake} placeholder="06:00" placeholderTextColor="#71717A" maxLength={5}
                    autoCorrect={false} autoCapitalize="none" editable={!saving} style={[styles.input, monoFont]} />
                  <Text style={[styles.smallText, bodyFont]}>Use 24-hour time, such as 06:00 or 22:30.</Text>
                  <Text style={[styles.preview, monoFont]}>{preview ? `shift ${formatOffset(offsetMinutes(preview))}` : 'Enter valid times in HH:mm format.'}</Text>
                  <Text style={[styles.paragraph, bodyFont]}>The shift uses the shortest difference, up to 12 hours. Your local hour percentage stays the same.</Text>
                  {formError && <Text accessibilityRole="alert" style={[styles.error, bodyFont]}>{formError}</Text>}
                  <Pressable accessibilityRole="button" accessibilityLabel="Start time shift" testID="start-shift" disabled={saving} accessibilityState={{ disabled: saving }}
                    style={[styles.startButton, saving && styles.disabled]} onPress={() => {
                      if (preview) void saveShift(preview);
                      else setFormError('Enter both times in HH:mm format. Hours must be 00 to 23. Minutes must be 00 to 59.');
                    }}>
                    <Text style={[styles.startText, bodyFont]}>{saving ? 'Saving...' : 'Start time shift'}</Text>
                  </Pressable>
                  {shift?.enabled && <Pressable accessibilityRole="button" accessibilityLabel="Turn off time shift" testID="disable-shift" disabled={saving}
                    style={styles.button} onPress={() => { void saveShift({ ...shift, enabled: false }); }}>
                    <Text style={[styles.buttonText, bodyFont, { color: '#F87171' }]}>Turn off time shift</Text>
                  </Pressable>}
                </>}
              </View>
            </ScrollView>
          </KeyboardAvoidingView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0A0A0B' },
  page: { flexGrow: 1, alignItems: 'center', paddingHorizontal: 24, paddingVertical: 22 },
  header: { width: '100%', maxWidth: 480, alignItems: 'center', marginBottom: 28 },
  brand: { color: '#FAFAFA', fontSize: 32, letterSpacing: -1.5, marginBottom: 12 },
  eyebrow: { color: '#A1A1AA', fontSize: 10, letterSpacing: 2.4, textAlign: 'center' },
  clockArea: { alignItems: 'center', width: '100%', maxWidth: 480 },
  ringCenter: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center' },
  percentage: { color: '#FAFAFA', letterSpacing: -3 },
  phase: { fontSize: 16, letterSpacing: 2, marginTop: 8 },
  remaining: { fontSize: 14, color: '#A1A1AA', textAlign: 'center' },
  segmentBar: { flexDirection: 'row', gap: 4, marginTop: 20, marginBottom: 28, width: '75%', maxWidth: 280 },
  segment: { flex: 1, height: 5, borderRadius: 2 },
  time: { color: '#E4E4E7', fontSize: 24, letterSpacing: 0.5 },
  smallText: { color: '#A1A1AA', fontSize: 12, marginTop: 8, textAlign: 'center', lineHeight: 20 },
  shiftDetail: { alignItems: 'center' },
  legend: { width: '100%', maxWidth: 380, flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 18, marginTop: 32, marginBottom: 24 },
  legendItem: { alignItems: 'center', minWidth: 58 },
  dot: { width: 5, height: 5, borderRadius: 3, marginBottom: 8 },
  legendLabel: { color: '#D4D4D8', fontSize: 11 },
  range: { color: '#A1A1AA', fontSize: 9, marginTop: 5 },
  actions: { width: '100%', maxWidth: 480, flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 12, marginTop: 'auto', paddingTop: 12 },
  button: { minHeight: 48, minWidth: 44, paddingHorizontal: 14, paddingVertical: 12, justifyContent: 'center', alignItems: 'center', borderWidth: 1, borderColor: '#27272A', borderRadius: 12 },
  buttonText: { color: '#D4D4D8', fontSize: 13, textAlign: 'center' },
  disabled: { opacity: 0.5 },
  modalRoot: { flex: 1, backgroundColor: '#000000BB' },
  modalKeyboard: { flex: 1 },
  modalScroll: { flexGrow: 1, justifyContent: 'center', padding: 20, alignItems: 'center' },
  sheet: { width: '100%', maxWidth: 480, backgroundColor: '#101012', borderRadius: 24, padding: 24, borderWidth: 1, borderColor: '#27272A' },
  sheetHeader: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, gap: 8 },
  sheetTitle: { color: '#FAFAFA', fontSize: 22, flexShrink: 1 },
  closeButton: { minWidth: 44, minHeight: 44, paddingHorizontal: 8, justifyContent: 'center' },
  paragraph: { color: '#A1A1AA', fontSize: 14, lineHeight: 23, marginBottom: 18 },
  fieldLabel: { color: '#D4D4D8', fontSize: 13, marginBottom: 8 },
  input: { color: '#FAFAFA', fontSize: 20, backgroundColor: '#18181B', borderColor: '#3F3F46', borderWidth: 1, borderRadius: 12, paddingHorizontal: 16, paddingVertical: 12, marginBottom: 16, minHeight: 52 },
  preview: { color: '#4ADE80', fontSize: 15, textAlign: 'center', marginVertical: 18 },
  error: { color: '#F87171', fontSize: 13, lineHeight: 21, marginBottom: 16, maxWidth: 480 },
  startButton: { backgroundColor: '#4ADE80', minHeight: 50, borderRadius: 12, alignItems: 'center', justifyContent: 'center', padding: 14, marginBottom: 12 },
  startText: { color: '#07110A', fontSize: 15 },
});
