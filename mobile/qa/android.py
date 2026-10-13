import argparse
import pathlib
import re
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description="Check Drift on a connected Android device.")
parser.add_argument("--serial", required=True)
parser.add_argument("--output", default="/private/tmp/drift-android-qa")
args = parser.parse_args()
out = pathlib.Path(args.output)
out.mkdir(parents=True, exist_ok=True)
package = "com.bipinrimal.drift.mobile"


def adb(*command):
    return subprocess.check_output(["adb", "-s", args.serial, *command], timeout=30)


def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/drift-qa.xml")
    return list(ET.fromstring(adb("shell", "cat", "/sdcard/drift-qa.xml")).iter("node"))


def find(identifier):
    for node in nodes():
        if identifier in (node.get("resource-id"), node.get("text"), node.get("content-desc")):
            return node
    raise AssertionError(f"Missing UI element: {identifier}")


def tap(identifier):
    node = find(identifier)
    left, top, right, bottom = map(int, re.findall(r"\d+", node.get("bounds")))
    assert right > left and bottom > top, identifier
    adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))
    time.sleep(0.3)


def replace(identifier, value):
    tap(identifier)
    adb("shell", "input", "keyevent", "123")
    adb("shell", "input", "keyevent", *(["67"] * 5))
    adb("shell", "input", "text", value)
    adb("shell", "input", "keyevent", "4")


def launch():
    adb("shell", "am", "start", "-n", f"{package}/.MainActivity")
    time.sleep(1)


def relaunch():
    adb("shell", "am", "force-stop", package)
    launch()


def capture(name):
    (out / f"{name}.png").write_bytes(adb("exec-out", "screencap", "-p"))


def check_clock():
    before = int(adb("shell", "date", "+%M").strip())
    ring = next(node for node in nodes() if "percent of this hour complete" in node.get("content-desc", ""))
    after = int(adb("shell", "date", "+%M").strip())
    percent = int(ring.get("content-desc").split()[0])
    assert any(int(minute * 100 / 60) <= percent <= int((minute * 60 + 59) / 36)
               for minute in (before, after)), (percent, before, after)


original_font = adb("shell", "settings", "get", "system", "font_scale").decode().strip()
original_rotation = adb("shell", "settings", "get", "system", "user_rotation").decode().strip()
original_auto = adb("shell", "settings", "get", "system", "accelerometer_rotation").decode().strip()
original_shift = None
try:
    launch()
    existing = nodes()
    if any(node.get("resource-id") == "close-sheet" for node in existing):
        tap("close-sheet")
    for _ in range(4):
        try:
            find("time-shift")
            break
        except AssertionError:
            adb("shell", "input", "swipe", "540", "1900", "540", "400", "400")
    tap("time-shift")
    original_shift = (find("actual-wake").get("text"), find("ideal-wake").get("text"),
                      any(node.get("resource-id") == "disable-shift" for node in nodes()))
    tap("close-sheet")
    check_clock()
    capture("home")
    tap("why-percentages")
    find("At :30, half of the hour has passed. Drift shows this as 50%.")
    capture("explanation")
    tap("close-sheet")
    tap("time-shift")
    replace("actual-wake", "25:00")
    tap("start-shift")
    find("Enter both times in HH:mm format. Hours must be 00 to 23. Minutes must be 00 to 59.")
    replace("actual-wake", "10:15")
    replace("ideal-wake", "06:00")
    capture("shift-form")
    tap("start-shift")
    find("shift +4h 15m")
    check_clock()
    relaunch()
    find("shift +4h 15m")
    capture("shift-restored")
    tap("time-shift")
    assert find("actual-wake").get("text") == "10:15"
    tap("disable-shift")
    relaunch()
    find("local time")
    adb("shell", "input", "keyevent", "3")
    time.sleep(2)
    launch()
    check_clock()
    capture("foreground-return")
    adb("shell", "settings", "put", "system", "font_scale", "1.8")
    relaunch()
    for _ in range(4):
        try:
            find("time-shift")
            break
        except AssertionError:
            adb("shell", "input", "swipe", "540", "1900", "540", "400", "400")
    tap("time-shift")
    capture("large-text-shift")
    tap("close-sheet")
    adb("shell", "settings", "put", "system", "font_scale", original_font)
    adb("shell", "settings", "put", "system", "accelerometer_rotation", "0")
    adb("shell", "settings", "put", "system", "user_rotation", "1")
    time.sleep(1)
    capture("landscape")
    print("PASS: local clock, explanation, validation, persistence, disable, foreground return, large text, landscape.")
finally:
    for key, value in (("font_scale", original_font), ("user_rotation", original_rotation),
                       ("accelerometer_rotation", original_auto)):
        if value == "null":
            adb("shell", "settings", "delete", "system", key)
        else:
            adb("shell", "settings", "put", "system", key, value)
    launch()
    if original_shift is not None:
        if any(node.get("resource-id") == "close-sheet" for node in nodes()):
            tap("close-sheet")
        for _ in range(4):
            try:
                find("time-shift")
                break
            except AssertionError:
                adb("shell", "input", "swipe", "540", "1900", "540", "400", "400")
        tap("time-shift")
        replace("actual-wake", original_shift[0])
        replace("ideal-wake", original_shift[1])
        tap("start-shift")
        if not original_shift[2]:
            tap("time-shift")
            tap("disable-shift")
