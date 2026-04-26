"""
Phase 2: REMOVE all non-7.72 loot entries from monster XMLs.

The user wants pure 7.72 loot — no aliases mapping post-7.72 items to lookalikes.

Steps:
1. Revert the auto-added section in items.xml (the alias attempt didn't work
   anyway because the engine emits "Duplicate item with id: N" warnings and
   skips entries whose ID already has a name).
2. Build the canonical 7.72 valid set from items.xml (4883 IDs + their names).
3. Walk every monster XML. For each <item id=N> or <item name=X>:
   - If id/name doesn't resolve in items.xml -> drop the entry entirely.
   - If it's a container with <inside>, recurse on children.
4. Result: zero "Unknown loot item" + zero "Duplicate item" warnings.
"""
import os, re

ROOT = os.path.dirname(os.path.abspath(__file__))
ITEMS_XML = os.path.join(ROOT, 'data', 'items', 'items.xml')


def step1_revert_items_xml():
    """Strip the auto-added alias section from items.xml."""
    txt = open(ITEMS_XML, 'r', encoding='utf-8').read()
    # Remove the block we inserted (between our marker comments)
    pattern = re.compile(
        r'\n*\t<!-- =+ Auto-added: OTX-imported loot aliases =+ -->\n.*?'
        r'\n*\t<!-- =+ Auto-added: OTX-imported items.otb IDs =+ -->\n.*?(?=\n</items>)',
        re.DOTALL,
    )
    new = pattern.sub('', txt)
    if new == txt:
        # Maybe the pattern is slightly different; try a looser match
        pattern2 = re.compile(
            r'\n*\t<!-- =+ Auto-added.*?=+ -->\n(?:\t<item[^/]*/>\n)+',
            re.DOTALL,
        )
        new = pattern2.sub('', txt)
    open(ITEMS_XML, 'w', encoding='utf-8').write(new)
    return len(txt) - len(new)


def step2_build_valid_set():
    """Return (valid_ids: set[int], valid_names: set[str-lowercase])."""
    txt = open(ITEMS_XML, 'r', encoding='utf-8').read()
    valid_ids = set()
    valid_names = set()
    for m in re.finditer(r'<item\s+id="(\d+)"', txt):
        valid_ids.add(int(m.group(1)))
    for m in re.finditer(r'<item\s+id="\d+"[^>]*\sname="([^"]+)"', txt):
        valid_names.add(m.group(1).lower())
    return valid_ids, valid_names


def step3_clean_monster_xmls(valid_ids, valid_names):
    """Walk every monster XML and drop <item> tags whose id/name is unknown."""
    monster_dir = os.path.join(ROOT, 'data', 'monster')

    item_open_re = re.compile(
        r'<item\s+(?:id="(\d+)"|name="([^"]+)")[^>]*?(/?)>'
    )

    files_changed = 0
    items_dropped = 0

    for root, _, files in os.walk(monster_dir):
        for f in files:
            if not f.endswith('.xml'):
                continue
            path = os.path.join(root, f)
            try:
                txt = open(path, 'r', encoding='utf-8').read()
            except UnicodeDecodeError:
                txt = open(path, 'r', encoding='latin-1').read()

            new_txt, dropped = clean_monster_xml(txt, valid_ids, valid_names)
            if dropped > 0:
                files_changed += 1
                items_dropped += dropped
                open(path, 'w', encoding='utf-8').write(new_txt)

    return files_changed, items_dropped


def clean_monster_xml(txt, valid_ids, valid_names):
    """
    Remove every <item ...>...</item> or <item .../> whose id/name is unknown.
    For containers (with <inside>), recurse: keep the container if valid,
    only strip invalid children.
    Returns (new_text, count_of_dropped_items).
    """
    # Strategy: tokenize by lines and use a state machine for nested items.
    # Each <item> tag either self-closes (/>) or has a matching </item>.
    # We'll process the file with a regex that finds ALL <item ...> and decide.

    out = []
    i = 0
    dropped = 0
    n = len(txt)

    while i < n:
        # Find next <item or </item>
        m = re.search(r'<item\s+([^/>]*?)(/?)>|</item>', txt[i:])
        if not m:
            out.append(txt[i:])
            break
        # Append everything up to the match
        out.append(txt[i:i + m.start()])
        attrs_or_close = m.group(0)
        if attrs_or_close == '</item>':
            out.append(attrs_or_close)
            i += m.end()
            continue

        # It's an <item ...>
        attrs = m.group(1)
        is_self_closing = m.group(2) == '/'

        # Extract id or name
        idm = re.search(r'\bid="(\d+)"', attrs)
        nm = re.search(r'\bname="([^"]+)"', attrs)

        is_valid = False
        if idm:
            try:
                is_valid = int(idm.group(1)) in valid_ids
            except ValueError:
                is_valid = False
        elif nm:
            is_valid = nm.group(1).lower() in valid_names
        else:
            # No id/name? keep as-is.
            is_valid = True

        if is_self_closing:
            if is_valid:
                out.append(attrs_or_close)
            else:
                dropped += 1
                # Skip; also remove trailing comment/whitespace until newline
                rest = txt[i + m.end():]
                trail = re.match(r'[ \t]*(?:<!--[^>]*-->)?[ \t]*\n?', rest)
                if trail:
                    i += m.end() + trail.end()
                    continue
            i += m.end()
        else:
            # Container <item>...</item>: find matching </item>, accounting for nesting
            start_at = i + m.end()
            depth = 1
            j = start_at
            while j < n and depth > 0:
                inner = re.search(r'<item\s+[^/>]*?(/?)>|</item>', txt[j:])
                if not inner:
                    break
                tok = inner.group(0)
                tok_self = inner.group(1) == '/'
                if tok == '</item>':
                    depth -= 1
                elif tok.startswith('<item') and not tok_self:
                    depth += 1
                # tok_self=True items don't affect depth
                j += inner.end()
            block_end = j  # j points just past matching </item>

            inner_block = txt[start_at:block_end]

            if is_valid:
                # Keep wrapper, but recurse into inner_block to clean children
                cleaned_inner, inner_dropped = clean_monster_xml(
                    inner_block, valid_ids, valid_names
                )
                dropped += inner_dropped
                out.append(attrs_or_close)
                out.append(cleaned_inner)
                # Already consumed up to block_end (including </item>)
                i += m.end() + (block_end - start_at)
            else:
                # Drop entire block
                dropped += 1
                # Skip trailing whitespace/newline after </item>
                rest_after = txt[block_end:]
                trail = re.match(r'[ \t]*\n?', rest_after)
                if trail:
                    i = block_end + trail.end()
                else:
                    i = block_end

    return ''.join(out), dropped


if __name__ == '__main__':
    print('=== Step 1: Revert items.xml auto-added aliases ===')
    bytes_removed = step1_revert_items_xml()
    print(f'  Removed {bytes_removed} bytes from items.xml.')

    print('\n=== Step 2: Build valid 7.72 set from items.xml ===')
    ids, names = step2_build_valid_set()
    print(f'  {len(ids)} valid IDs, {len(names)} valid names.')

    print('\n=== Step 3: Strip unknown loot entries from monster XMLs ===')
    files, dropped = step3_clean_monster_xmls(ids, names)
    print(f'  Modified {files} files, dropped {dropped} unknown <item> entries.')

    print('\nAll done. Restart server to verify clean log.')
