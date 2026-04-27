"""
Etapa H polish — remove duplicate OTX entries where TFS already covers the
itemid via a fromid/toid range or single individual id.

The engine emits 'Duplicate registered item with id: N' for every OTX
<action itemid="N"/> whose N is already covered by a TFS-native
<action fromid="X" toid="Y"/> range. Same problem in movements.xml.

Strategy:
1. Walk the XML and split entries into 'native' (everything before the
   `Auto-imported from OTX` marker) and 'imported' (after).
2. Collect every itemid covered by native entries (single + ranges).
3. For each imported entry, if its itemid (or every id in its range) is
   already covered, drop it.
4. If the imported entry has actionid/uniqueid/fromaid/toaid (action ids,
   not item ids), keep it — those are quest hooks unrelated to TFS items.
"""
import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))


def collect_native_itemids(text, marker):
    """Return set of itemids covered by entries BEFORE the OTX marker."""
    head, _, _ = text.partition(marker)
    covered = set()

    # itemid="N"
    for m in re.finditer(r'\bitemid="(\d+)"', head):
        covered.add(int(m.group(1)))

    # fromid="A" toid="B"
    for m in re.finditer(r'\bfromid="(\d+)"\s+toid="(\d+)"', head):
        a, b = int(m.group(1)), int(m.group(2))
        for i in range(min(a, b), max(a, b) + 1):
            covered.add(i)

    return covered


def entry_itemids(entry):
    """Return list of itemids referenced by an entry, or None if it
    only refers to actionid/uniqueid (i.e. quest hooks, not item registrations)."""
    if 'itemid=' not in entry and 'fromid=' not in entry:
        return None  # actionid/uniqueid only — leave alone

    ids = []
    m = re.search(r'\bitemid="(\d+)"', entry)
    if m:
        ids.append(int(m.group(1)))

    m = re.search(r'\bfromid="(\d+)"\s+toid="(\d+)"', entry)
    if m:
        a, b = int(m.group(1)), int(m.group(2))
        ids.extend(range(min(a, b), max(a, b) + 1))

    return ids if ids else None


def dedupe(xml_path, marker, tag_pattern):
    txt = open(xml_path, 'r', encoding='utf-8').read()
    if marker not in txt:
        return 0  # nothing imported yet

    native_ids = collect_native_itemids(txt, marker)

    # Process each imported entry; keep or drop
    pre, sep, post = txt.partition(marker)

    dropped = 0
    def replace(m):
        nonlocal dropped
        entry = m.group(0)
        ids = entry_itemids(entry)
        if ids is None:
            return entry  # no itemid — keep
        if all(i in native_ids for i in ids):
            dropped += 1
            return ''  # drop
        return entry

    new_post = re.sub(tag_pattern, replace, post)
    # Tidy up triple-blank lines left behind
    new_post = re.sub(r'\n\s*\n\s*\n+', '\n\n', new_post)

    if dropped == 0:
        return 0

    open(xml_path, 'w', encoding='utf-8').write(pre + sep + new_post)
    return dropped


if __name__ == '__main__':
    print('=== Dedup OTX-imported entries against TFS-native ranges ===')

    actions = os.path.join(ROOT, 'data', 'actions', 'actions.xml')
    n = dedupe(
        actions,
        '<!-- ===== Auto-imported from OTX ===== -->',
        r'<action\b[^>]*?/>\s*\n?',
    )
    print(f'  actions.xml: dropped {n} entries')

    movements = os.path.join(ROOT, 'data', 'movements', 'movements.xml')
    n = dedupe(
        movements,
        '<!-- ===== Auto-imported from OTX ===== -->',
        r'<movevent\b[^>]*?/>\s*\n?',
    )
    print(f'  movements.xml: dropped {n} entries')
