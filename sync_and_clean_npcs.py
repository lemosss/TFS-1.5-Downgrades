"""
3-phase NPC cleanup for TFS 1.5:

PHASE 0 (rollback): if data/npc/_unused/ exists from a previous run,
                    restore everything back into data/npc/.
PHASE 1 (delete):   remove NPCs that exist ONLY in TFS 1.5 (and their
                    paired scripts).
PHASE 2 (copy):     copy NPCs that exist ONLY in 8.0 (and their paired
                    scripts) into TFS 1.5.
PHASE 3 (orphans):  scan TFS 1.5 again for unused NPCs and move them
                    into data/npc/deadfiles/.

After this, TFS 1.5's data/npc/ should mirror 8.0's NPC roster, with
truly orphaned files quarantined in a deadfiles/ subfolder.
"""

import re
import shutil
from pathlib import Path

TFS = Path(__file__).parent / "data"
SRC = Path(r"C:\Users\Lemos\Desktop\Realera OT\Realera 8.0\data")

NPC_DIR = TFS / "npc"
NPC_SCRIPTS = NPC_DIR / "scripts"
SPAWN_XML = TFS / "world" / "global-spawn.xml"
UNUSED_DIR = NPC_DIR / "_unused"
DEAD_DIR = NPC_DIR / "deadfiles"
DEAD_SCRIPTS = DEAD_DIR / "scripts"

SRC_NPC_DIR = SRC / "npc"
SRC_NPC_SCRIPTS = SRC_NPC_DIR / "scripts"

# NPCs that exist ONLY in TFS 1.5 (per the diff you ran). These get deleted.
# Includes the two rename-only files (ArkhothepNPC, Demon SkeletonNPC) since
# Phase 2 will bring back the 8.0 names.
TFS_ONLY = [
    "Alice.xml",
    "Banker.xml",
    "Captain.xml",
    "Deruno.xml",
    "Riona.xml",
    "Tyoric.xml",
    "The Forgotten King.xml",
    "ArkhothepNPC.xml",
    "Demon SkeletonNPC.xml",
]

# NPCs that exist ONLY in 8.0 (per the diff). These get copied. Test.xml
# is intentionally skipped (debug file).
EIGHT_ZERO_ONLY = [
    "A Logger.xml",
    "Arkhothep.xml",
    "Azham.xml",
    "Demon Skeleton NPC.xml",
    "Djinn Master.xml",
    "Eric.xml",
    "Maximus.xml",
    "Nahlesar.xml",
    "Quentin in Arena.xml",
]


def read(p):
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


# ============================================================
# PHASE 0: Rollback previous _unused move
# ============================================================
print("=" * 60)
print("PHASE 0: Rollback _unused/ if any")
print("=" * 60)
restored = 0
if UNUSED_DIR.exists():
    for xml in UNUSED_DIR.glob("*.xml"):
        dest = NPC_DIR / xml.name
        shutil.move(str(xml), str(dest))
        restored += 1
    sub_scripts = UNUSED_DIR / "scripts"
    if sub_scripts.exists():
        for lua in sub_scripts.glob("*.lua"):
            dest = NPC_SCRIPTS / lua.name
            shutil.move(str(lua), str(dest))
            restored += 1
        sub_scripts.rmdir()
    UNUSED_DIR.rmdir()
print(f"Restored {restored} files. data/npc/ now has "
      f"{len(list(NPC_DIR.glob('*.xml')))} NPCs.\n")

# ============================================================
# PHASE 1: Delete TFS-only NPCs
# ============================================================
print("=" * 60)
print("PHASE 1: Delete TFS-only NPCs")
print("=" * 60)
deleted = 0
for fname in TFS_ONLY:
    xml = NPC_DIR / fname
    if not xml.exists():
        print(f"  skip (already gone): {fname}")
        continue
    # Find paired script via the xml's `script="X.lua"` attribute (best),
    # or fall back to filename + .lua.
    content = read(xml)
    m = re.search(r'script="([^"]+\.lua)"', content)
    script_name = Path(m.group(1)).name if m else xml.stem + ".lua"
    script = NPC_SCRIPTS / script_name
    xml.unlink()
    deleted += 1
    msg = f"  deleted xml: {fname}"
    if script.exists():
        script.unlink()
        msg += f"  +script: {script.name}"
    print(msg)
print(f"Deleted {deleted} NPCs.\n")

# ============================================================
# PHASE 2: Copy 8.0-only NPCs into TFS 1.5
# ============================================================
print("=" * 60)
print("PHASE 2: Copy 8.0-only NPCs into TFS 1.5")
print("=" * 60)
copied = 0
for fname in EIGHT_ZERO_ONLY:
    src_xml = SRC_NPC_DIR / fname
    if not src_xml.exists():
        print(f"  ERROR: not found in 8.0: {fname}")
        continue
    dst_xml = NPC_DIR / fname
    shutil.copy2(str(src_xml), str(dst_xml))
    copied += 1
    msg = f"  copied xml: {fname}"
    content = read(src_xml)
    m = re.search(r'script="([^"]+\.lua)"', content)
    script_name = Path(m.group(1)).name if m else src_xml.stem + ".lua"
    src_script = SRC_NPC_SCRIPTS / script_name
    if src_script.exists():
        dst_script = NPC_SCRIPTS / script_name
        shutil.copy2(str(src_script), str(dst_script))
        msg += f"  +script: {script_name}"
    print(msg)
print(f"Copied {copied} NPCs.\n")

# ============================================================
# PHASE 3: Detect orphans and quarantine to deadfiles/
# ============================================================
print("=" * 60)
print("PHASE 3: Move unused NPCs to data/npc/deadfiles/")
print("=" * 60)
DEAD_DIR.mkdir(exist_ok=True)
DEAD_SCRIPTS.mkdir(exist_ok=True)

# Spawned NPCs (from global-spawn.xml)
spawned = set()
for m in re.finditer(r'<npc name="([^"]+)"', read(SPAWN_XML)):
    spawned.add(m.group(1))
print(f"Spawned NPCs: {len(spawned)} unique names")

# All NPC xmls + their internal name + paired script (if any)
npc_files = {}
for xml in NPC_DIR.glob("*.xml"):
    if xml.is_dir():
        continue
    content = read(xml)
    m_name = re.search(r'<npc\s+name="([^"]+)"', content)
    if not m_name:
        continue
    name = m_name.group(1)
    m_script = re.search(r'script="([^"]+\.lua)"', content)
    script_path = None
    if m_script:
        sp = NPC_SCRIPTS / Path(m_script.group(1)).name
        if sp.exists():
            script_path = sp
    npc_files[xml] = {"name": name, "script": script_path}

print(f"NPC xml files in data/npc/: {len(npc_files)}")

# Concatenate all data/ files OUTSIDE data/npc/ for substring scan
big_blob = []
for f in TFS.rglob("*"):
    if not f.is_file():
        continue
    try:
        rel = f.relative_to(TFS)
    except ValueError:
        continue
    if rel.parts and rel.parts[0] == "npc":
        continue
    if f.suffix.lower() in (".lua", ".xml", ".otmod", ".otui"):
        big_blob.append(read(f))
blob = "\n".join(big_blob)
print(f"Scanned {len(big_blob)} files outside data/npc/, "
      f"total {len(blob)//1024} KB")

# Classify
orphans = []
for xml_path, info in npc_files.items():
    name = info["name"]
    if name in spawned:
        continue
    # Quoted-name match -- avoids false positives from common-word names.
    pattern = re.compile(rf'["\']{re.escape(name)}["\']')
    if pattern.search(blob):
        continue
    orphans.append((xml_path, info))
print(f"Orphan NPCs to quarantine: {len(orphans)}")

# Move them
for xml_path, info in orphans:
    dst_xml = DEAD_DIR / xml_path.name
    shutil.move(str(xml_path), str(dst_xml))
    if info["script"] and info["script"].exists():
        dst_script = DEAD_SCRIPTS / info["script"].name
        shutil.move(str(info["script"]), str(dst_script))

# Final summary
live = len(list(NPC_DIR.glob("*.xml")))
dead = len(list(DEAD_DIR.glob("*.xml")))
print(f"\nDone.")
print(f"  Live data/npc/         : {live} NPCs")
print(f"  Quarantined deadfiles/ : {dead} NPCs")
print(f"  Live scripts           : {len(list(NPC_SCRIPTS.glob('*.lua')))}")
print(f"  Dead scripts           : {len(list(DEAD_SCRIPTS.glob('*.lua')))}")
