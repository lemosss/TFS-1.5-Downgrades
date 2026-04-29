#!/usr/bin/env python3
"""
Apply the spell whitelist defined by user spec (28/04/2026).

For each spell:
  - in spells.xml: update mana/maglv/prem to match spec; comment out non-whitelisted
  - in NPC scripts: comment out non-whitelisted entries
  - rune charges: update <rune charges="N"> per RUNE_CHARGES, then sync conjure scripts

Only COMMENTS, never DELETES. Every commented block carries a note:
    [DESATIVADO - Magia fora da whitelist oficial - 28/04/2026]

Run from the repo root. Backups every touched file as `.bak`.
"""
import re
from pathlib import Path
from datetime import datetime
import shutil

ROOT = Path(r"C:\Users\Lemos\Desktop\Realera TFS 1.5")
SPELLS_XML = ROOT / "data" / "spells" / "spells.xml"
NPC_SPELL_DIR = ROOT / "data" / "npc" / "scripts" / "spells"
CONJURING_DIR = ROOT / "data" / "spells" / "scripts" / "conjuring"

NOTE_DATE = "28/04/2026"
DEACT_NOTE = f"[DESATIVADO - Magia fora da whitelist oficial - {NOTE_DATE}]"

# ---------- Whitelist (keyed by lowercase WORDS) ----------
# vocs: 1=Sorc 2=Druid 3=Pal 4=Knight 5=MS 6=ED 7=RP 8=EK
# mana = None -> "var" (don't update mana attr)

WHITELIST = {
    # --- All 4 base vocations ---
    'exana pox':           {'name': 'Antidote',           'vocs': {1,2,3,4,5,6,7,8}, 'ml': 2,  'mana': 30,  'prem': False},
    'exiva':               {'name': 'Find Person',        'vocs': {1,2,3,4,5,6,7,8}, 'ml': 0,  'mana': 20,  'prem': False},
    'utevo gran lux':      {'name': 'Great Light',        'vocs': {1,2,3,4,5,6,7,8}, 'ml': 3,  'mana': 60,  'prem': False},
    'utani hur':           {'name': 'Haste',              'vocs': {1,2,3,4,5,6,7,8}, 'ml': 4,  'mana': 60,  'prem': True},
    'exani hur':           {'name': 'Levitate',           'vocs': {1,2,3,4,5,6,7,8}, 'ml': 3,  'mana': 50,  'prem': True},
    'utevo lux':           {'name': 'Light',              'vocs': {1,2,3,4,5,6,7,8}, 'ml': 0,  'mana': 20,  'prem': False},
    'exura':               {'name': 'Light Healing',      'vocs': {1,2,3,4,5,6,7,8}, 'ml': 1,  'mana': 25,  'prem': False},
    'exani tera':          {'name': 'Magic Rope',         'vocs': {1,2,3,4,5,6,7,8}, 'ml': 1,  'mana': 20,  'prem': True},

    # --- Sorc + Druid + Paladin ---
    'adito tera':          {'name': 'Desintegrate',       'vocs': {1,2,3,5,6,7}, 'ml': 8,  'mana': 100, 'prem': True},
    'adito grav':          {'name': 'Destroy Field',      'vocs': {1,2,3,5,6,7}, 'ml': 6,  'mana': 60,  'prem': False},
    'adori flam':          {'name': 'Fireball',           'vocs': {1,2,3,5,6,7}, 'ml': 5,  'mana': 60,  'prem': False},
    'adori gran':          {'name': 'Heavy Magic Missile','vocs': {1,2,3,5,6,7}, 'ml': 3,  'mana': 70,  'prem': False},
    'exura gran':          {'name': 'Intense Healing',    'vocs': {1,2,3,5,6,7}, 'ml': 2,  'mana': 40,  'prem': False},
    'utana vid':           {'name': 'Invisible',          'vocs': {1,2,3,5,6,7}, 'ml': 15, 'mana': 210, 'prem': False},
    'adori':               {'name': 'Light Magic Missile','vocs': {1,2,3,5,6,7}, 'ml': 1,  'mana': 40,  'prem': False},
    'utamo vita':          {'name': 'Magic Shield',       'vocs': {1,2,3,5,6,7}, 'ml': 4,  'mana': 50,  'prem': False},
    'exura vita':          {'name': 'Ultimate Healing',   'vocs': {1,2,3,5,6,7}, 'ml': 8,  'mana': 80,  'prem': False},

    # --- Sorc + Druid only ---
    'adana mort':          {'name': 'Animate Dead',       'vocs': {1,2,5,6}, 'ml': 7,  'mana': 300, 'prem': True},
    'exana ina':           {'name': 'Cancel Invisibility','vocs': {1,2,5,6}, 'ml': 12, 'mana': 200, 'prem': True},
    'utevo res ina':       {'name': 'Creature Illusion',  'vocs': {1,2,5,6}, 'ml': 10, 'mana': 100, 'prem': False},
    'adevo grav vis':      {'name': 'Energy Field',       'vocs': {1,2,5,6}, 'ml': 5,  'mana': 80,  'prem': False},
    'exori vis':           {'name': 'Energy Strike',      'vocs': {1,2,5,6}, 'ml': 3,  'mana': 20,  'prem': True},
    'adevo mas grav vis':  {'name': 'Energy Wall',        'vocs': {1,2,5,6}, 'ml': 18, 'mana': 250, 'prem': False},
    'adevo mas hur':       {'name': 'Explosion',          'vocs': {1,2,5,6}, 'ml': 12, 'mana': 180, 'prem': False},
    'adevo grav flam':     {'name': 'Fire Field',         'vocs': {1,2,5,6}, 'ml': 3,  'mana': 60,  'prem': False},
    'adevo mas grav flam': {'name': 'Fire Wall',          'vocs': {1,2,5,6}, 'ml': 13, 'mana': 200, 'prem': False},
    'adevo mas flam':      {'name': 'Firebomb',           'vocs': {1,2,5,6}, 'ml': 9,  'mana': 150, 'prem': False},
    'exori flam':          {'name': 'Flame Strike',       'vocs': {1,2,5,6}, 'ml': 3,  'mana': 20,  'prem': True},
    'exori mort':          {'name': 'Force Strike',       'vocs': {1,2,5,6}, 'ml': 2,  'mana': 20,  'prem': True},
    'adori frigo':         {'name': 'Frost Magic Missile','vocs': {1,2,5,6}, 'ml': 30, 'mana': 90,  'prem': False},
    'adori gran flam':     {'name': 'Great Fireball',     'vocs': {1,2,5,6}, 'ml': 9,  'mana': 120, 'prem': False},
    'exori frigo':         {'name': 'Ice Strike',         'vocs': {1,2,5,6}, 'ml': 6,  'mana': 25,  'prem': True},
    'exevo frigo hur':     {'name': 'Ice Wave',           'vocs': {1,2,5,6}, 'ml': 40, 'mana': 130, 'prem': True},
    'adevo grav pox':      {'name': 'Poison Field',       'vocs': {1,2,5,6}, 'ml': 2,  'mana': 50,  'prem': False},
    'adevo mas grav pox':  {'name': 'Poison Wall',        'vocs': {1,2,5,6}, 'ml': 11, 'mana': 160, 'prem': False},
    'adevo res flam':      {'name': 'Soulfire',           'vocs': {1,2,5,6}, 'ml': 13, 'mana': 150, 'prem': True},
    'utani gran hur':      {'name': 'Strong Haste',       'vocs': {1,2,5,6}, 'ml': 8,  'mana': 100, 'prem': True},
    'exani res':           {'name': 'Summon Call',        'vocs': {1,2,5,6}, 'ml': 26, 'mana': None,'prem': True},  # var
    'utevo res':           {'name': 'Summon Creature',    'vocs': {1,2,5,6}, 'ml': 16, 'mana': None,'prem': False}, # var
    'utevo vis lux':       {'name': 'Ultimate Light',     'vocs': {1,2,5,6}, 'ml': 12, 'mana': 140, 'prem': True},

    # --- Sorcerer only ---
    'exeta vis':           {'name': 'Enchant Staff',      'vocs': {1,5}, 'ml': 22, 'mana': 80,  'prem': True},
    'exevo vis lux':       {'name': 'Energy Beam',        'vocs': {1,5}, 'ml': 10, 'mana': 100, 'prem': False},
    'exevo mort hur':      {'name': 'Energy Wave',        'vocs': {1,5}, 'ml': 20, 'mana': 250, 'prem': True},
    'adevo mas vis':       {'name': 'Energybomb',         'vocs': {1,5}, 'ml': 18, 'mana': 220, 'prem': True},
    'exevo flam hur':      {'name': 'Fire Wave',          'vocs': {1,5}, 'ml': 7,  'mana': 80,  'prem': False},
    'exevo gran vis lux':  {'name': 'Great Energy Beam',  'vocs': {1,5}, 'ml': 14, 'mana': 200, 'prem': False},
    'adevo grav tera':     {'name': 'Magic Wall',         'vocs': {1,5}, 'ml': 14, 'mana': 250, 'prem': True},
    'adori vita vis':      {'name': 'Sudden Death',       'vocs': {1,5}, 'ml': 25, 'mana': 220, 'prem': False},
    'exevo gran mas vis':  {'name': 'Ultimate Explosion', 'vocs': {1,5}, 'ml': 40, 'mana': 800, 'prem': True},

    # --- Druid only ---
    'adana pox':           {'name': 'Antidote Rune',      'vocs': {2,6}, 'ml': 5,  'mana': 50,  'prem': False},
    'adevo ina':           {'name': 'Chameleon',          'vocs': {2,6}, 'ml': 11, 'mana': 150, 'prem': False},
    'adeta sio':           {'name': 'Convince Creature',  'vocs': {2,6}, 'ml': 10, 'mana': 100, 'prem': False},
    'adevo res pox':       {'name': 'Envenom',            'vocs': {2,6}, 'ml': 7,  'mana': 100, 'prem': True},
    'exevo pan':           {'name': 'Food',               'vocs': {2,3,6,7}, 'ml': 0, 'mana': 30, 'prem': False},  # Druid+Paladin
    'exura sio':           {'name': 'Heal Friend',        'vocs': {2,6}, 'ml': 7,  'mana': 70,  'prem': True},
    'adura gran':          {'name': 'Intense Healing Rune','vocs': {2,6}, 'ml': 4,  'mana': 60,  'prem': False},
    'exevo mas vita':      {'name': 'Mass Growth',        'vocs': {2,6}, 'ml': 60, 'mana': 880, 'prem': True},
    'exura gran mas res':  {'name': 'Mass Healing',       'vocs': {2,6}, 'ml': 19, 'mana': 150, 'prem': True},
    'utura mas res':       {'name': 'Mass Purification',  'vocs': {2,6}, 'ml': 36, 'mana': 240, 'prem': True},
    'adana ani':           {'name': 'Paralyze',           'vocs': {2,6}, 'ml': 35, 'mana': 600, 'prem': True},
    'exevo gran mas pox':  {'name': 'Poison Storm',       'vocs': {2,6}, 'ml': 28, 'mana': 600, 'prem': True},
    'adevo mas pox':       {'name': 'Poisonbomb',         'vocs': {2,6}, 'ml': 8,  'mana': 130, 'prem': True},
    'utura sio':           {'name': 'Purification',       'vocs': {2,6}, 'ml': 23, 'mana': 70,  'prem': True},
    'exana kor':           {'name': 'Revitalize',         'vocs': {2,6}, 'ml': 8,  'mana': 50,  'prem': False},
    'adura vita':          {'name': 'Ultimate Healing Rune','vocs': {2,6}, 'ml': 11, 'mana': 100, 'prem': False},
    'exana mas mort':      {'name': 'Undead Legion',      'vocs': {2,6}, 'ml': 15, 'mana': 400, 'prem': True},
    # NOTE: user's spec said 'exevo grav vita' but server uses 'adevo grav vita' (assumed typo).
    'adevo grav vita':     {'name': 'Wild Growth',        'vocs': {2,6}, 'ml': 13, 'mana': 220, 'prem': True},

    # --- Paladin only ---
    'exevo con':           {'name': 'Conjure Arrow',      'vocs': {3,7}, 'ml': 2,  'mana': 40,  'prem': False},
    'exevo con mort':      {'name': 'Conjure Bolt',       'vocs': {3,7}, 'ml': 6,  'mana': 70,  'prem': True},
    'exeta con':           {'name': 'Enchant Spear',      'vocs': {3,7}, 'ml': 12, 'mana': 120, 'prem': True},
    'exevo con flam':      {'name': 'Explosive Arrow',    'vocs': {3,7}, 'ml': 10, 'mana': 120, 'prem': False},
    'exevo con pox':       {'name': 'Poisoned Arrow',     'vocs': {3,7}, 'ml': 5,  'mana': 70,  'prem': False},
    'exevo con vis':       {'name': 'Power Bolt',         'vocs': {3,7}, 'ml': 14, 'mana': 200, 'prem': True},

    # --- Knight only ---
    'exori':               {'name': 'Berserk',            'vocs': {4,8}, 'ml': 5,  'mana': None,'prem': True},  # var
    'exeta res':           {'name': 'Challenge',          'vocs': {4,8}, 'ml': 4,  'mana': 60,  'prem': True},
}

# ---------- Rune charges (keyed by lowercase spell NAME as in spells.xml) ----------
RUNE_CHARGES = {
    'light magic missile':   10,
    'heavy magic missile':   10,
    'frost magic missile':   5,    # = user "Icicle"
    'fireball':              5,
    'soulfire':              5,
    'sudden death':          1,
    'great fireball':        4,
    'explosion':             6,
    'fire field':            3,
    'energy field':          3,
    'poison field':          3,
    'firebomb':              2,
    'energybomb':            2,
    'poisonbomb':            2,
    'fire wall':             4,
    'energy wall':           4,
    'poison wall':           4,
    'intense healing rune':  1,
    'ultimate healing rune': 1,
    'antidote rune':         1,    # = user "Cure Poison" rune
    'magic wall':            3,
    'destroy field':         3,
    'desintegrate':          3,    # spelling in spells.xml ("Desintegrate"); user uses "Disintegrate"
    'paralyze':              1,
    'chameleon':             1,
    'animate dead':          1,
    'convince creature':     1,
    'wild growth':           2,
}

# Alternative names that NPC scripts may use (NPC name -> canonical spells.xml name)
NPC_NAME_ALIASES = {
    'cure poison rune': 'antidote rune',
    'fire bomb':        'firebomb',
    'energy bomb':      'energybomb',
    'poison bomb':      'poisonbomb',
    'paralyse':         'paralyze',
    'disintegrate':     'desintegrate',
    'chameleon':        'chameleon',
}

VOC_NAME_TO_ID = {
    'sorcerer': 1, 'druid': 2, 'paladin': 3, 'knight': 4,
    'master sorcerer': 5, 'elder druid': 6, 'royal paladin': 7, 'elite knight': 8,
}

# ---------- Helpers ----------

def backup(path: Path):
    bak = path.with_suffix(path.suffix + ".bak")
    if not bak.exists():
        shutil.copy(path, bak)

def whitelist_lookup_by_name(name: str):
    """Find whitelist entry by spell name (case-insensitive)."""
    if not name:
        return None
    target = name.lower()
    target = NPC_NAME_ALIASES.get(target, target)
    for words, spec in WHITELIST.items():
        if spec['name'].lower() == target:
            return (words, spec)
    return None

# ---------- Phase 1: spells.xml ----------

def update_attr(s: str, attr: str, value: str) -> str:
    """Set attr="value" inside an XML start-tag fragment (without closing '>').
    Updates in place if present; otherwise appends at the end."""
    pat = re.compile(rf'\b{re.escape(attr)}="[^"]*"')
    repl = f'{attr}="{value}"'
    if pat.search(s):
        return pat.sub(repl, s, count=1)
    return s.rstrip() + ' ' + repl

def parse_attrs(line: str) -> dict:
    return dict(re.findall(r'\b(\w+)="([^"]*)"', line))

def process_spells_xml():
    raw = SPELLS_XML.read_text(encoding='utf-8', errors='replace')
    backup(SPELLS_XML)

    # We work block-wise. A block is either a self-closing tag or an opening->closing pair.
    # Find every <instant ...> .. </instant>, <conjure ...> .. </conjure>, <rune ...>(/>) or matching pair.

    out = []
    i = 0
    stats = {'updated_instant': 0, 'updated_rune': 0, 'commented': 0, 'rune_charges_set': 0}
    missing = set(WHITELIST.keys())  # words that we want to find in spells.xml

    BLOCK_RE = re.compile(r'<(instant|conjure|rune)\b([^>]*?)(/?)>', re.IGNORECASE)

    while i < len(raw):
        m = BLOCK_RE.search(raw, i)
        if not m:
            out.append(raw[i:])
            break
        out.append(raw[i:m.start()])
        tag = m.group(1).lower()
        attrs_text = m.group(2)
        self_closing = m.group(3) == '/'

        # Find the END of this block (whole inner XML content + closing tag if not self-closing)
        if self_closing:
            block_end = m.end()
        else:
            close_tag = f'</{tag}>'
            close_idx = raw.find(close_tag, m.end())
            if close_idx == -1:
                # malformed; just emit and continue
                out.append(raw[m.start():m.end()])
                i = m.end()
                continue
            block_end = close_idx + len(close_tag)

        block = raw[m.start():block_end]
        attrs = parse_attrs(attrs_text)
        words = (attrs.get('words') or '').lower().strip()
        name  = (attrs.get('name')  or '').lower().strip()

        action = 'comment'  # default
        wl_words, wl_spec = None, None

        # NEVER touch monster-internal spells: they use words="###N" (uncastable
        # by players) and live under script="monster/...". Stripping them breaks
        # every monster that references them by name in their XML.
        script_attr = (attrs.get('script') or '').lower()
        if words.startswith('###') or script_attr.startswith('monster/'):
            action = 'keep'

        # Whitelist match: <instant>/<conjure> by words, <rune> by name
        elif tag in ('instant', 'conjure'):
            if words and words in WHITELIST:
                wl_words, wl_spec = words, WHITELIST[words]
                action = 'update'
        elif tag == 'rune':
            # Match <rune> tags by name to RUNE_CHARGES.
            # A <rune> tag is the USE-spell of a rune; we don't have whitelist data
            # for it (whitelist is conjure-side), but we want to keep runes whose
            # name matches a whitelisted conjure (e.g., conjure "Antidote Rune"
            # exists -> keep <rune name="Antidote Rune">).
            canon = NPC_NAME_ALIASES.get(name, name)
            keep = False
            for spec in WHITELIST.values():
                if spec['name'].lower() == canon:
                    keep = True; break
            if keep:
                action = 'update_rune'
            else:
                action = 'comment'

        if action == 'keep':
            out.append(block)

        elif action == 'update' and wl_spec:
            missing.discard(wl_words)
            tag_text = block.split('>', 1)[0]    # everything before first '>'
            rest     = block[len(tag_text):]     # the '>' + body + close tag
            # Update mana
            if wl_spec['mana'] is not None:
                tag_text = update_attr(tag_text, 'mana', str(wl_spec['mana']))
            # Update maglv (magic level)
            tag_text = update_attr(tag_text, 'maglv', str(wl_spec['ml']))
            # Update prem
            tag_text = update_attr(tag_text, 'prem', '1' if wl_spec['prem'] else '0')
            block = tag_text + rest
            stats['updated_instant'] += 1
            out.append(block)

        elif action == 'update_rune':
            # Update <rune charges="N"> for whitelisted rune spell names
            canon = NPC_NAME_ALIASES.get(name, name)
            if canon in RUNE_CHARGES:
                tag_text = block.split('>', 1)[0]
                rest     = block[len(tag_text):]
                tag_text = update_attr(tag_text, 'charges', str(RUNE_CHARGES[canon]))
                block = tag_text + rest
                stats['rune_charges_set'] += 1
            stats['updated_rune'] += 1
            out.append(block)

        else:
            # Wrap the whole block in an XML comment; preserve indentation if any
            note = f'<!-- {DEACT_NOTE} -->\n\t<!-- {block.replace("--", "- -")} -->'
            stats['commented'] += 1
            out.append(note)

        i = block_end

    SPELLS_XML.write_text(''.join(out), encoding='utf-8')

    print(f"[spells.xml] updated_instant={stats['updated_instant']}  "
          f"updated_rune={stats['updated_rune']}  "
          f"rune_charges_set={stats['rune_charges_set']}  "
          f"commented={stats['commented']}")
    if missing:
        print(f"[spells.xml] MISSING from spells.xml ({len(missing)} whitelisted words):")
        for w in sorted(missing):
            print(f"   {w!r}  ({WHITELIST[w]['name']})")
    return missing

# ---------- Phase 2: NPC spell shop scripts ----------

NPC_ENTRY_RE = re.compile(
    r'^(\s*)(\[\d+\]\s*=\s*\{.*\bspell\s*=\s*"([^"]+)".*\}\s*,?)\s*$'
)

def process_npc_scripts():
    total_updated = 0
    total_commented = 0
    for path in sorted(NPC_SPELL_DIR.glob("*.lua")):
        text = path.read_text(encoding='utf-8', errors='replace')
        backup(path)
        new_lines = []
        commented_here = 0
        for line in text.splitlines(keepends=True):
            m = NPC_ENTRY_RE.match(line)
            if not m:
                new_lines.append(line); continue
            indent, body, spell_name = m.group(1), m.group(2), m.group(3)
            wl = whitelist_lookup_by_name(spell_name)
            if wl is None:
                # not whitelisted -> comment out (preserve indent)
                if not body.startswith('--'):
                    new_lines.append(f"{indent}-- {DEACT_NOTE}\n")
                    new_lines.append(f"{indent}-- {body}\n")
                    commented_here += 1
                else:
                    new_lines.append(line)
            else:
                # whitelisted: leave as-is for now (vocations handled by spells.xml)
                new_lines.append(line)
        if commented_here:
            path.write_text(''.join(new_lines), encoding='utf-8')
            total_commented += commented_here
            print(f"[NPC] {path.name}: commented {commented_here}")
        total_updated += 1
    print(f"[NPC] {total_updated} files scanned; {total_commented} entries commented total")

# ---------- Phase 3: conjure script counts ----------

def process_conjure_scripts():
    """Run after Phase 1; reads spells.xml <rune charges> and re-aligns conjure counts."""
    raw = SPELLS_XML.read_text(encoding='utf-8', errors='replace')
    rune_id_charges = {}
    for m in re.finditer(r'<rune\b[^/>]*?\bid="(\d+)"[^/>]*?\bcharges="(\d+)"', raw):
        rune_id_charges[int(m.group(1))] = int(m.group(2))

    instants = re.findall(r'<instant\b[^>]*?\bscript="(conjuring/[^"]+)"', raw)
    CONJURE_CALL = re.compile(r'(creature:conjureItem\((\d+),\s*(\d+),\s*)(\d+)(\))')

    updated = 0
    for rel in instants:
        path = ROOT / "data" / "spells" / "scripts" / rel
        if not path.exists():
            continue
        s = path.read_text(encoding='utf-8')
        m = CONJURE_CALL.search(s)
        if not m:
            continue
        cid = int(m.group(3))
        if cid not in rune_id_charges:
            continue
        new_count = rune_id_charges[cid]
        old_count = int(m.group(4))
        if old_count == new_count:
            continue
        backup(path)
        s2 = CONJURE_CALL.sub(lambda mm: mm.group(1) + str(new_count) + mm.group(5), s, count=1)
        path.write_text(s2, encoding='utf-8')
        print(f"[conjure] {rel}: id={cid} {old_count} -> {new_count}")
        updated += 1
    print(f"[conjure] {updated} script(s) re-aligned")

# ---------- Run ----------

print(f"\n=== Applying spell whitelist ({NOTE_DATE}) ===\n")
print("PHASE 1: spells.xml")
missing = process_spells_xml()
print("\nPHASE 2: NPC spell scripts")
process_npc_scripts()
print("\nPHASE 3: conjure script counts")
process_conjure_scripts()
print("\nDone. Backups written next to each modified file (.bak).")
