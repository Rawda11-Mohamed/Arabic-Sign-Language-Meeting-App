"""
switch_to_15f_model.py
──────────────────────
Run this AFTER you have downloaded  retrained_hierarchical_model_15f.h5
from Colab and placed it in the flask_api folder.

It patches app.py and recognizer.py so the server uses the 15-frame model.

Usage:
    python switch_to_15f_model.py
"""

import os, re

BASE = os.path.dirname(os.path.abspath(__file__))
APP_PY        = os.path.join(BASE, "flask_api", "app.py")
RECOGNIZER_PY = os.path.join(BASE, "flask_api", "recognizer.py")
NEW_MODEL     = "retrained_hierarchical_model_15f.h5"

# ── 1. app.py: point MODEL_PATH to the new file ──────────────────────────────
with open(APP_PY, "r", encoding="utf-8") as f:
    src = f.read()

old_model_line = re.search(r'MODEL_PATH\s*=.*', src).group(0)
new_model_line = f'MODEL_PATH = os.path.join(BASE_DIR, "{NEW_MODEL}")'

if NEW_MODEL in src:
    print(f"app.py already points to {NEW_MODEL}  (no change needed)")
else:
    src = src.replace(old_model_line, new_model_line)
    with open(APP_PY, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"app.py  updated: MODEL_PATH -> {NEW_MODEL}")

# ── 2. recognizer.py: change sequence_length default from 25 -> 15 ───────────
with open(RECOGNIZER_PY, "r", encoding="utf-8") as f:
    src = f.read()

# The default argument in the constructor
patched = re.sub(
    r"(def __init__\(self, model, class_mapping, sequence_length=)\d+(\):)",
    r"\g<1>15\2",
    src,
)

if patched == src:
    print("recognizer.py  already uses sequence_length=15  (no change needed)")
else:
    with open(RECOGNIZER_PY, "w", encoding="utf-8") as f:
        f.write(patched)
    print("recognizer.py  updated: sequence_length default = 15")

print()
print("All done! Now restart Flask (Ctrl+C then python app.py).")
print("Fill time will be ~10 s instead of ~17 s.")
