"""
One-shot script to clean ALL "Unknown loot item" warnings.

Strategy:
- 109 unknown NAMES -> add `<item id="<7.72 ID>" name="<unknown>"/>` aliases to items.xml.
  Lookup by name returns the 7.72 ID, monster drops the 7.72 item.
- 80 unknown IDs that ARE in items.otb -> add `<item id="N" name="loot_N"/>` to items.xml.
- 60 unknown IDs that are NOT in items.otb -> bulk-replace with id="2148" in monster XMLs.
"""
import os, re, json

ROOT = os.path.dirname(os.path.abspath(__file__))
ITEMS_XML = os.path.join(ROOT, 'data', 'items', 'items.xml')

# Mapping: unknown post-7.72 name -> 7.72 ID equivalent that exists in items.xml
NAME_MAPPING = {
    # Potions -> empty potion vial (2006)
    'health potion': 2273, 'great health potion': 2273, 'strong health potion': 2273,
    'ultimate health potion': 2273, 'mana potion': 2273, 'great mana potion': 2273,
    'strong mana potion': 2273, 'great spirit potion': 2273, 'mastermind potion': 2273,
    'berserk potion': 2273, 'bullseye potion': 2273, 'blood preservation': 2273,

    # Wands/Rods -> existing 7.72 rods/wands
    'amber staff': 2185, 'wand of decay': 2185, 'wand of starstorm': 2185,
    'wand of draconia': 2185, 'lunar staff': 2186, 'springsprout rod': 2182,
    'dragonbone staff': 2185, 'hailstorm rod': 2183, 'terra rod': 2182,
    'shadow sceptre': 2185, 'diamond sceptre': 2185,

    # Weapons
    'titan axe': 2452, 'angelic axe': 2452, 'glorious axe': 2452,
    'mercenary sword': 2393, 'crystal sword': 2392, 'composite hornbow': 2455,
    'spiked squelcher': 2391, 'bonebreaker': 2387, 'nightmare blade': 2390,
    'sabretooth': 2148,

    # Armor / Outfits
    'paladin armor': 2476, 'belted cape': 2660, 'cultish robe': 2660,
    'focus cape': 2660, 'hibiscus dress': 2660, 'magma boots': 2643,
    'glacier shoes': 2643, 'rope belt': 2120, 'pair of earmuffs': 2461,
    'batwing hat': 2323, 'broken gladiator shield': 2511,

    # Materials/components -> generic gold/gems
    'magic sulphur': 2147, 'iron ore': 2148, 'nail': 2148, 'gear wheel': 2148,
    'gear crystal': 2148, 'frosty heart': 2150, 'mutated bat ear': 2148,
    'mutated rat tail': 2148, 'mutated flesh': 2148, 'bat wing': 2148,
    'striped fur': 2148, 'wyrm scale': 2148, 'haunted piece of wood': 2148,
    'cyclops toe': 2148, 'pelvis bone': 5928, 'vampire teeth': 2148,
    'small enchanted ruby': 2147, 'small enchanted amethyst': 2150,
    'small topaz': 2150, 'gold ingot': 2157, 'glob of acid slime': 2148,
    'glob of mercury': 2148, 'glob of tar': 2148, 'lump of earth': 2148,
    'clay lump': 2148, 'shard': 2148,

    # Amulets/jewelry
    'lightning pendant': 2125, 'shockwave amulet': 2125, 'sacred tree amulet': 2125,
    'terra amulet': 2125, 'jewelled backpack': 1988,

    # Quest/special items -> placeholder
    'demonic essence': 2148, 'concentrated demonic blood': 2148,
    'crystal of power': 2148, 'crystal of focus': 2148, 'midnight shard': 2148,
    'essence of a bad dream': 2148, 'broken key ring': 2148, 'cultish symbol': 2148,
    'cultish mask': 2148, 'pirate voodoo doll': 2114, 'royal tapestry': 2148,
    'silky tapestry': 2148, 'red piece of cloth': 2148, 'blood goblet': 2148,
    'black skull': 2148, 'half-eaten brain': 2148, 'scythe leg': 2148,
    'strand of medusa hair': 2148, 'terra mantle': 2660, 'terra legs': 2649,

    # Spellbooks
    'spellbook of enlightenment': 2175, 'spellbook of mind control': 2175,

    # Food / consumable
    'bar of chocolate': 2687, 'raspberry': 2674, 'peanut': 2674, 'potato': 2685,
    'rum flask': 2006, 'brown flask': 2006, "flask of warrior's sweat": 2006,
    'nomad parchment': 2598, 'dirty turban': 2461,

    # Misc
    'boggy dreads': 2148, "dragon's tail": 2148,
}

IDS_IN_OTB = [5462, 5544, 5553, 5669, 5706, 5710, 5741, 5792, 5801, 5806, 5810, 5812, 5879,
              5895, 5911, 5913, 5917, 5918, 5926, 5927, 5929, 5944, 6087, 6088, 6089, 6090,
              6092, 6095, 6096, 6097, 6098, 6126, 6300, 6500, 6533, 6541, 7158, 7159, 7290,
              7343, 7364, 7368, 7378, 7379, 7381, 7383, 7387, 7398, 7407, 7408, 7419, 7424,
              7426, 7427, 7432, 7437, 7441, 7449, 7457, 7459, 7460, 7461, 7462, 7463, 7464,
              7588, 7589, 7590, 7591, 7618, 7620, 7632, 7733, 7888, 7892, 7896, 7897, 7902,
              7909, 7910]

IDS_NOT_IN_OTB = [8472, 8473, 8870, 8871, 8878, 8911, 9808, 9809, 9810, 9812, 9837, 9979,
                  10103, 10220, 10550, 10555, 10556, 10557, 10559, 10561, 10575, 10578,
                  10580, 10583, 10601, 10609, 11196, 11207, 11209, 11215, 11219, 11224,
                  11227, 11238, 11240, 11245, 11301, 11302, 11303, 11304, 11305, 11307,
                  11309, 11323, 11355, 11366, 11367, 11368, 11372, 11374, 12411, 12443,
                  12444, 12445, 12446, 12447, 12448, 12608, 13757, 33528]


def step1_validate_targets():
    """Verify NAME_MAPPING targets all exist with a name in items.xml."""
    items_xml = open(ITEMS_XML, 'r', encoding='utf-8').read()
    known_ids_with_name = set()
    for m in re.finditer(r'<item\s+id="(\d+)"\s+name="', items_xml):
        known_ids_with_name.add(int(m.group(1)))

    bad = []
    for n, tid in NAME_MAPPING.items():
        if tid not in known_ids_with_name:
            bad.append((n, tid))
    return bad


def step2_add_aliases_and_ids():
    """Add NAME_MAPPING aliases and IDS_IN_OTB entries to items.xml."""
    items_xml = open(ITEMS_XML, 'r', encoding='utf-8').read()

    # Build new entries block
    new_entries = ['', '\t<!-- ===== Auto-added: OTX-imported loot aliases ===== -->']
    for name in sorted(NAME_MAPPING.keys()):
        target = NAME_MAPPING[name]
        new_entries.append(f'\t<item id="{target}" name="{name}"/>')

    new_entries.append('')
    new_entries.append('\t<!-- ===== Auto-added: OTX-imported items.otb IDs ===== -->')
    for iid in sorted(IDS_IN_OTB):
        new_entries.append(f'\t<item id="{iid}" name="loot_{iid}"/>')

    # Insert before closing </items>
    insert_block = '\n'.join(new_entries) + '\n'
    if '</items>' not in items_xml:
        raise RuntimeError('No </items> closing tag found')
    out = items_xml.replace('</items>', insert_block + '</items>', 1)

    open(ITEMS_XML, 'w', encoding='utf-8').write(out)
    return len(NAME_MAPPING) + len(IDS_IN_OTB)


def step3_replace_unsupported_ids_in_monsters():
    """Bulk-replace IDs not in items.otb with 2148 (gold coin) in all monster XMLs."""
    monster_dir = os.path.join(ROOT, 'data', 'monster')
    fix_set = {str(i) for i in IDS_NOT_IN_OTB}

    pattern = re.compile(r'(<item\s+id=")(\d+)(")')

    def sub(m):
        if m.group(2) in fix_set:
            return m.group(1) + '2148' + m.group(3)
        return m.group(0)

    total_files = 0
    total_subs = 0
    for root, _, files in os.walk(monster_dir):
        for f in files:
            if not f.endswith('.xml'):
                continue
            path = os.path.join(root, f)
            try:
                txt = open(path, 'r', encoding='utf-8').read()
            except UnicodeDecodeError:
                txt = open(path, 'r', encoding='latin-1').read()
            new, n = pattern.subn(sub, txt)
            if n > 0 and new != txt:
                open(path, 'w', encoding='utf-8').write(new)
                total_files += 1
                # Count how many were actually replaced (subn includes non-matches)
                # better: count the actual fix_set hits before/after
                before = sum(1 for m in pattern.finditer(txt) if m.group(2) in fix_set)
                after = sum(1 for m in pattern.finditer(new) if m.group(2) in fix_set)
                total_subs += before - after
    return total_files, total_subs


if __name__ == '__main__':
    print('=== Step 1: Validate NAME_MAPPING targets ===')
    bad = step1_validate_targets()
    if bad:
        print(f'  WARNING: {len(bad)} mappings point to IDs without name in items.xml:')
        for n, tid in bad:
            print(f'    "{n}" -> {tid}')
        print('  These will still be added but might fail at runtime.')
    else:
        print('  All targets valid.')

    print('\n=== Step 2: Add aliases + new IDs to items.xml ===')
    n = step2_add_aliases_and_ids()
    print(f'  Added {n} entries to items.xml.')

    print('\n=== Step 3: Replace unsupported IDs in monster XMLs ===')
    files, subs = step3_replace_unsupported_ids_in_monsters()
    print(f'  Modified {files} files, replaced {subs} ID references.')

    print('\nAll done. Restart server to verify.')
