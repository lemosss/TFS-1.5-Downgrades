"""
Merge OTX action/movement/talkaction/creaturescript/globalevent/spell entries
into TFS-format XMLs, normalizing the OTX format (`event="script" value="X"`)
to TFS format (`script="X"`).

Format normalizations:
  All categories: `event="script"\s+value="X"` -> `script="X"`
  movements only: `type="StepIn|StepOut|..."`  -> `event="StepIn|..."`
"""
import os, re

OTX = '../solebraserver/otserv1/data'
TFS = 'data'

CATEGORIES = [
    ('actions',          'actions',          'action',     '</actions>'),
    ('movements',        'movements',        'movevent',   '</movements>'),
    ('talkactions',      'talkactions',      'talkaction', '</talkactions>'),
    ('creaturescripts',  'creaturescripts',  'event',      '</creaturescripts>'),
    ('globalevents',     'globalevents',     'globalevent','</globalevents>'),
    # Spells skipped: TFS already has 103 spells with proper 7.72 incantations
    # ('adevo grav pox' etc); OTX uses descriptive names ('Poison Field') for
    # the same item IDs which would cause duplicate registrations.
    # ('spells',           'spells',           None,         '</spells>'),
]

# Movement event type values
MOVE_EVENT_TYPES = {'stepin', 'stepout', 'equip', 'deequip', 'additem', 'removeitem'}


def normalize_entry(line, is_movement):
    """Convert an OTX-format XML entry line to TFS format."""
    # Detect event-type up front: "script" (Lua file), "function" (built-in C++), or "buffer" (rare).
    m_event = re.search(r'\bevent="([^"]+)"', line)
    event_kind = m_event.group(1).lower() if m_event else None

    # 1) For movements: type="StepIn"  ->  event="StepIn"
    if is_movement:
        # OTX has event="script" + type="StepIn"; we want event="StepIn"
        m_type = re.search(r'\btype="([^"]+)"', line)
        if m_type and m_type.group(1).lower() in MOVE_EVENT_TYPES:
            # Drop the `type=` attribute (we'll replace event="script" with event="StepIn" below)
            line = re.sub(r'\s*type="[^"]+"', '', line, count=1)
            # Replace event="script" with event="StepIn"
            line = re.sub(r'\bevent="script"', f'event="{m_type.group(1)}"', line, count=1)
    else:
        # For non-movements, simply drop event="script" since we'll replace value= with script=.
        # For event="function" we keep both attributes (TFS reads them as-is).
        if event_kind == 'script':
            line = re.sub(r'\s*event="script"', '', line, count=1)

    # 2) value="X.lua" -> script="X.lua"  ONLY when this is a script entry.
    #    For event="function" value="houseBuy" we leave value= alone so the
    #    engine still routes it to the built-in C++ function.
    if event_kind != 'function' and 'script=' not in line:
        line = re.sub(r'\bvalue="([^"]+)"', r'script="\1"', line, count=1)

    return line


def extract_entries(xml_path, tag_name=None):
    """Extract individual entry lines from an OTX XML. tag_name=None = match all top-level <X .../> tags."""
    txt = open(xml_path, 'r', encoding='utf-8').read()
    # Strip XML decl + root open/close
    txt = re.sub(r'<\?xml[^>]*\?>', '', txt)
    txt = re.sub(r'</?\w+>\s*$', '', txt.strip())  # strip trailing root close
    txt = re.sub(r'^\s*<\w+>', '', txt.strip())   # strip leading root open
    # Strip XML comments (so we don't pick up disabled <event .../> entries)
    txt = re.sub(r'<!--.*?-->', '', txt, flags=re.DOTALL)

    if tag_name:
        # Match self-closing <tag .../> only — `[^>]*?` allows '/' inside
        # attribute values like words="/buyhouse" but stops at the '>' end.
        pat = rf'<{tag_name}\b[^>]*?/>'
    else:
        # Spells: rune, instant, conjure
        pat = r'<(?:rune|instant|conjure)\b[^>]*?/>'

    return re.findall(pat, txt)


def merge_category(folder, root_tag, tag_name, close_tag):
    otx_xml = os.path.join(OTX, folder, f'{folder}.xml')
    tfs_xml = os.path.join(TFS, folder, f'{folder}.xml')

    if not os.path.exists(otx_xml):
        print(f'  [{folder}] OTX xml not found, skip.')
        return 0
    if not os.path.exists(tfs_xml):
        print(f'  [{folder}] TFS xml not found, skip.')
        return 0

    is_movement = (folder == 'movements')

    otx_entries = extract_entries(otx_xml, tag_name)

    # Read TFS file to identify which scripts are already registered (avoid duplicates)
    tfs_txt = open(tfs_xml, 'r', encoding='utf-8').read()
    existing_scripts = set(re.findall(r'script="([^"]+)"', tfs_txt))

    # Normalize and dedup
    new_entries = []
    skipped_dup = 0
    for entry in otx_entries:
        normed = normalize_entry(entry, is_movement)
        # Pull the script= attribute
        m = re.search(r'\bscript="([^"]+)"', normed)
        if m and m.group(1) in existing_scripts:
            skipped_dup += 1
            continue
        new_entries.append(normed)

    if not new_entries:
        print(f'  [{folder}] no new entries (skipped {skipped_dup} dups)')
        return 0

    # Insert new entries before </root>
    block = '\n\n\t<!-- ===== Auto-imported from OTX ===== -->\n\t' + '\n\t'.join(new_entries) + '\n'
    new_tfs_txt = tfs_txt.replace(close_tag, block + close_tag, 1)
    open(tfs_xml, 'w', encoding='utf-8').write(new_tfs_txt)

    print(f'  [{folder}] +{len(new_entries)} new entries (skipped {skipped_dup} dups)')
    return len(new_entries)


total = 0
print('=== Merging OTX -> TFS XMLs ===')
for folder, root_tag, tag, close in CATEGORIES:
    total += merge_category(folder, root_tag, tag, close)

print(f'\nTotal entries merged: {total}')
