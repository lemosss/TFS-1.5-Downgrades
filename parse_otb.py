#!/usr/bin/env python3
"""Quick OTB parser - extract serverId/clientId for given server IDs."""
import struct
import sys
from pathlib import Path

OTB = Path(r"C:\Users\Lemos\Desktop\Realera OT\Realera TFS 1.5\data\items\items.otb")

ESC = 0xFD
NODE_START = 0xFE
NODE_END = 0xFF

def unescape(data):
    out = bytearray()
    i = 0
    while i < len(data):
        if data[i] == ESC:
            out.append(data[i+1])
            i += 2
        else:
            out.append(data[i])
            i += 1
    return bytes(out)

# OTB attribute IDs (from itemloader.h)
ITEM_ATTR_FIRST       = 0x10
ITEM_ATTR_SERVERID    = 0x10
ITEM_ATTR_CLIENTID    = 0x11
ITEM_ATTR_NAME        = 0x12
ITEM_ATTR_DESCR       = 0x13
ITEM_ATTR_SPEED       = 0x14
ITEM_ATTR_SLOT        = 0x15
ITEM_ATTR_MAXITEMS    = 0x16
ITEM_ATTR_WEIGHT      = 0x17
ITEM_ATTR_WEAPON      = 0x18
ITEM_ATTR_AMU         = 0x19
ITEM_ATTR_ARMOR       = 0x1A
ITEM_ATTR_MAGLEVEL    = 0x1B
ITEM_ATTR_MAGFIELDTYPE= 0x1C
ITEM_ATTR_WRITEABLE   = 0x1D
ITEM_ATTR_ROTATETO    = 0x1E
ITEM_ATTR_DECAY       = 0x1F
ITEM_ATTR_SPRITEHASH  = 0x20
ITEM_ATTR_MINIMAPCOLOR= 0x21
ITEM_ATTR_07          = 0x22
ITEM_ATTR_08          = 0x23
ITEM_ATTR_LIGHT       = 0x24
ITEM_ATTR_LIGHT2      = 0x2A
ITEM_ATTR_TOPORDER    = 0x2B
ITEM_ATTR_WAREID      = 0x2C

raw = OTB.read_bytes()

def parse_node(data, offset):
    """Returns (node_data, child_offsets, end_offset). Caller already consumed 0xFE."""
    pass

# Walk top-level: header byte 0x00 then root node 0xFE
# Real implementation: find nodes
# Simpler approach: find byte sequences for serverid attr in unescaped node bodies

# Parse properly: skip 4-byte header (version), then root node 0xFE
i = 4  # skip 4-byte file version header
assert raw[i] == NODE_START, f"Expected NODE_START at {i}, got {raw[i]:#x}"
i += 1
# Root node: type byte + flags(4) + attrs
i += 1  # type
i += 4  # flags
# Root has attributes block ending implicitly when child node starts (0xFE)
# Skip root attrs: read until we hit 0xFE
while raw[i] not in (NODE_START, NODE_END):
    if raw[i] == ESC:
        i += 2
        continue
    # attr_id(1) + datalen(2) + data
    attr = raw[i]; i += 1
    datalen = struct.unpack_from('<H', raw, i)[0]; i += 2
    i += datalen

# Now walk children (item records)
results = {}
target_ids = {2260, 2273, 2294, 2302, 2304, 2305, 2313, 2293, 2160, 2148}

def parse_item_node(start, end):
    """Parse a single item node body (after 0xFE, before its 0xFF). Returns dict of attrs."""
    body = unescape(raw[start:end])
    # body layout: type(1) + flags(4) + attrs[]
    if len(body) < 5:
        return None
    item_type = body[0]
    flags = struct.unpack_from('<I', body, 1)[0]
    p = 5
    attrs = {'type': item_type, 'flags': flags}
    while p < len(body):
        attr = body[p]; p += 1
        if p + 2 > len(body): break
        datalen = struct.unpack_from('<H', body, p)[0]; p += 2
        data = body[p:p+datalen]; p += datalen
        if attr == ITEM_ATTR_SERVERID:
            attrs['serverid'] = struct.unpack('<H', data)[0]
        elif attr == ITEM_ATTR_CLIENTID:
            attrs['clientid'] = struct.unpack('<H', data)[0]
        elif attr == ITEM_ATTR_NAME:
            attrs['name'] = data.decode('latin-1', errors='replace')
        elif attr == ITEM_ATTR_WEIGHT:
            attrs['weight'] = struct.unpack('<H', data)[0]
        elif attr == ITEM_ATTR_SPRITEHASH:
            attrs['sprhash'] = data.hex()
    return attrs

# Walk children: each child is 0xFE ... 0xFF (with escapes for 0xFD/0xFE/0xFF inside data)
# Need to scan respecting escape bytes
while i < len(raw):
    b = raw[i]
    if b == NODE_END:
        # end of root
        break
    if b != NODE_START:
        i += 1
        continue
    # Found item node start
    i += 1  # consume 0xFE
    start = i
    # Find matching 0xFF (escape-aware)
    while i < len(raw):
        c = raw[i]
        if c == ESC:
            i += 2
            continue
        if c == NODE_END:
            break
        if c == NODE_START:
            # nested node? items.otb has none typically
            break
        i += 1
    end = i
    if i < len(raw) and raw[i] == NODE_END:
        i += 1
    attrs = parse_item_node(start, end)
    if attrs and 'serverid' in attrs:
        sid = attrs['serverid']
        if sid in target_ids:
            results[sid] = attrs

for sid in sorted(target_ids):
    if sid in results:
        a = results[sid]
        print(f"server={sid:5d} client={a.get('clientid','?'):5d} type={a.get('type','?'):2d} flags={a.get('flags',0):#010x} weight={a.get('weight','-')}")
    else:
        print(f"server={sid:5d}  NOT FOUND in items.otb")
