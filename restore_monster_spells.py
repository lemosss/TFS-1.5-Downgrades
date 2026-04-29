#!/usr/bin/env python3
"""
Restore monster spell registrations that the whitelist script wrongly commented.

Monster spells use words="###N" so players can't cast them — they are invoked
internally by monsters. They were never the user's whitelist target. Reverse the
DESATIVADO wrap for these specific entries.
"""
import re
from pathlib import Path

SPELLS_XML = Path(r"C:\Users\Lemos\Desktop\Realera TFS 1.5\data\spells\spells.xml")

raw = SPELLS_XML.read_text(encoding='utf-8', errors='replace')

# Match the whole DESATIVADO wrapper + a monster spell instant line.
# Wrapper format (from apply_spell_whitelist.py):
#   <!-- [DESATIVADO ...] -->
#   <!-- <instant ... words="###N" ... /> -->
WRAPPER_RE = re.compile(
    r'(\s*)<!--\s*\[DESATIVADO[^\n]*-->\s*\n'
    r'\s*<!--\s*(<instant\b[^>]*?\bwords="###\d+"[^>]*?/>)\s*-->\s*\n',
    re.IGNORECASE
)

count = 0
def unwrap(m):
    global count
    count += 1
    indent = m.group(1)
    inner  = m.group(2)
    return f'{indent}{inner}\n'

new_raw = WRAPPER_RE.sub(unwrap, raw)
SPELLS_XML.write_text(new_raw, encoding='utf-8')
print(f"Unwrapped {count} monster spell registrations")
