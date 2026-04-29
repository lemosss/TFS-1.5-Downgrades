# Realera TFS 1.5 (8.0) — Notes

Working tree at `C:\Users\Lemos\Desktop\Realera TFS 1.5\` is a fresh build of
**Nekiro's TFS-1.5-Downgrades** branch `8.0`, populated with content copied
from `C:\Users\Lemos\Desktop\global 8.0\` (an old 2015 server distribution).

```
Realera TFS 1.5/
├── build/RelWithDebInfo/tfs.exe       compiled binary (vcpkg manifest)
├── src/                               C++ source (modified — see below)
├── data/                              Lua / XML content (mostly from global 8.0)
├── start.bat                          launcher (sets CWD, runs tfs.exe, pause)
├── parse_otb.py                       OTB inspector (find serverid/clientid)
├── fix_blank_rune_otb.py              one-shot OTB patcher (NOT applied — reverted)
├── fix_conjure_counts.py              syncs conjure script counts ↔ <rune charges>
└── (helper scripts from earlier passes: fix_loot.py, fix_conjures.py, etc.)
```

The project is **Realera 8.0 reborn on a modern engine**. The old fork at
`Desktop\Realera 8.0\` was 2015 era, missing libs/functions; we abandoned it.

---

## 1. Build

vcpkg manifest mode. `vcpkg.json` lists deps; CMake auto-installs via toolchain.

```
cmake --build "C:/Users/Lemos/Desktop/Realera TFS 1.5/build" \
      --config RelWithDebInfo --parallel 8 --target tfs
```

Output: `build/RelWithDebInfo/tfs.exe`. Runtime DLLs (`boost_*-vc143-mt-x64-1_90.dll`)
are next to the exe — they ship with vcpkg's bin output and must stay alongside.
Don't move them out (the 7.72 build doesn't have them because that vcpkg pulled
older static Boost; the 8.0 build pulls dynamic 1.90).

### Build fixes already committed in `src/`

**Boost.Asio modern API** (`connection.h/cpp`, `server.h/cpp`, `signals.h/cpp`,
`scheduler.h/cpp`, `otpch.h`):
- `io_service` → `io_context`
- `expires_from_now` → `expires_after`
- `io_context::work` → `executor_work_guard`
- `io_service.post(fn)` → `boost::asio::post(io, fn)`
- `address_v4::from_string` → `make_address_v4`
- `to_ulong()` → `to_uint()`

vcpkg's Boost 1.90 dropped all the deprecated names; the original Nekiro 8.0
branch was written against ~1.66.

### Runtime fixes already committed in `src/`

- **`database.cpp` SSL disable** — same as 7.72: libmariadb 3.3+ auto-enables TLS
  via the auth packet builder. Both flags needed:
  ```cpp
  my_bool ssl_off = 0;
  mysql_options(handle, MYSQL_OPT_SSL_ENFORCE, &ssl_off);
  mysql_options(handle, MYSQL_OPT_SSL_VERIFY_SERVER_CERT, &ssl_off);
  ```
  Without this, XAMPP MariaDB errors with "TLS/SSL error".

- **`iologindata.cpp:616` PlayerSex_t serialization** — `enum PlayerSex_t : uint8_t`
  was being serialized as a *char* by ostringstream, producing `☺` literally in the
  SQL update string ("invalid sex column" syntax error). Fix: cast to integer.
  ```cpp
  query << "`sex` = " << static_cast<uint16_t>(player->sex)
  ```

- **`protocolgame.cpp` shop packets — TIBIA 8.0 FORMAT** (this was the trade-window
  bug; required rebuild). The TFS upstream code was emitting 9.10+/9.73+ shapes:
  - `sendShop`: removed NPC name field (9.10+ only), changed item count from
    `uint16_t` to `uint8_t` (8.0 cap).
  - `sendSaleItemList`: changed money from `uint64_t` to `uint32_t` (uint64 is 9.73+).
  Without this fix the client errors with "InputMessage eof reached" silently
  and the shop window never opens.

- **`networkmessage.cpp:110-112` blank rune corruption** — see Section 7. One-line
  fix: `} else if (it.isRune() && it.charges > 0) {`

### Run

- `start.bat` in repo root: sets CWD, runs `tfs.exe`, pauses on exit.
- MySQL: XAMPP at `C:\xampp\`. Start with `C:\xampp\mysql_start.bat`.
  DB is **`realera15`**, root user, no password.
- Always `taskkill //F //IM tfs.exe` between starts (same orphan-instance trap as
  the OT/CLAUDE.md describes for the 7.72 server).

---

## 2. Database (`realera15`)

Migrated from old `realera` DB (kept the SQL dump, imported into new schema name).

```
account_id 1, name `1`, password sha1('lemos'), type 6 (GOD), premium until 2036
  ├─ player_id 1: ADM Lemos       (god flags, vocation 0/None, level 100)
  ├─ player_id 4: Lemos            (Paladin, level 8, in Rookgaard)
  ├─ player_id 5: MS Lemos         (Master Sorcerer, level 100, Thais)
  └─ player_id 6: ED Lemos         (Elder Druid, level 100, Thais)
```

- `accounts.password` = `char(40)` SHA-1 hex.
- `accounts.type` enum 1..6, **6 = GOD** (NOT 5 — `/i` etc. require type 6).
  We bumped from 5 → 6 mid-session because `/i blank rune` was failing.
- `accounts.premium_ends_at` = unix timestamp. Set to 2036 with:
  ```sql
  UPDATE accounts SET premium_ends_at = UNIX_TIMESTAMP() + (3650*86400) WHERE id=1;
  ```
- `players.town_id`: 1=Thais, 2=Carlin, 3=Venore, 4=Ab'Dendriel, 5=Rookgaard
  (whatever the loaded `.otbm` contains — verify by booting and checking logs).

---

## 3. Lua 5.5 / TFS 1.5 compatibility (data/)

### const-for crashes
Lua 5.5 makes both numeric *and* generic `for` loop variables `<const>`.
Reassigning the loop var = "attempt to assign to const variable" → `core.lua`
errors out → cascading registration failures.

**Fix pattern**: copy loop var to a local at the top of each loop body
(`local dir = direction`). Patched in:
- `data/lib/core/position.lua`
- `data/lib/debugging/dump.lua` (if present)
- `data/npc/lib/npcsystem/modules.lua`

### `table.maxn` removed in Lua 5.5
46 call sites across `data/` converted to `#t` directly. **No shim.** User
preference: "ma shim nao seria esconder o bug?" — for a small number of sites
with a trivial replacement, root-fix is cleaner. Modules.lua had 4 sites.

### `table.contains` (30+ sites)
Never was a Lua native. **Shim accepted** because mass-rewriting 30+ varied
call patterns is more error-prone than a 3-line helper. Lives in
`data/lib/compat/compat.lua`.

### Other compat shims in `data/lib/compat/compat.lua`
Added 7 legacy functions that exist in global 8.0 scripts but not in Nekiro 1.5:
- `doCreateItem`, `doCreateItemEx`
- `doCombat`, `doMoveCreature`
- `doSendAnimatedText` (silent no-op — was deprecated debugPrint, spams)
- `doPlayerSetOfflineTrainingSkill`
- `isInArray`
- `setCombatCondition = Combat.addCondition` (renamed in Nekiro 1.5)

### Missing constants
- `data/lib/core/constants.lua`: `ITEM_BAG = 1987`

### `data/scripts/` folder
The engine **requires `data/scripts/lib/`** to exist (revscript loader). When
we initially wiped `data/scripts/` the server crashed on boot with
`createFunctions nil`. **Restored Nekiro's `lib/` + `eventcallbacks/`** while
keeping content from global 8.0. Don't delete `data/scripts/lib/`.

---

## 4. NPC system

### Trade window
Two layers had to be fixed for shops to open:
1. **Protocol packet shape** (see §1 — `protocolgame.cpp` sendShop / sendSaleItemList).
2. **`data/npc/lib/npcsystem/modules.lua` `requestTrade`** — was missing the call
   to `openShopWindow(cid, items, onBuy, onSell)` for `SHOPMODULE_MODE != TALK`.
   Without this fix, even with the right packet, the shop dict would build but
   the window never sent.

We run with `SHOPMODULE_MODE = SHOPMODULE_MODE_BOTH`, so both branches in
`requestTrade` matter — patch both.

### `NpcHandler:onPlayerEndTrade`
Added as a no-op in `data/npc/lib/npcsystem/npchandler.lua`. `runes.lua` (NPC)
calls it; without the method it errors at trade-end and trade gets stuck.

### The Oracle (Rookgaard vocation choice)
Rewrote `data/npc/scripts/The Oracle.lua` from scratch for 4 Tibia 8.0 cities.
Town IDs and temple positions:
| Town | id | Temple position |
|------|----|------------------|
| Thais | 1 | (32369, 32241, 7) |
| Carlin | 2 | (32360, 31782, 7) |
| Venore | 3 | (32957, 32076, 7) |
| Ab'Dendriel | 4 | (32732, 31634, 7) |

The Oracle was initially placed in the temple by mistake — user asked to remove it.
It belongs in the upper-floor Rookgaard altar room (vanilla position).

---

## 5. Login chain & creaturescripts

### `creaturescripts.xml` — alphabetical map order
`std::map` iterates alphabetically. Login event order is determined by the `name`
attribute, NOT the XML declaration order. User wanted blessings message LAST →
I tried renaming `AdventurerBlessings` → `zzAdventurerBlessings`. **User reverted**:
"nao renomeie nada, deixa como estava". Order is whatever you get from the names
that are there now; live with it.

### `data/creaturescripts/scripts/others/adventureblessings.lua` — silent segfault
Player::blessings is `std::bitset<6>` (6 slots, max). Script originally looped
`for i = 1, 8 do player:addBlessing(i, 1) end` → out-of-bounds at i=7 = SILENT
SEGFAULT (no log line, server just disappears).

**ADM Lemos lvl 100 was unaffected** because `>= 20` skipped the script. **Lemos
lvl 8 hit it on every login** = "connection lost". Took hours to find. Fix:
```lua
for i = 1, 5 do
    if not player:hasBlessing(i) then
        player:addBlessing(i)  -- single-arg call (no second `1`)
    end
end
```

### `login.lua` setVocation crash for vocation 0
Vocation 0 (None) has no demotion → `getDemotion()` returns nil → `:getId()` on
nil = crash. Added nil check.

### Starter runes (one-shot)
`data/creaturescripts/scripts/starter_runes.lua` registered in creaturescripts.xml.
On first login of a mage vocation (Sorc/Druid/MS/ED, ids 1/2/5/6), gives 50 blank
runes. Storage key `88888` so it doesn't repeat.

---

## 6. Spells (rune system rework)

### `<conjure>` is dead
`function="conjureRune"` is **not** in Nekiro 1.5 source. The 38 spells using it
were silently failing to load — every conjure incantation gave "magic spell".
**Diagnostic** for next time: any spell saying "magic spell" instead of casting
= the spell is registered but its function/script is unknown.

### Fix: `Player:conjureItem` helper + per-spell scripts
- Helper added to `data/spells/lib/spells.lua`:
  ```lua
  function Player:conjureItem(reagentId, conjureId, conjureCount, effect)
      -- removeItem(reagentId, 1) → addItem(conjureId, conjureCount), w/ effects
  end
  ```
- All 38 `<conjure ... function="conjureRune">` blocks rewritten to
  `<instant ... script="conjuring/X.lua">`.
- Each script is a 3-liner:
  ```lua
  function onCastSpell(creature, variant)
      return creature:conjureItem(REAGENT, CONJURE_ID, COUNT)
  end
  ```
- Generated by `fix_conjures.py`. **Important caveat** discovered mid-session:
  earlier passes only generated scripts for spells whose script file was missing.
  Existing UH/chameleon/convince scripts had Nekiro defaults (count=1) instead
  of Realera defaults (count=2 etc). Fix: regenerate ALL 38 by always overwriting.

### Rune charges normalization
`<rune>` entries in `data/spells/spells.xml` normalized:
- UH (`adura vita`/2273): `charges=1`
- SD (`adori vita vis`/2268): `charges=1`
- GFB (`adori gran flam`/2304): `charges=2`
- All others: `charges=5`

**Avalanche skipped** — confirmed by user on 2026-04-28: Avalanche is a Tibia 8.1
feature, not 8.0. Items.xml has the entry (id 2274, `adori mas frigo`) carried
over from global 8.0, but no `<rune>` / `<instant>` registrations and no scripts.
Don't add it without explicit user request.

### NPCs no longer sell runes
Stripped from `data/npc/*.xml` shop_buyable / shop_sellable, and 50ish
`shopModule:add{Buyable,Sellable}Item` Lua calls commented out. Players only
get runes via conjuring.

### `function="convince"` and `function="chameleon"`
Same treatment as conjureRune — converted to script form.

---

## 7. The Blank Rune saga (THE BIG BUG)

### Symptoms
- Soul display = **-1** after relogin if carrying blank rune
- Backpack **won't open** if blank rune is inside
- Map renders **BLACK** if blank rune is in backpack
- Bonus weirdness: a backpack containing blank rune, dropped on the ground after
  relogin, **renders as a blank rune itself** (client cached the wrong clientId
  while parsing the corrupted packet)

### Wrong diagnosis (reverted)
First hypothesis: `items.otb` has blank rune (server 2260) with flags `0x60`
(MOVEABLE | PICKUPABLE only) while UH (2273) has `0xF0` (+ STACKABLE | USEABLE).
Built `fix_blank_rune_otb.py` to add the STACKABLE flag → backed up `items.otb.bak`.
**User pushback**: "blank rune nao e stacavel ... vai ser uma separada da outra
mesmo". Reverted from the backup. Blank rune is **non-stackable by design** in
this server.

### Real cause
`src/networkmessage.cpp:110-112`:
```cpp
} else if (it.isRune()) {
    addByte(it.charges);
}
```
This sends 1 byte after the clientId for **any** item with `<attribute key="type"
value="rune"/>`. For UH/GFB/SD that byte is the charges count and the client
expects it (Tibia.dat marks them as having a sub-type indicator).

For **blank rune** the byte is `it.charges = 0` (default — no `<charges>` attr in
items.xml). The 8.0 client.dat does **NOT** flag blank rune as having a sub-type
→ doesn't read the byte → reads it as the *next* item's clientId → entire packet
parse desyncs from that point on.

That's why all the symptoms are inventory/container/map rendering bugs: those
are the packets that contain item lists, and a single off-by-one byte cascades
through the rest.

### Fix
One-line patch in both addItem overloads:
```cpp
} else if (it.isRune() && it.charges > 0) {
    addByte(it.charges);
}
```
i.e. only ship the sub-type byte for runes that actually have charges configured.
Comment in source explains why for future-me.

### Cleanup of corruption residue
3 ghost blank runes with `count=0` were sitting in `player_items` for MS Lemos
in invalid slots (pid=5/6/10 — these aren't real inventory slots). Removed via:
```sql
DELETE FROM player_items WHERE player_id = 5 AND itemtype = 2260 AND count = 0;
```
Soul values in DB were always **100** (correct) — the bug was display-only,
not a real stat reset. Confirmed all 4 chars have soul=100 in the players table.

### Files for next time
- `parse_otb.py` — read items.otb, dump server/client/flags for given IDs.
  Reuse if anything else has flag mismatch suspicions.
- `fix_blank_rune_otb.py` — flag-flip patcher. **Do NOT re-run on this otb**;
  blank rune is supposed to stay non-stackable. Kept for reference / template.

### Second bug found in the same session: "You need a magic item"
After the networkmessage.cpp fix, conjuring still failed: `adori gran flam`
with a blank rune in the BP gave **"You need a magic item to cast the spell"**.
Root cause in `src/item.h:957` `Item::countByType`:
```cpp
if (i->isRune()) {
    return i->getSubType();   // blank rune getSubType() == 0
}
```
For UH/GFB/SD this returns charges (≥1) — fine. For blank rune `getSubType()`
returns 0 (no charges configured), so `Player::removeItemOfType` thinks zero
exist in inventory → returns false → `Player:conjureItem` cancels with
RETURNVALUE_YOUNEEDAMAGICITEMTOCASTSPELL.

Fix:
```cpp
if (i->isRune()) {
    const uint16_t charges = i->getSubType();
    return charges > 0 ? charges : 1;   // blank rune counts as 1 physical
}
```
This is the canonical pattern: a rune with charges is "consumed" by spending
charges; a rune without charges is consumed as a whole item (1 per cast).
Required rebuild.

---

## 7b. Post-CLAUDE.md polish (same session, after the bug saga)

### Rune look description showing "(0x)"
After conjuring fireball runes the player look text was:
> You see 8 fireball runes for magic level 4. It's an "adori flam" spell **(0x)**.

`src/item.cpp:906`:
```cpp
s << ". It's an \"" << it.runeSpellName << "\" spell (" << (item ? item->getCharges() : it.charges) << "x)";
```

For *non-stackable* runes (UH, GFB, SD, blank rune) `getCharges()` reads
`ITEM_ATTRIBUTE_CHARGES` from item attributes — works.

For *stackable* runes (fireball/explosion/heavy MM/etc — flags 0xF0 in items.otb)
the engine stores the charge count in `itemCount`, NOT in
`ITEM_ATTRIBUTE_CHARGES`. So `getCharges()` returns 0 → "(0x)".

**Fix**: use `getSubType()` which already handles both cases (returns `count` for
stackable, `getCharges()` for charged). Comment in source explains why.

### Conjure script counts misaligned with `<rune charges>`
After the conjureItem migration, the conjure script counts (the value passed to
`addItem`) drifted: fireball.lua had `count=10`, GFB had `count=4`,
ultimate_healing had `count=2`. None matched the user's normalization (UH=1,
GFB=2, others=5).

`fix_conjure_counts.py` — reads spells.xml `<rune>` entries to build
`{rune_id: charges}`, then walks each `<instant script="conjuring/X.lua">` and
rewrites the script's `conjureItem(reagent, id, count)` call so `count == charges`.
Skips conjures whose target id isn't a rune (arrows/bolts have intentionally
different stack sizes — `conjure_arrow=20`, `conjure_power_bolt=20`, etc.).

Updated 28 conjure scripts in one pass. Re-run any time you change a
`<rune charges>` value in spells.xml — the script self-syncs from the XML.

### NPC trade items disabled even with money in BP
Buying anything from any NPC was greyed out, even with crystal coins in the BP.
Cause: **gold/platinum/crystal coins had no `<attribute key="worth">`** in
items.xml. `Player::getMoney()` walks the inventory summing `it.worth` of each
item — with worth unset, every coin counted as 0 currency. The shop client
disables items the player can't afford → all disabled.

Fix in `data/items/items.xml`:
```xml
<item id="2148" article="a" name="gold coin">
    <attribute key="weight" value="10" />
    <attribute key="worth" value="1" />
</item>
<item id="2152" article="a" name="platinum coin">
    <attribute key="weight" value="10" />
    <attribute key="worth" value="100" />
</item>
<item id="2160" article="a" name="crystal coin">
    <attribute key="weight" value="10" />
    <attribute key="worth" value="10000" />
</item>
```

items.xml requires server restart (no `/reload items`).

### Avalanche pivot
User asked "como faz avalanche com o druid". I started building the spell
(attack script + items.xml charges adjustment) before the user clarified
**Avalanche came in 8.1, not 8.0** ("entrou no tibia 8.1 nao precisa dela,
deixa so gfb"). All in-progress changes reverted. items.xml charges back to 4
(unused), no spells.xml entry, no script.

### Fireball needtarget back to "1"
We removed `needtarget="1"` from the Fireball `<rune>` thinking AOE was the
intended behavior. User reverted: **"a fireball rune vai ser needtarget='1'"**.
Fireball stays creature-only on this server.

### Spell whitelist applied (28/04/2026)
User provided official spell tables (Sorc/Druid/Pal/Knight) with exact ML/Mana/Premium
per spell, plus the rune charges-per-conjure table. `apply_spell_whitelist.py` (in repo
root) does it all in one pass — preserves history (comments, never deletes), tagged
`[DESATIVADO - Magia fora da whitelist oficial - 28/04/2026]`.

What it touches:
- `data/spells/spells.xml` — whitelisted spells get `mana`/`maglv`/`prem` updated
  inline; non-whitelisted blocks wrapped in `<!-- ... -->`. **51 commented out, 66
  instants + 28 runes updated.**
- `data/npc/scripts/spells/*.lua` — non-whitelisted entries prefixed with `--`
  (with the deactivation note above). **60 entries commented across 9 NPC files.**
- `data/spells/scripts/conjuring/*.lua` — counts re-aligned to `<rune charges>` via
  `fix_conjure_counts.py` logic (Phase 3 of the same script). Re-runs every time;
  no-op if already in sync.

WHITELIST format inside `apply_spell_whitelist.py`:
```python
WHITELIST = {
    'utevo lux': {'name': 'Light', 'vocs': {1,2,3,4,5,6,7,8}, 'ml': 0, 'mana': 20, 'prem': False},
    ...
}
RUNE_CHARGES = {'fireball': 5, 'great fireball': 4, 'sudden death': 1, ...}
```
- Keyed by lowercase `words` (the magic incantation — the only invariant).
- `vocs` = union across user's tables (Sorc=1/MS=5, Druid=2/ED=6, Pal=3/RP=7, Knight=4/EK=8).
- `mana=None` for spells with variable mana (Berserk, Summon Creature, Summon Call).
- NPC matching uses spell NAME → words via the parsed spells.xml; `NPC_NAME_ALIASES`
  resolves common renames ("Cure Poison Rune" → "Antidote Rune", "Paralyse" →
  "Paralyze", "Fire bomb" → "Firebomb", "Disintegrate" → "Desintegrate", etc).

**The whitelist must NOT touch monster-internal spells.** First run wrongly
commented out all 40 `<instant words="###N" script="monster/*.lua">` entries —
those are invoked by monsters BY NAME from their XML (`<attack name="djinn
electrify"/>` etc), with `words="###N"` so players can't cast them. Without the
registration, every monster XML referencing them errors at boot
(`Unknown spell name: djinn electrify`, `phantasm drown`, `* skill reducer`,
etc — the actual implementation lives in `data/spells/scripts/monster/*.lua`).
**Fixed**: `apply_spell_whitelist.py` now keeps any `<instant>` whose
`words=` starts with `###` OR whose `script=` starts with `monster/`.
`restore_monster_spells.py` (in repo root) is a one-shot recovery if the
wrap-in-comment ever happens again — it unwraps DESATIVADO comments around
monster-internal spells.

**Spells in the user's whitelist that don't exist in spells.xml** (need adding manually
if the user wants them — current server has them as items.xml entries but no spell
registration):
- `adori frigo` (Frost Magic Missile / Icicle Rune — items.xml id 2271 exists)
- `exori frigo` (Ice Strike)
- `exevo frigo hur` (Ice Wave)
- `exana kor` (Revitalize)
- `exana mas mort` (Undead Legion)
- `exani res` (Summon Call)
- `exevo mas vita` (Mass Growth)
- `utura mas res` (Mass Purification)
- `utura sio` (Purification)

**Rune charges normalization** (canonical, this overrides earlier sessions):
- LMM, HMM = 10
- Fireball, Soulfire, Frost MM (Icicle) = 5
- Sudden Death = 1
- Great Fireball = 4
- Explosion = 6
- Fire/Energy/Poison Field = 3
- Fire/Energy/Poison Bomb = 2
- Fire/Energy/Poison Wall = 4
- IH/UH/Antidote (Cure Poison) = 1
- Magic Wall, Destroy Field, Disintegrate = 3
- Paralyze, Chameleon, Animate Dead, Convince Creature = 1
- Wild Growth = 2 (`adevo grav vita` — user spec said "exevo" but that was a typo)

To re-apply (e.g., after editing `WHITELIST` in the script): restore from `.bak`
files first, then run `python apply_spell_whitelist.py`. The script is idempotent
on the FIRST run after a backup-restore but will double-comment if run on
already-modified files.

### `/reload <category>` works in-game (must be GOD)
- `/reload all` — everything
- `/reload spells` — spells.xml + scripts (perfect for testing conjure changes)
- `/reload scripts`, `/reload monsters`, `/reload npcs`, `/reload talkactions`,
  `/reload actions`, `/reload movements`
- **Doesn't work**: items.otb / items.xml / src/*.cpp — restart or rebuild required.

### SD spell (for reference)
- Conjure: `adori vita vis`, lvl 45, mana 880, soul 5, Sorcerer/MS only
- Use rune: needtarget=1, deals death damage, charges=1 (per normalization)

---

## 8. Common pitfalls / things that bit us

- **Two `tfs.exe` instances** = phantom "ERROR 2". Always `taskkill //F //IM tfs.exe`
  before starting.
- **`function="conjureRune"` silently no-ops** in Nekiro 1.5. Symptom is the spell
  saying "magic spell" without an effect. Look at `<spell>` → if it uses a
  function name not in the engine's function table, it just doesn't fire.
- **`std::bitset<6>` for blessings** — any script that loops past index 5 = silent
  segfault. Same for any other bitset-backed enum (check before iterating).
- **Renaming login events to control order** — works (alphabetical map order),
  but user explicitly rejected: do NOT rename. Live with whatever order falls
  out of existing names.
- **`<spawn>` blocks containing `<npc>` instead of `<monster>`** — my "remove
  empty spawn" pass deleted them and 433 NPCs vanished from the map. Caught by
  user; restored from `global 8.0`. Always grep for `<npc>` before mass-deleting
  in `world-spawn.xml`.
- **Account type 5 vs 6** — `/i`, `/teleport`, broadcasting all need 6 (GOD).
  Type 5 = Senior GM, doesn't have full god flags.
- **`data/scripts/lib/` is mandatory** — engine boot fails without it. When
  importing content from another server, restore Nekiro's `lib/` + `eventcallbacks/`.
- **OTB clientId vs Tibia.dat sub-type flags** — don't assume. The blank rune bug
  was diagnosed only after parsing items.otb AND reading the engine's serialization
  path. If a single item is causing wide-area packet corruption, suspect the
  per-item byte count first (stackable / fluid / rune charge bytes).
- **Coin worth must be in items.xml** — without `<attribute key="worth">` on
  gold/platinum/crystal, `Player::getMoney()` returns 0 and trade greys out
  every item. Easy to miss because nothing in the boot log warns about it.
- **Stackable vs charged rune storage** — `getCharges()` only works for runes
  with the STACKABLE flag *off* in items.otb (charges live in attributes). For
  stackable runes use `getSubType()` (which returns `itemCount`). Confused once
  during the "(0x)" description bug.
- **`/reload spells` is the friend** — testing spells.xml changes does NOT need
  a restart. `<rune>` / `<instant>` attribute changes (needtarget, charges, etc)
  pick up via `/reload spells` immediately. items.xml needs full restart.

---

## 9. Open threads / next session

- **Verify rune conjuration end-to-end** in-game. Cast `adori gran flam`,
  `adura vita`, etc. on a char with blank runes in BP. Confirm runes appear and
  blank rune count decrements.
- **Confirm trade window** opens on a couple of NPCs with mixed shops (food vendor,
  equipment vendor) — make sure both buy/sell sides render.
- **Test starter_runes.lua** — log a fresh mage char and confirm 50 blank runes
  on first login, none on subsequent logins (storage 88888 should gate).
- **Quest functionality** — user asked early on "as quests vao funcionar?". We
  haven't verified any quest. Katana quest key/door was the specific concern.
  Smoke-test by walking a few quest chains.
- **Map warnings** — there are still some `Empty spawn at position` / mover-able
  items in houses warnings. User said "deixa por enquanto"; revisit only if it
  becomes load-bearing.
- **No git repo** — `Realera TFS 1.5/` is **not** a git repo (unlike the 7.72
  stack at `Desktop/OT/`). All fixes live as raw file edits. If we want history,
  `git init` and commit the current state first.

---

## 10. Quick reference: source files we edited

| File | What |
|------|------|
| `src/connection.h/cpp` | Asio modern API |
| `src/server.h/cpp` | Asio modern API |
| `src/signals.h/cpp` | Asio modern API |
| `src/scheduler.h/cpp` | Asio modern API |
| `src/otpch.h` | Asio modern API |
| `src/database.cpp` | MySQL SSL disable |
| `src/iologindata.cpp:616` | sex enum cast |
| `src/protocolgame.cpp` | sendShop / sendSaleItemList for 8.0 protocol |
| `src/networkmessage.cpp:110-112,130-132` | blank rune charge byte gating |
| `src/item.h:957-967` | countByType: blank rune counts as 1 (not 0) |
| `src/item.cpp:906` | rune description: `getSubType()` so stackable runes show count |

## Quick reference: data/ files we edited

- `data/lib/compat/compat.lua` — 7 legacy functions, table.contains, setCombatCondition
- `data/lib/core/constants.lua` — ITEM_BAG = 1987
- `data/lib/core/position.lua` — const-for fix
- `data/spells/spells.xml` — 38 conjure→instant, rune charges normalized
  (UH=1, SD=1, GFB=2, others=5), convince/chameleon converted, Fireball
  needtarget="1" (kept on user request)
- `data/spells/lib/spells.lua` — Player:conjureItem helper
- `data/spells/scripts/conjuring/*.lua` — 38 generated scripts; counts aligned
  to `<rune charges>` via `fix_conjure_counts.py`
- `data/items/items.xml` — coin worth attributes (gold=1, platinum=100,
  crystal=10000); blank rune kept non-stackable; avalanche entry untouched (unused)
- `data/npc/lib/npcsystem/modules.lua` — requestTrade openShopWindow, table.maxn → #
- `data/npc/lib/npcsystem/npchandler.lua` — onPlayerEndTrade no-op
- `data/npc/scripts/The Oracle.lua` — 4-city rewrite
- 118 `data/npc/*.xml` — runes stripped from shops
- `data/creaturescripts/creaturescripts.xml` — StarterRunes registered
- `data/creaturescripts/scripts/starter_runes.lua` — new
- `data/creaturescripts/scripts/login.lua` — vocation 0 nil check
- `data/creaturescripts/scripts/others/adventureblessings.lua` — bitset<6> fix

---

## Account/character cheat sheet

```
DB realera15, account 1, password 'lemos', type 6 (GOD), premium until 2036
  ADM Lemos     lvl 100, vocation 0 (None), god flags
  Lemos         lvl 8,   vocation 3 (Paladin),       Rookgaard
  MS Lemos      lvl 100, vocation 5 (Master Sorc),   Thais temple
  ED Lemos      lvl 100, vocation 6 (Elder Druid),   Thais temple
```

Both MS Lemos and ED Lemos were created mid-session at user request, magic
level 40, in the Thais temple ("MS e ED na minha conta level 100 ai ... no
tmeplo de thais").

---

## 12. Day-5 work — Player Shop (Priston Tale style)

Added a full player-shop system under `data/scripts/playershop/` (server, revscripts)
and `C:/Users/Lemos/Desktop/otclientv80/modules/game_playershop/` (client). 
Right-click your own char → "Open Shop" (creates own shop). Right-click another
player who's selling → "Open Shop" (buy from them).

### Server-side: `data/scripts/playershop/`

| File | Role |
|------|------|
| `01_config.lua` | shared config (`PlayerShopConfig`), opcode IDs (130-138), packing helpers (`PlayerShop_PackU8/U16/U32/Str`), `PlayerShop_SendOpcode`, `PlayerShop_Reject` |
| `02_core.lua` | `PlayerShop_Open` / `PlayerShop_Close` / `PlayerShop_Buy` (synchronous w/ rollback), `PlayerShop_BroadcastState`, `PlayerShop_SendShopDataTo`, `PlayerShop_SendInventoryList` |
| `03_opcodes.lua` | Reader for buffer parsing; `PlayerShop_DispatchOpcode`; `CreatureEvent("PlayerShopExtOp")` (type=extendedopcode) |
| `04_events.lua` | login chain (registers `PlayerShopExtOp` + `PlayerShopLogout`), logout closes shop (no longer blocks), `EventCallback.onMoveItem` blocks ALL item movement while selling, GlobalEvent tick (500ms) warps seller back if displaced + 8h timeout, GlobalEvent sayTick (10s) makes seller `say(text, TALKTYPE_SAY)` so the title floats overhead |
| `05_talkactions.lua` | `!fecharloja`, `!lojas`, `/shop list`, `/shop close <name>` |
| `06_save_hook.lua` | `GlobalEvent("shutdown")` closes all shops; VIP login sync stub (Player:getVipList not exposed in this build, so commented out) |
| `README.md` | install + opcode table + design notes |

### Client-side: `otclientv80/modules/game_playershop/`

| File | Role |
|------|------|
| `playershop.otmod` | manifest (filename had to be `playershop.otmod` not `game_playershop.otmod` — otclientv80 convention is `<short>.otmod`) |
| `playershop.otui` | `ShopBubble` (unused now), `CreateShopWindow`, `ShopViewWindow`, `ShopSlot` styles; **NO `//` comments** (OTUI doesn't accept them, breaks parser) |
| `playershop.lua` | opcode registration, `iAmSelling` flag, drawInformation hook (icon next to name), VIP color/icon hook, click intercept |
| `create_shop.lua` | "Criar Loja" window logic: 20 slots, item picker, price validation, `commitCreateShop` |
| `shop_view.lua` | buyer view: lists items + qty + buy buttons |

### ExtendedOpcodes (130-138)

All payloads are packed into a SINGLE string sent via `addString` — multiple
`addByte`/`addU32` calls after the opcode byte corrupt the OTClient extended-opcode
parser's framing (it expects exactly one length-prefixed string after the opcode).
The bug manifested as truncated text ("ta loja" instead of "Esta loja") because
the client's `readStr(buffer, 1)` read 2 bytes as length INSIDE the actual string.

| ID | Name | Direction | Payload |
|----|------|-----------|---------|
| 130 | OPEN | C→S | text(str), n(u8), [uid(u32) id(u16) count(u16) price(u32)]×n |
| 131 | CLOSE | C→S | (vazio) |
| 132 | REQUEST | C→S | sellerCid(u32) |
| 133 | BUY | C→S | sellerCid(u32) slot(u8) qty(u16) |
| 134 | DATA | S→C | sellerId(u32) name(str) text(str) n(u8) [slot(u8) id(u16) count(u16) price(u32) charges(u16) name(str)]×n |
| 135 | STATE_BROADCAST | S→C | cid(u32) isOpen(u8) text(str if open) |
| 136 | VIP_STATUS | S→C | guid(u32) name(str) isOpen(u8) |
| 137 | INVENTORY_LIST | S↔C | (request: vazio; response: n(u16) [uid(u32) id(u16) count(u16) charges(u16) name(str)]×n) |
| 138 | REJECT | S→C | reason(str) |

### Movement / chat lock layers (4 layers — overengineered? maybe)

Took several iterations because each "fix" had a corner case. Final stack:

| Layer | Where | What it blocks |
|-------|-------|----------------|
| 1. `walking.lua walk()` early-return | client | WASD / direction keys (no input sent to server) |
| 2. `walking.lua turn()` early-return | client | Ctrl + arrows turning |
| 3. `gameinterface.lua autoWalk` early-return | client | click-to-walk |
| 4. `Player:onTurn` returns false | server | hacked-client safety net for turning |
| 5. 500ms tick `teleportTo(anchor)` | server | hacked-client safety net for movement |
| 6. `console.lua sendCurrentMessage` filter | client | non-`!`/`/` chat (commands like `!fecharloja` still pass) |

**Paralyze condition was tried** to freeze on server side, but it caused the
"buyer walks onto same SQM as seller" bug (apparently Tibia treats paralyzed
creatures differently for tile-blocking). Removed; layer-1/2/3 client-side
blocks + onTurn + warp-back tick are sufficient.

**`changeSpeed(-currentSpeed)` was tried** even before paralyze. Same
non-blocking-tile bug. Don't use.

**Auto-close on logout, walk anchor lives ON THE SHOP ENTRY** (`shop.anchorPos`),
not in a parallel table. So when the shop closes, the anchor disappears
automatically — fixes "open shop somewhere else, get teleported to old spot"
bug.

### Bubble (overhead text)

Initial attempt: custom `ShopBubble` widget on the map panel using
`mapPanel:getCreaturePosition(creature)` — that method **doesn't exist** in
otclientv80. Scrapped.

Current: server makes the seller `Creature:say(shop.text, TALKTYPE_SAY)` every
10 seconds. The engine renders a yellow bubble natively (visible to all nearby
players, fades in a few seconds, repeats). Tried `TALKTYPE_MONSTER_SAY` (red
bubble) — user didn't like the colour. Tried suppressing the chat-log entry
via a `console.lua` patch in `onTalk` that matches `name + message` against
`modules.game_playershop.sellingCreatures` and skips the log entry — works
but means we still have spam in the engine's log on the seller's side
(cosmetic only on the buyer-side chat tabs).

### Right-click menu (the great separator saga)

Goal: "Open Shop" entry visible only when:
- Right-clicking own char (opens create-shop window)
- Right-clicking another player who's currently selling (opens buyer view)

Iterated through several approaches because of the otclientv80 menu hook API:

1. Single category `playershop` with one option — got 1 separator. User wanted 2.
2. Two categories `_create` + `_view` — got 2 separators (one per category, even
   the empty one), but order was random per `pairs()` so "Open Shop" sometimes
   appeared between two separators (good) and sometimes after both (bad).
3. Patched `gameinterface.lua` to iterate `hookedMenuOptions` in **sorted-key
   order** so the placement is deterministic. Categories `playershop_a_create`
   (own char) and `playershop_b_view` (selling other) — `_a_` always renders
   first, `_b_` second.
4. Tried adding 2 trailing separators below "Open Shop" via custom logic — user
   said it looked weird (3 separators total), reverted.

Final: 2 categories + sorted iteration in gameinterface.lua. Result: 2 separators
appear consistently around the "Open Shop" option.

### Other UX fixes that piled up
- **Coin click-to-walk on selling tile**: drop `paralyze` (was making seller
  non-blocking).
- **Shop-title required**: client validation (in `commitCreateShop`) +
  server validation (in `PlayerShop_Open`).
- **`getTradeState()` doesn't exist** in this build — removed the trade-state
  check from `canOpenShop`.
- **`getVipList()` doesn't exist** either — VIP gold-colour hook stays
  registered but does nothing (only nearby `STATE_BROADCAST` paints the icon).
- **`CONST_SLOT_FIRST/LAST` are nil** in this build — replaced with literals
  `1, 10` in `findItemInInventory` and `PlayerShop_SendInventoryList`.
- **Coin worth attributes** (already in §7b but bears repeating): without
  `<attribute key="worth">` on coins, `Player::getMoney()` returned 0 and the
  trade window greyed out everything. Set 1/100/10000 on gold/plat/crystal.
- **Stackable rune drop only drops 1**: this is a TFS 1.5 / 8.0 protocol
  default — drag asks "How much?" via the count window. NOT a player-shop bug.
  User declined the suggested fix in `gameinterface.lua moveStackableItem`
  (default = drop all without dialog) — kept original behaviour.
- **Hailstorm Fury mount typo** — early-day fix, completely unrelated to player
  shop. Mount id=55 was named `"Hailtorm Fury"` (missing `s`) inherited from
  global 8.0's mounts.xml when it overwrote Nekiro's correct version. One-line
  fix in `data/XML/mounts.xml`. (commit `0ad745d3`)

### Files modified outside the playershop module
- `otclientv80/modules/game_walking/walking.lua` — `walk()` and `turn()` early-return
- `otclientv80/modules/game_interface/gameinterface.lua` — sorted-key hook iteration; autoWalk early-return; **note**: `useThing:isItem()` check in the GameBot ID-display block means the "ID: 409" line only appears for items, not creature right-clicks
- `otclientv80/modules/game_console/console.lua` — `sendCurrentMessage` filter for non-`!`/`/` while selling; `onTalk` filter to skip shop-bubble messages from chat log
- `otclientv80/modules/game_interface/interface.otmod` — added `game_playershop` to the `load-later` list so it loads when game_interface init's
- `Realera TFS 1.5/data/events/scripts/player.lua` — `Player:onTurn` blocks Ctrl+arrows while selling

### Message colours (final)
- "Loja aberta. Voce nao pode se mover ate fechar." → `MESSAGE_INFO_DESCR` (green via the existing 7c client patch)
- "Loja fechada." (and variants on close) → `MESSAGE_INFO_DESCR` (green)
- "Voce ja tem uma loja aberta." → `MESSAGE_INFO_DESCR` (green, informational)
- All blocking messages ("Esta loja nao esta mais disponivel.", "Voce nao pode mover itens com a loja aberta.", chat-blocked, etc.) → `MESSAGE_STATUS_WARNING` server-side, `displayFailureMessage()` client-side. Renders white at the bottom of the screen — user said "deixa como esta agora, branco lá embaixo".

### Open issues / not implemented
- Custom-styled overhead bubble (the "Lojinha do Gordo" white-bubble look from the user's reference image) — would require either an engine patch to render `TALKTYPE_PRIVATE_NP` differently or a custom client-side widget that converts game-position → screen-pixel. Skipped because `mapPanel:getCreaturePosition` doesn't exist in otclientv80 and the engineer time-budget was rough.
- `getVipList()` — would need either a Lua binding added to TFS source (small C++ change) or query the DB directly from a globalevent. Skipped.
- Shift+drag = drop entire stack — confirmed user prefers the original Tibia behaviour with the count dialog.

### Files for reference
- `data/scripts/playershop/README.md` — install + opcode table
- `data/scripts/playershop/06_save_hook.lua` — also has the `PlayerShop_CloseAll(reason)` global helper that the existing `data/globalevents/scripts/serversave.lua` can call directly if you want shop-close-on-save.

### Day-5b polish (still same day, after long iteration)

**Bubble: settled on a custom `ShopBubble` UIWidget** (in playershop.otui — white pill,
`#f1f1f1` bg + `#4a4a4a` border + `#1a1a1a` text). Created on STATE_BROADCAST(open=1)
as a child of the game map panel. Position synced every 50ms via
`creature:getInformationPosition()` (a Creature method exposed in the otclientv80
binary even though it's not surfaced in any module; works fine from Lua).
Persistent — does not fade. Server re-broadcasts STATE every 3s so newly-arrived
nearby clients also get the bubble.

**Tried and discarded**:
- `Creature:say(text, TALKTYPE_SAY)` — yellow bubble + chat-log spam.
  Console.lua filter to skip the chat-log entry worked, but only when the local
  client already had `sellingCreatures` populated; new arrivals saw the spam.
- `Creature:say(text, TALKTYPE_MONSTER_SAY)` — red bubble. User vetoed colour.
- Engine `StaticText` (`StaticText.create()` + `g_map.addThing(st, pos, -1)`) — fades
  in ~5s. Tried refreshing every 3s but user wanted "static, no refresh".

**`Creature:getInformationPosition()`** — undocumented but present in the
otclientv80 GL/DX binary. Returns the screen pixel where info (name, HP) is drawn.
Subtract widget height + 18px to place a bubble above the name.

**OTUI hex colours must be 6-digit.** `#444` and `#ddd` (3-digit) throw
`failed to cast node value '#444' to type 'class Color'` and the entire style
fails to load. Use `#444444`, `#dddddd`. Cost an evening of confused debugging.

### `iAmSelling` truth model (final)
- Client side flag, set/cleared by server's STATE_BROADCAST handler ONLY.
- Optimistically set to `true` on `commitCreateShop` (right after sending OPCODE_OPEN)
  so the user can't dash off in the 50-100ms before the server's STATE_BROADCAST
  comes back.
- Reset to `false` in `onGameStart` and `onGameEnd` to handle re-login on a
  cached client.
- **NOT reset in `onReject`.** Server's `PlayerShop_Reject` always sends a
  STATE_BROADCAST with the player's TRUE selling state immediately after the
  REJECT opcode. So the client's authoritative source for the flag is exclusively
  STATE_BROADCAST. This fixes the "user has shop active, opens window again,
  server rejects, client briefly thinks not-selling, walks for 2s" bug.

### Right-click menu — final form
- Two registered hooks (`playershop_a_create` for self → opens create window;
  `playershop_b_view` for other selling player → opens buy window).
- `gameinterface.lua` patched in TWO places: (1) iterate `hookedMenuOptions` in
  sorted-key order so layout is deterministic; (2) only add the per-category
  separator if at least one option's condition matches (so empty categories
  don't produce ghost separators on right-click of plain ground).
- Result: 2 separators visible only when the menu actually contains the Open
  Shop entry; 0 separators on ground/empty right-click.

### Movement / chat lock — final layers (paralyze removed)
1. **client `walking.lua walk()`** early-return if `iAmSelling` — drops WASD.
2. **client `walking.lua turn()`** early-return if `iAmSelling` — drops Ctrl+arrows.
3. **client `gameinterface.lua autoWalk`** early-return if `iAmSelling` — drops click-to-walk.
4. **server `Player:onTurn`** returns `false` if shop active — safety net for hacked client.
5. **server 500ms tick `teleportTo(shop.anchorPos)`** — safety net for hacked client.
6. **client `console.lua sendCurrentMessage`** allowlist: only `!fecharloja`,
   `!lojas`, `/shop`, `/shop *` pass; everything else shows red failure msg.
7. **server `EventCallback.onMoveItem`** returns `false` for ALL item moves while
   selling (no per-item UID matching — those break with non-unique items).

`shop.anchorPos` lives on the shop entry, not in a parallel table. Closes shop
→ entry deleted → anchorPos automatically gone. Fixes "close shop, open new one
1+ tile away, get teleported to old spot".

### Buyer-side PZ enforcement
- Buyer outside PZ tries to right-click "Open Shop" → server `PlayerShop_SendShopDataTo`
  rejects with red "Voce precisa estar em zona protegida para ver lojas."
- Buyer with view window open walks out of PZ → 500ms tick detects, sends
  REJECT + clears `OpenShopWindows[buyerId]`. Client's `onReject` calls (in
  pcall, three redundant paths because sandbox cross-script globals are
  inconsistent in OTCv8) `shop_view_close()`, `viewWindow:destroy()`, and
  `modules.game_playershop.viewWindow`. The view UI closes immediately.

### Message colour conventions (final)
- Server-side green (`MESSAGE_INFO_DESCR` → centerGreen via the existing
  client patch from §7c):
  - "Loja aberta. Voce nao pode se mover ate fechar."
  - "Loja fechada." / "Loja fechada (logout)." etc.
- Server-side red (via `PlayerShop_Reject` → REJECT opcode →
  `displayBroadcastMessage` → centerRed via `MessageModes.Warning`):
  - "Voce ja tem uma loja aberta."
  - "Voce precisa colocar um titulo na loja."
  - "Preco invalido no slot N."
  - "Loja vazia. Adicione pelo menos um item."
  - "Esta loja nao esta mais ativa."
  - "Voce precisa estar em zona protegida para ver lojas."
  - "Voce saiu da zona protegida. Loja fechada."
- Whitelist failure (client-side, status-small white): "Voce so pode digitar
  !fecharloja enquanto a loja esta aberta."

### Other small polish
- Top-bar "Criar Loja" button removed — both shop creation AND view are via the
  right-click menu only.
- ESC binds to close the Create-Shop window (`g_keyboard.bindKeyPress('Escape',
  closeCreateShop, createWindow)`).
- `onGameEnd` clears `lastSavedText`, `lastSavedSlots`, `inventoryList`, and
  destroys the create window so the next character on the same client doesn't
  see the previous one's draft.
- `iAmSelling` reset on both `onGameStart` and `onGameEnd` (paranoid defensive).
- Hailstorm Fury mount typo fix from earlier in the day shipped in commit
  `0ad745d3` — completely unrelated to player shop, just happened in same day.
