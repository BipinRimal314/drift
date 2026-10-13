import { useEffect, useState } from 'react';
import { PermissionsAndroid, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { requireOptionalNativeModule } from 'expo';
import { snapshot } from './clock';

type ToolsState = {
  overlayEnabled: boolean; overlayPermission: boolean;
  notificationEnabled: boolean; notificationPermission: boolean;
};
type Tools = {
  getState(): Promise<ToolsState>;
  requestOverlayPermission(): Promise<void>;
  startOverlay(): Promise<void>;
  stopOverlay(): Promise<void>;
  requestWidget(): Promise<boolean>;
  startNotification(): Promise<void>;
  stopNotification(): Promise<void>;
  openNotificationSettings(): Promise<void>;
};
type LoadState = { kind: 'loading' } | { kind: 'ready'; toolsState: ToolsState } | { kind: 'unavailable' };
const tools = Platform.OS === 'android' ? requireOptionalNativeModule<Tools>('DriftTools') : null;

export default function OutsideClock({ now }: { now: Date }) {
  const clock = snapshot(now, null);
  const [state, setState] = useState<LoadState>(tools ? { kind: 'loading' } : { kind: 'unavailable' });
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!tools) return;
    let mounted = true;
    async function refresh() {
      if (!tools) return;
      try {
        const toolsState = await tools.getState();
        if (mounted) setState({ kind: 'ready', toolsState });
      } catch {
        if (mounted) setState({ kind: 'unavailable' });
      }
    }
    void refresh();
    return () => { mounted = false; };
  }, [now]);

  async function addWidget() {
    if (!tools || busy) return;
    setBusy(true);
    try {
      const offered = await tools.requestWidget();
      setMessage(offered ? 'Confirm Add in your launcher. You can move or resize the widget on the home screen.'
        : 'Touch and hold your home screen. Open Widgets, select Drift, and drag its widget into place.');
    } catch {
      setMessage('The widget could not be added. Try adding Drift from your home screen widget list.');
    } finally { setBusy(false); }
  }

  async function runTool(action: () => Promise<void>, failureMessage: string) {
    if (!tools || state.kind !== 'ready' || busy) return;
    setBusy(true);
    setMessage(null);
    try {
      await action();
      setState({ kind: 'ready', toolsState: await tools.getState() });
    } catch {
      setMessage(failureMessage);
      try { setState({ kind: 'ready', toolsState: await tools.getState() }); }
      catch { setState({ kind: 'unavailable' }); }
    } finally { setBusy(false); }
  }

  const toggleOverlay = () => runTool(async () => {
    if (!tools || state.kind !== 'ready') return;
    if (state.toolsState.overlayEnabled) {
      await tools.stopOverlay();
    } else if (!state.toolsState.overlayPermission) {
      setMessage('Allow display over other apps. Return to Drift, then tap Start floating clock.');
      await tools.requestOverlayPermission();
    } else {
      if (Number(Platform.Version) >= 33) {
        await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS);
      }
      await tools.startOverlay();
      setMessage('Drag the percentage to move it. Tap it to open Drift. Use Close to stop the floating clock.');
    }
  }, 'The floating clock could not change. Check its display permission and try again.');

  const toggleNotification = () => runTool(async () => {
    if (!tools || state.kind !== 'ready') return;
    if (state.toolsState.notificationEnabled) {
      await tools.stopNotification();
      return;
    }
    if (Number(Platform.Version) >= 33) {
      await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS);
    }
    if (!(await tools.getState()).notificationPermission) {
      setMessage('Allow Hour percentage notifications and status bar icons. Return to Drift, then tap Start status icon.');
      await tools.openNotificationSettings();
    } else {
      await tools.startNotification();
      setMessage('The status icon shows the hour percentage as a number. Open its notification for details or Stop.');
    }
  }, 'The status icon could not change. Check notification settings and try again.');

  const enabled = state.kind === 'ready' && state.toolsState.overlayEnabled;
  const toolsReady = state.kind === 'ready' && !busy;
  return <View style={styles.content}>
    {message && <Text accessibilityRole="alert" testID="outside-message" style={styles.instructions}>{message}</Text>}
    <Text style={styles.description}>These choices show your local hour. Use them together or separately. The phone's system clock stays unchanged.</Text>
    {Platform.OS === 'android' && <View style={styles.card}>
      <Text accessibilityRole="header" style={styles.title}>Status icon</Text>
      <View style={styles.iconPreview} accessible accessibilityLabel={`Status icon preview. ${clock.displayPercentage} percent of this hour.`}>
        <Text style={styles.iconPercent}>{clock.displayPercentage}</Text>
      </View>
      <Text style={styles.description}>See the hour percentage beside your notification icons. The number means percent of this hour.</Text>
      <Text style={styles.detail}>Android controls icon visibility. Enable notification icons in your phone settings if they are hidden. No display permission is needed.</Text>
      <Pressable testID="toggle-notification" accessibilityRole="button" accessibilityState={{ disabled: !toolsReady }}
        disabled={!toolsReady} onPress={() => { void toggleNotification(); }} style={[styles.button, !toolsReady && styles.disabled]}>
        <Text style={styles.buttonText}>{busy ? 'Please wait...' : state.kind === 'ready' && state.toolsState.notificationEnabled
          ? 'Stop status icon' : 'Start status icon'}</Text>
      </Pressable>
      <Pressable testID="notification-settings" accessibilityRole="button" accessibilityState={{ disabled: !tools || busy }}
        disabled={!tools || busy} onPress={() => {
          void tools?.openNotificationSettings().catch(() => setMessage('Notification settings could not open. Open Drift notifications in phone settings.'));
        }} style={styles.settingsButton}>
        <Text style={styles.instructions}>Notification settings</Text>
      </Pressable>
      {state.kind === 'unavailable' && <Text style={styles.detail}>The status icon is unavailable in this build.</Text>}
    </View>}
    <View style={styles.card}>
      <Text accessibilityRole="header" style={styles.title}>Home screen widget</Text>
      <View style={styles.widgetPreview} accessible accessibilityLabel={`Widget preview. ${clock.displayPercentage} percent. ${clock.phase.label}.`}>
        <Text style={[styles.percent, { color: clock.phase.color }]}>{clock.displayPercentage}%</Text>
        <Text style={styles.previewText}>{clock.phase.label} · {clock.minutesLeft} minutes left</Text>
        <Text style={styles.previewText}>This hour · {clock.localClock}</Text>
      </View>
      <Text style={styles.description}>See the hour when you return to your home screen.</Text>
      <Text style={styles.detail}>The phone controls widget updates. They can be delayed. Open Drift for the live clock.</Text>
      {Platform.OS === 'android' ? <>
        <Pressable testID="add-widget" accessibilityRole="button" accessibilityState={{ disabled: !tools || busy }}
          disabled={!tools || busy} onPress={() => { void addWidget(); }} style={[styles.button, (!tools || busy) && styles.disabled]}>
          <Text style={styles.buttonText}>Add home screen widget</Text>
        </Pressable>
        <Text style={styles.detail}>The Android widget shows its last update time. Tap Refresh when you need a new reading.</Text>
      </> : <Text style={styles.instructions}>Touch and hold the home screen. Tap Edit, then Add Widget. Search for Drift and choose a size.</Text>}
    </View>
    <View style={styles.card}>
      <Text accessibilityRole="header" style={styles.title}>Floating clock</Text>
      <View style={styles.overlayPreview} accessible accessibilityLabel={`Floating clock preview. ${clock.displayPercentage} percent.`}>
        <Text style={[styles.overlayPercent, { color: clock.phase.color }]}>{clock.displayPercentage}%</Text>
        <Text style={styles.previewText}>Close</Text>
      </View>
      {Platform.OS === 'android' ? <>
        <Text style={styles.description}>Keep the percentage visible over other apps. Move it away from controls. Turn it off at any time.</Text>
        <Text style={styles.detail}>This uses display permission and an ongoing notification. It does not replace the system status bar.</Text>
        <Pressable testID="toggle-overlay" accessibilityRole="button" accessibilityState={{ disabled: !toolsReady }}
          disabled={!toolsReady} onPress={() => { void toggleOverlay(); }} style={[styles.button, !toolsReady && styles.disabled]}>
          <Text style={styles.buttonText}>{busy ? 'Please wait...' : enabled ? 'Stop floating clock'
            : state.kind === 'ready' && !state.toolsState.overlayPermission ? 'Allow floating clock' : 'Start floating clock'}</Text>
        </Pressable>
        {state.kind === 'unavailable' && <Text style={styles.detail}>The floating clock is unavailable in this build.</Text>}
      </> : <Text style={styles.description}>iOS does not permit Drift to float over other apps. The home screen widget is available instead.</Text>}
    </View>
  </View>;
}

const styles = StyleSheet.create({
  content: { gap: 16 },
  card: { padding: 16, borderColor: '#303035', borderWidth: 1, borderRadius: 16, gap: 12 },
  title: { color: '#FAFAFA', fontSize: 18 },
  description: { color: '#D4D4D8', fontSize: 14, lineHeight: 23 },
  detail: { color: '#A1A1AA', fontSize: 12, lineHeight: 20 },
  instructions: { color: '#D4D4D8', fontSize: 14, lineHeight: 23 },
  widgetPreview: { backgroundColor: '#0A0A0B', borderRadius: 18, padding: 18, gap: 6, alignItems: 'center' },
  percent: { fontSize: 42, fontVariant: ['tabular-nums'] },
  previewText: { color: '#D4D4D8', fontSize: 12, textAlign: 'center' },
  overlayPreview: { alignSelf: 'center', flexDirection: 'row', alignItems: 'center', gap: 20, backgroundColor: '#0A0A0B', borderRadius: 28, paddingHorizontal: 18, minHeight: 56 },
  overlayPercent: { fontSize: 26, fontVariant: ['tabular-nums'] },
  iconPreview: { alignSelf: 'center', backgroundColor: '#0A0A0B', borderRadius: 28, paddingHorizontal: 18, minHeight: 56, justifyContent: 'center' },
  iconPercent: { color: '#FAFAFA', fontSize: 26, fontVariant: ['tabular-nums'] },
  button: { minHeight: 48, padding: 12, backgroundColor: '#4ADE80', borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  buttonText: { color: '#07110A', fontSize: 14, textAlign: 'center' },
  settingsButton: { minHeight: 48, padding: 12, alignItems: 'center', justifyContent: 'center' },
  disabled: { opacity: 0.5 },
});
