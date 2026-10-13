import argparse
import json
import pathlib
import subprocess
import time

parser = argparse.ArgumentParser(description="Verify Drift's widget on an iOS simulator home screen.")
parser.add_argument("--udid", required=True)
parser.add_argument("--idb", default="idb")
parser.add_argument("--output", default="/private/tmp/drift-ios-widget-proof")
args = parser.parse_args()
out = pathlib.Path(args.output)
out.mkdir(parents=True, exist_ok=True)

subprocess.run([args.idb, "ui", "button", "HOME", "--udid", args.udid], check=True, timeout=30)
time.sleep(1)
raw = subprocess.check_output([
    args.idb, "ui", "describe-all", "--api", "axbridge", "--match", "Drift", "--filter", "interactable",
    "--udid", args.udid,
], timeout=30)
elements = json.loads(raw)
widget = next((element for element in elements if element.get("AXValue") == "Widget"
               and element.get("frame", {}).get("width", 0) > 0), None)
assert widget is not None, "Add Drift's widget from the home screen widget picker before running this check."
(out / "widget-accessibility.json").write_text(json.dumps(widget, indent=2))
subprocess.run(["xcrun", "simctl", "io", args.udid, "screenshot", str(out / "widget-on-home.png")],
               check=True, timeout=30)
print("PASS: Drift has a visible native widget on the iOS home screen. Screenshot and accessibility record saved.")
