"""
Move unused NPC XML files (and their .lua scripts when matching) into
data/npc/_unused/ so the live folder only contains NPCs that are
actually referenced somewhere in the server.

Definition of "used":
  - NPC name appears in data/world/global-spawn.xml, OR
  - NPC name appears as a string anywhere under data/ EXCEPT data/npc/
    (so the npc's own xml/script never self-references)

Orphans are moved (not deleted) so a misclassification can be reversed
by dragging the file back.
"""

import re
import shutil
from pathlib import Path

BASE = Path(__file__).parent / "data"
NPC_DIR = BASE / "npc"
NPC_SCRIPT_DIR = NPC_DIR / "scripts"
SPAWN_XML = BASE / "world" / "global-spawn.xml"
UNUSED_DIR = NPC_DIR / "_unused"
UNUSED_SCRIPT_DIR = UNUSED_DIR / "scripts"

UNUSED_DIR.mkdir(exist_ok=True)
UNUSED_SCRIPT_DIR.mkdir(exist_ok=True)


def read(p):
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


# ---- 1. Spawned NPCs ----
spawned = set()
for m in re.finditer(r'<npc name="([^"]+)"', read(SPAWN_XML)):
    spawned.add(m.group(1))
print(f"Spawned NPCs: {len(spawned)} unique names")

# ---- 2. All NPC xmls + their internal name ----
npc_files = {}  # filename -> {"path": Path, "name": str, "script": str|None}
for xml in NPC_DIR.glob("*.xml"):
    content = read(xml)
    m_name = re.search(r'<npc\s+name="([^"]+)"', content)
    if not m_name:
        print(f"  skip (no <npc name>): {xml.name}")
        continue
    name = m_name.group(1)
    m_script = re.search(r'script="([^"]+\.lua)"', content)
    script_path = None
    if m_script:
        script_path = NPC_SCRIPT_DIR / Path(m_script.group(1)).name
        if not script_path.exists():
            script_path = None
    npc_files[xml.name] = {"path": xml, "name": name, "script": script_path}

print(f"NPC xml files in data/npc/: {len(npc_files)}")

# ---- 3. Concatenate every file in data/ EXCEPT data/npc/ for substring search ----
# Reads everything once into memory, then scans NPC names against the blob.
# 8.0 / TFS 1.5 are ~50-100MB worth of scripts/xml; this fits easily.
big_blob_parts = []
for f in BASE.rglob("*"):
    if not f.is_file():
        continue
    try:
        rel = f.relative_to(BASE)
    except ValueError:
        continue
    # Skip data/npc/ entirely (no self-reference) and the unused folder.
    if rel.parts and rel.parts[0] == "npc":
        continue
    if f.suffix.lower() in (".lua", ".xml", ".otmod", ".otui"):
        big_blob_parts.append(read(f))

big_blob = "\n".join(big_blob_parts)
print(f"Scanned {len(big_blob_parts)} files outside data/npc/, total {len(big_blob)//1024} KB of text")

# ---- 4. Classify each NPC ----
orphans = []
for fname, info in npc_files.items():
    name = info["name"]
    if name in spawned:
        continue  # spawned -> used
    # Need a precise enough check: name flanked by quotes or word boundary.
    # Many NPC names are common words ("Captain", "Banker") so a raw substring
    # match would yield false-keeps. Quotes catch the typical NPC-name use:
    #   selectByName("X"), shopNpc.name = 'X', etc.
    pattern = re.compile(rf'["\']{re.escape(name)}["\']')
    if pattern.search(big_blob):
        continue  # referenced somewhere -> used
    orphans.append(info)

print(f"Orphan NPCs (to move): {len(orphans)}")

# ---- 5. Move ----
for info in orphans:
    src_xml = info["path"]
    dst_xml = UNUSED_DIR / src_xml.name
    shutil.move(str(src_xml), str(dst_xml))
    msg = f"  moved xml: {src_xml.name}"
    if info["script"]:
        # The npc had a paired script; move it too.
        src_lua = info["script"]
        dst_lua = UNUSED_SCRIPT_DIR / src_lua.name
        if src_lua.exists():
            shutil.move(str(src_lua), str(dst_lua))
            msg += f"  +script: {src_lua.name}"
    print(msg)

print(f"\nDone. Orphans moved to: {UNUSED_DIR.relative_to(BASE.parent)}")
print(f"Live data/npc/ now has {len(list(NPC_DIR.glob('*.xml')))} NPCs.")
