import argparse
import pathlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description="Check Drift's live Android status icon.")
parser.add_argument("--serial", required=True)
args = parser.parse_args()
package = "com.bipinrimal.drift.mobile"
out = pathlib.Path("/private/tmp/drift-notification-android")
out.mkdir(exist_ok=True)


def adb(*command):
    return subprocess.check_output(["adb", "-s", args.serial, *command], timeout=30)


def tree():
    adb("shell", "uiautomator", "dump", "/sdcard/drift-notification.xml")
    return ET.fromstring(adb("shell", "cat", "/sdcard/drift-notification.xml"))


def nodes():
    return list(tree().iter("node"))


def find(identifier):
    for _ in range(6):
        for node in nodes():
            if identifier in (node.get("resource-id"), node.get("text"), node.get("content-desc")):
                return node
        adb("shell", "input", "swipe", "540", "1900", "540", "450", "350")
    raise AssertionError(f"Missing element: {identifier}")


def tap(node):
    left, top, right, bottom = map(int, re.findall(r"\d+", node.get("bounds")))
    assert right > left and bottom > top
    adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))
    time.sleep(0.5)


def capture(name):
    (out / f"{name}.png").write_bytes(adb("exec-out", "screencap", "-p"))


def notification():
    dump = adb("shell", "dumpsys", "notification", "--noredact").decode()
    active = dump.split("Notification List:", 1)[1].split("mToastQueue", 1)[0]
    for record in re.split(r"(?=    NotificationRecord\()", active):
        header = record.splitlines()[0] if record.splitlines() else ""
        if f"pkg={package} " in header and " id=42 " in header:
            return record
    return None


def gone(message):
    for _ in range(6):
        if notification() is None:
            return
        time.sleep(0.5)
    raise AssertionError(message)


def shade_row_node(match):
    # Android may group Drift's notifications; the innermost row holding the title is ours.
    rows = [row for row in tree().iter("node")
            if row.get("resource-id") == "com.android.systemui:id/expandableNotificationRow"
            and any("% of this hour" in (node.get("text") or "") for node in row.iter("node"))]
    return next((node for node in rows[-1].iter("node") if match(node)), None) if rows else None


def tap_stop_in_shade():
    for _ in range(3):
        stop = shade_row_node(lambda node: node.get("text") == "Stop status icon")
        if stop is not None:
            tap(stop)
            return
        expand = shade_row_node(lambda node: node.get("resource-id") in
                                ("android:id/expand_button", "android:id/expand_button_touch_container"))
        assert expand is not None, "The Drift notification can expand in the shade"
        tap(expand)
    raise AssertionError("The expanded Drift notification shows Stop status icon")


def reading():
    for _ in range(3):
        before = adb("shell", "date", "+%M:%S").decode().strip()
        record = notification()
        after = adb("shell", "date", "+%M:%S").decode().strip()
        assert record is not None, "The live notification exists"
        match = re.search(r"android.title=String \((\d+)%", record)
        assert match, "The notification title gives the percentage"
        value = int(match[1])
        expected = {sum(int(part) * unit for part, unit in zip(clock.split(":"), (60, 1))) // 36
                    for clock in (before, after)}
        if value in expected:
            assert "typ=BITMAP" in record, "The small icon uses rendered percentage digits"
            assert "sound=null" in record and "vibrate=null" in record, "Updates are silent"
            return value
        time.sleep(0.5)
    raise AssertionError(f"Notification percentage {value} differs from phone time {before}, {after}")


SHEET_IDS = ("close-sheet", "toggle-notification", "add-widget", "toggle-overlay")


def open_choices():
    adb("shell", "am", "start", "-n", f"{package}/.MainActivity")
    time.sleep(1)
    if any(node.get("resource-id") in SHEET_IDS for node in nodes()):
        adb("shell", "input", "keyevent", "4")
        time.sleep(0.5)
    tap(find("outside-clock"))


open_choices()
control = find("toggle-notification")
if notification() is None:
    tap(control)
    permission = next((node for node in nodes()
                       if node.get("resource-id", "").endswith("permission_allow_button")), None)
    if permission is not None:
        tap(permission)
time.sleep(1)
first = reading()
capture("status-icon-controls")
adb("shell", "monkey", "-p", "com.sec.android.app.popupcalculator", "-c", "android.intent.category.LAUNCHER", "1")
time.sleep(1)
capture("status-icon-calculator")
deadline = time.monotonic() + 42
while time.monotonic() < deadline:
    time.sleep(2)
    current = reading()
    if current != first:
        break
else:
    raise AssertionError("The percentage did not update while another app was open")
capture("status-icon-updated")
print(f"PASS: silent bitmap icon and background percentage update {first}% to {current}%", flush=True)
adb("shell", "cmd", "statusbar", "expand-notifications")
time.sleep(1)
capture("notification-expanded")
tap_stop_in_shade()
gone("The notification Stop action removes the icon")
adb("shell", "cmd", "statusbar", "collapse")
open_choices()
tap(find("toggle-notification"))
time.sleep(1)
reading()
tap(find("toggle-notification"))
gone("The app can stop the status icon")
tap(find("toggle-notification"))
time.sleep(1)
reading()
adb("shell", "input", "keyevent", "3")
time.sleep(1)
capture("status-icon-home")
print("PASS: notification Stop, app stop, restart. Status icon remains enabled.", flush=True)
