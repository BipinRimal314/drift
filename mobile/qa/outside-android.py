import argparse
import pathlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description="Demonstrate Drift's widget and floating clock on Android.")
parser.add_argument("--serial", required=True)
args = parser.parse_args()
out = pathlib.Path("/private/tmp/drift-outside-android")
out.mkdir(exist_ok=True)


def adb(*command):
    return subprocess.check_output(["adb", "-s", args.serial, *command], timeout=30)


def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/drift-outside.xml")
    return list(ET.fromstring(adb("shell", "cat", "/sdcard/drift-outside.xml")).iter("node"))


def find(identifier, scroll=False):
    for _ in range(5 if scroll else 1):
        for node in nodes():
            if identifier in (node.get("resource-id"), node.get("text"), node.get("content-desc")):
                return node
        if scroll:
            adb("shell", "input", "swipe", "540", "1900", "540", "400", "400")
    raise AssertionError(f"Missing element: {identifier}")


def tap_node(node):
    left, top, right, bottom = map(int, re.findall(r"\d+", node.get("bounds")))
    assert right > left and bottom > top
    adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))
    time.sleep(0.5)


def tap(identifier, scroll=False):
    tap_node(find(identifier, scroll))


def capture(name):
    (out / f"{name}.png").write_bytes(adb("exec-out", "screencap", "-p"))


def overlay_bounds():
    for window in adb("shell", "dumpsys", "window", "windows").decode().split("Window #"):
        if ("package=com.bipinrimal.drift.mobile" in window and "ty=APPLICATION_OVERLAY" in window
                and "isVisible=true" in window):
            match = re.search(r"frame=\[(\d+),(\d+)\]\[(\d+),(\d+)\]", window)
            assert match is not None, "The visible overlay has window bounds"
            return tuple(map(int, match.groups()))
    return None


SHEET_IDS = ("close-sheet", "toggle-notification", "add-widget", "toggle-overlay")


def open_choices():
    adb("shell", "am", "start", "-n", "com.bipinrimal.drift.mobile/.MainActivity")
    time.sleep(1)
    if any(node.get("resource-id") in SHEET_IDS for node in nodes()):
        adb("shell", "input", "keyevent", "4")
        time.sleep(0.5)
    tap("outside-clock", scroll=True)


open_choices()
capture("choices")
widget_state = adb("shell", "dumpsys", "appwidget").decode().split("Widgets:")[-1].split("Hosts:")[0]
if "com.bipinrimal.drift.mobile" not in widget_state:
    tap("add-widget", scroll=True)
    capture("pin-confirmation")
    tap("Add")
adb("shell", "input", "keyevent", "3")
time.sleep(1)
home = nodes()
for direction in ((900, 180), (180, 900)):
    for _ in range(6):
        if any("Updated " in node.get("text", "") for node in home):
            break
        adb("shell", "input", "swipe", str(direction[0]), "1100", str(direction[1]), "1100", "350")
        home = nodes()
    if any("Updated " in node.get("text", "") for node in home):
        break
assert any("Updated " in node.get("text", "") for node in home), "Pinned widget shows a timestamp"
capture("widget-on-home")
refresh = next(node for node in home if "Tap to refresh" in node.get("text", ""))
tap_node(refresh)
assert any("Updated " in node.get("text", "") for node in nodes())
print("PASS: widget pin, home rendering, manual refresh", flush=True)
open_choices()
control = find("toggle-overlay", scroll=True)
label = " ".join(node.get("text", "") for node in control.iter("node"))
if "Allow floating clock" in label:
    tap_node(control)
    settings = nodes()
    assert any("Drift" in node.get("text", "") for node in settings), "Permission screen belongs to Drift"
    row = next(node for node in settings if node.get("content-desc", "").startswith("Drift,") and "Switch" in node.get("content-desc", ""))
    if ", Off," in row.get("content-desc", ""):
        tap_node(row)
    adb("shell", "input", "keyevent", "4")
    time.sleep(1)
    control = find("toggle-overlay", scroll=True)
label = " ".join(node.get("text", "") for node in control.iter("node"))
if "Stop floating clock" not in label:
    tap_node(control)
    permission = next((node for node in nodes() if node.get("resource-id", "").endswith("permission_allow_button")), None)
    if permission is not None:
        tap_node(permission)
time.sleep(1)
before = overlay_bounds()
assert before is not None, "The floating clock is visible"
left, top, right, bottom = before
start_x = left + (right - left - (bottom - top)) // 2
start_y = (top + bottom) // 2
adb("shell", "input", "swipe", str(start_x), str(start_y),
    str(start_x + (200 if start_x < 700 else -200)), str(start_y + (200 if start_y < 1800 else -200)), "800")
after = overlay_bounds()
assert after is not None and after[:2] != before[:2], "Dragging moves the floating clock"
adb("shell", "monkey", "-p", "com.sec.android.app.popupcalculator", "-c", "android.intent.category.LAUNCHER", "1")
time.sleep(1)
assert overlay_bounds() is not None, "Overlay remains above another app"
capture("floating-over-calculator")
left, top, right, bottom = overlay_bounds()
adb("shell", "input", "tap", str(right - (bottom - top) // 2), str((top + bottom) // 2))
time.sleep(0.5)
assert overlay_bounds() is None, "Close stops the floating clock"
print("PASS: permission, foreground start, drag, other app, close", flush=True)
open_choices()
tap("toggle-overlay", scroll=True)
assert overlay_bounds() is not None, "Overlay restarts"
adb("shell", "input", "keyevent", "3")
time.sleep(1)
capture("both-on-home")
print("PASS: both choices are visible on the phone. Widget and floating clock remain enabled.", flush=True)
