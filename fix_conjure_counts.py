#!/usr/bin/env python3
"""
Align conjure script counts with spells.xml <rune charges> values.

For each <rune id="X" charges="Y"> in spells.xml, find the matching conjure
script (the one referenced by <instant ... script="conjuring/Z.lua"> whose
script's conjureItem call uses conjureId=X) and rewrite the count to Y.

This makes UH stack=1, GFB stack=2, others stack=5 (or whatever spells.xml
declares), exactly matching the user's normalization.
"""
import re
from pathlib import Path

ROOT = Path(r"C:\Users\Lemos\Desktop\Realera TFS 1.5")
SPELLS_XML = ROOT / "data" / "spells" / "spells.xml"
CONJURING_DIR = ROOT / "data" / "spells" / "scripts" / "conjuring"

xml = SPELLS_XML.read_text(encoding='utf-8', errors='replace')

# 1) rune_id -> charges (from <rune> entries)
rune_charges = {}
for m in re.finditer(r'<rune\b[^/>]*?\bid="(\d+)"[^/>]*?\bcharges="(\d+)"', xml):
    rune_charges[int(m.group(1))] = int(m.group(2))
print(f"[1] Found {len(rune_charges)} <rune> entries with charges")

# 2) instant_script_path -> conjure_id (parsing <instant>)
# We then read each conjure script for its conjureItem(reagent, id, count) call.
instants = {}
for m in re.finditer(r'<instant\b[^>]*?\bscript="(conjuring/[^"]+)"', xml):
    instants[m.group(1)] = True
print(f"[2] Found {len(instants)} <instant> conjure scripts referenced")

CONJURE_CALL = re.compile(r'(creature:conjureItem\((\d+),\s*(\d+),\s*)(\d+)(\))')

updated = 0
unchanged = 0
non_rune = 0
for script_rel, _ in instants.items():
    script_path = ROOT / "data" / "spells" / "scripts" / script_rel
    if not script_path.exists():
        continue
    text = script_path.read_text(encoding='utf-8')
    m = CONJURE_CALL.search(text)
    if not m:
        continue
    conjure_id = int(m.group(3))
    if conjure_id not in rune_charges:
        non_rune += 1
        continue
    new_count = rune_charges[conjure_id]
    old_count = int(m.group(4))
    if old_count == new_count:
        unchanged += 1
        continue
    new_text = CONJURE_CALL.sub(lambda mm: mm.group(1) + str(new_count) + mm.group(5), text, count=1)
    script_path.write_text(new_text, encoding='utf-8')
    print(f"  {script_rel}: id={conjure_id} {old_count} -> {new_count}")
    updated += 1

print(f"\n[3] Updated {updated}, unchanged {unchanged}, non-rune (skipped) {non_rune}")
