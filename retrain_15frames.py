"""
retrain_15frames.py
───────────────────
Patches the videos4.ipynb Colab notebook to retrain the model with
SEQUENCE_LENGTH = 15 instead of 25.

Run:
    python retrain_15frames.py

This creates  videos4_15frames.ipynb  next to the original notebook.
Upload that file to Google Colab and run all cells.

After training, download the saved model and rename it:
    retrained_hierarchical_model_15f.h5
Then drop it in:
    meeting2/flask_api/
"""

import json
import re
import os

# ── locate the notebook ───────────────────────────────────────────────────────
NOTEBOOK_PATH = r"C:/Users/Rawda/Downloads/videos4.ipynb"
OUTPUT_PATH   = r"C:/Users/Rawda/Downloads/videos4_15frames.ipynb"

if not os.path.exists(NOTEBOOK_PATH):
    print(f"ERROR: Notebook not found at {NOTEBOOK_PATH}")
    print("Please update NOTEBOOK_PATH at the top of this script.")
    exit(1)

with open(NOTEBOOK_PATH, "r", encoding="utf-8") as f:
    nb = json.load(f)

changes = []

for cell in nb.get("cells", []):
    if cell["cell_type"] != "code":
        continue

    src = "".join(cell["source"])
    original = src

    # ── 1. Change SEQUENCE_LENGTH constant ───────────────────────────────────
    # Covers both spellings used in different notebook versions
    for pattern in [
        r"(SEQUENCE_LENGTH\s*=\s*)\d+",
        r"(sequence_length\s*=\s*)\d+",
        r"(self\.sequence_length\s*=\s*)\d+",
    ]:
        src = re.sub(pattern, r"\g<1>15", src)

    # ── 2. Change any hard-coded 25 that clearly refers to sequence length ───
    # e.g.  "sequence = np.zeros((25, 100))"  →  np.zeros((15, 100))
    src = re.sub(r"\bnp\.zeros\(\(25,\s*100\)\)", "np.zeros((15, 100))", src)
    src = re.sub(r"\breshape\(1,\s*25,\s*100\)",  "reshape(1, 15, 100)",   src)
    src = re.sub(r"\breshape\(-1,\s*25,\s*100\)", "reshape(-1, 15, 100)",  src)
    # Input layer definitions  e.g.  Input(shape=(25, 100))
    src = re.sub(r"Input\(shape=\(25,\s*100\)\)", "Input(shape=(15, 100))", src)
    src = re.sub(r"input_shape=\(25,\s*100\)",    "input_shape=(15, 100)", src)

    # ── 3. Model filename – save as a distinctly-named file ──────────────────
    src = src.replace(
        "retrained_hierarchical_model",
        "retrained_hierarchical_model_15f",
    )
    # Also covers plain "hierarchical_model" saves
    src = src.replace(
        "hierarchical_model.h5",
        "hierarchical_model_15f.h5",
    )

    if src != original:
        changes.append("modified a cell")
        lines = src.splitlines(True)
        cell["source"] = lines

with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump(nb, f, indent=2, ensure_ascii=False)

print(f"Done! {len(changes)} cell(s) modified.")
print(f"Patched notebook saved to:\n  {OUTPUT_PATH}")
print()
print("Next steps:")
print("  1. Upload  videos4_15frames.ipynb  to Google Colab")
print("  2. Run all cells (Runtime → Run all)")
print("  3. Download the saved  retrained_hierarchical_model_15f.h5")
print("  4. Place it in:  meeting2/flask_api/")
print("  5. Update MODEL_PATH in app.py  (see instructions below)")
