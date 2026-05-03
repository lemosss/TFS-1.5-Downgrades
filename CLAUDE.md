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

---

## 13. Day-6 — Player Shop polish + UI rework + stock validation

Today's session continued where Day-5 left off. The end-state is a player
shop that's actually usable.

### Server side

#### Cross-slot stock validation (`02_core.lua` `PlayerShop_Open`)
Without this, a seller with 5 fireball runes could declare slot 1 = 5 + slot 2 = 5.
Each slot's per-call cap to `realItem:getCount()` succeeds (both see the same
stack of 5), but the total is 10 > 5. Buyers get the rejection at buy-time but
the shop is misleading.

Now: **sums advertised count per itemId across all slots** and walks the entire
inventory (slots 1-10 + recursive container descent) to count what the player
actually has. If totalNeeded > have, rejects with
`"Voce nao tem N <name> (so tem M)."`

#### Recursive `findItemInInventory`
Was descending only one level into containers. A rune in a BP-inside-a-BP would
fail validation. Now walks the full container tree.

#### `onMoveItem` actually blocks now
- `data/events/events.xml`: `<event class="Player" method="onMoveItem" enabled="1" />`
  (was `0`). Without enabling, the engine doesn't dispatch the event so neither
  the events.xml-style handler nor the EventCallback chain fires.
- `data/events/scripts/player.lua` `Player:onMoveItem`: explicit
  `if ActiveShops[self:getId()]` check returns false. Belt-and-suspenders with
  the `EventCallback` already in `04_events.lua`.

#### `PlayerShop_Reject` resyncs selling state
After every reject the server now sends a STATE_BROADCAST with the player's
TRUE selling state (selling/not-selling + text if open). Without this, the
client's optimistic `iAmSelling = true` (set in `commitCreateShop` after sending
OPCODE_OPEN) would get RESET to false by the old `onReject` handler, and a
player who already has a shop active would briefly walk free for ~2s while the
warp-back tick caught up. Now the client trusts STATE_BROADCAST exclusively.

### Client side (`otclientv80/modules/game_playershop/`)

#### Shop icon (settled)
- `setShield(1)` + `setShieldTexture('/images/game/slots/coins')`. The Shield
  slot renders next to the creature's name (matches the Miracle reference image).
- Tried `setEmblemTexture` first — that slot renders at body-level on this
  build. Tried `setIconTexture`/`setTypeTexture` — wrong positions or no render.
- Tried a custom `ShopBubble` UIWidget child of the map panel positioning via
  `creature:getInformationPosition()`/`getDrawOffset()`. Math was off when the
  local player walks (camera interpolation). Disabled — kept the code in
  `updateBubblePositions` as a no-op for future work.
- `creature:setShield(0)` on close clears the slot. **NEVER** call
  `setEmblemTexture('')` or `setShieldTexture('')` — engine tries to load
  `'.png'` and crashes.

#### Create-Shop UI rework
- One slot rendered initially. `+ adicionar item` button below adds up to 20.
  Clicking the X on a slot destroys that row; window keeps a single empty slot
  if all are removed.
- Item picker is now cursor-grab (same UX as `game_hotkeys` "use with"):
  click slot → cursor turns into the target arrow → click any item in
  inventory/BP → that item is captured. No popup window.
- Layout fixes:
  - `Texto da loja:` margin-top 30 → 4.
  - `Summary` label: `text-auto-resize: true` + `text-wrap: true` so
    "1 itens, valor total: X" doesn't get clipped on the right.
  - **Scrollbar moved to its own column** anchored to `parent.right`; the
    `slotsPanel` ends at `scrollBar.left` with 4px margin. Slot rows fit
    cleanly without their X buttons being eaten by the scrollbar.
  - OTUI hex colours: `#444` and `#ddd` (3-digit) crash the OTML parser with
    `failed to cast node value '#444' to type 'class Color'`. Use 6-digit
    everywhere (`#444444`, `#dddddd`).

#### Stackable count picked up properly
`item:getCount()` returns 1 even for stackable stacks of 3 in this build. Fix:
when capturing the item via cursor-grab, also read `clickedWidget:getItemCount()`
(the visible stack count from the source UIItem widget) and `item:getSubType()`
(stackable count is in subType for 8.0 protocol). Use `max(widgetCount,
item:getCount(), subType)`. Now a click on a stack of 3 captures all 3.

Same item is **allowed** in multiple slots (the seller may have several stacks
they want to list separately). Cross-slot stock validation server-side prevents
overselling.

#### Removed game_actionbar / game_bot / game_healthinfo from interface.otmod
Those modules were deleted from this otclientv80 setup earlier (by the user).
With them in the `load-later:` list, every boot threw 3 red errors:
- `Unable to find module 'game_actionbar' required by 'game_interface'`
- `Unable to find module 'game_bot' required by 'game_interface'`
- `attempt to index field 'game_healthinfo'` in
  `client_options/options.lua:392, :283, :326`.

Now removed from `interface.otmod` and the matching options.lua references are
defensive (nil-check before `.show()` / `.healthCircle:setVisible(...)` /
`.topHealthBar:setVisible(...)`).

### Right-click menu — final final
Two categories `playershop_a_create` (own char → create window) and
`playershop_b_view` (other selling player → buy window). Sorted-key iteration
in `gameinterface.lua` ensures deterministic order; categories with all
conditions returning false also have their separator skipped now (so plain
ground/empty right-click doesn't show empty separator strips).

### Chat allowlist — final
Only `!fecharloja`, `!lojas`, `/shop`, and `/shop *` pass while selling. Any
other message: red failure msg "Voce so pode digitar !fecharloja enquanto a
loja esta aberta." (in `console.lua sendCurrentMessage`).

Earlier I had hooks on `g_game.talkChannel`/`talkPrivate`/`talk` that blocked
ALL chat including commands. Removed — `console.lua sendCurrentMessage` is the
only entry point we need. Don't re-add the g_game hooks; they over-block.

### Message colour conventions — final
- Green (`MESSAGE_INFO_DESCR` → `centerGreen` via the §7c client patch):
  - "Loja aberta. Voce nao pode se mover ate fechar." (info on success)
  - "Loja fechada." (info on close, all variants)
- Red (REJECT opcode → `displayBroadcastMessage` → `centerRed` via
  `MessageModes.Warning`):
  - All blocking messages from server-side `PlayerShop_Reject` calls
- White at bottom (`displayFailureMessage` → `statusSmall`):
  - Client-side validation failures (chat allowlist, missing title client-pre-check)

`onReject` does NOT use `displayPrivateMessage` (lightblue → top, looks like
PM). Was the source of the "blue at top" bug earlier.

### Commits today
- Realera (`lemosss/TFS-1.5-Downgrades` branch `8.0`):
  - `cc9c2cd5` — playershop polish + buyer PZ enforcement
  - (this CLAUDE.md update will be its own commit)
- otclientv80 (`lemosss/otclientv8` branch `master`):
  - `3359c5b` — initial PlayerShop module + interface patches
  - `3b7db71` — shop icon as creature shield texture
  - `589f555` — cleaner Create-Shop UI

### MAJOR REFACTOR end-of-day: depot-backed shop stash

The shop now uses **the seller's depot as the source** instead of the
inventory:

- `PlayerShop_Open` walks all `player:getDepotChest(townId, false)` for
  towns 1..10 (`eachDepot` helper), runs the same recursive
  `findItemInDepot` search, validates cross-slot stock against depot
  totals, then **physically removes the items from the depot** (down to
  the requested count, splitting stacks via `setCount`).
- `ActiveShops[playerId].items[slot]` becomes a virtual stash:
  `{ itemId, count, price, charges, actionId }` only. No live engine
  Item reference. The actual items no longer exist anywhere on the
  player while the shop is open.
- `PlayerShop_Buy` now creates a fresh item via `buyer:addItem(itemId,
  qty)` (or `addItem(itemId, charges)` for charged non-stackables like
  UH/GFB) and decrements `entry.count`. No more `findItemInInventory`
  on the seller.
- `PlayerShop_Close` recreates whatever is left in the seller's
  **default depot (town 1, Thais)** via `Game.createItem(itemId, count)`
  + `setSubType(charges)` + `setActionId(actionId)` +
  `depot:addItem(item)`. Items return to the depot regardless of which
  town's depot they originally came from.
- Charges/actionId of NON-stackable items are preserved across the
  open→close cycle. Custom XML attributes (gem imbues, custom_text)
  are NOT preserved by `Game.createItem` — fungible items only.
- Backed off the `onMoveItem` blocks (both in `events/scripts/player.lua`
  and in `04_events.lua`'s `EventCallback`) — items are no longer in
  inventory, so the seller can freely move/drop other things while the
  shop is open. The seller is still movement-locked at one tile so
  buyers can find them.

`PlayerShop_SendInventoryList` (the OPCODE_INVENTORY_LIST response that
populates the create-shop window's picker) is technically unused now in
the new flow — the client-side cursor-grab pattern picks any UIItem the
user clicks (including depot UI items). Server validates against depot.
Old function kept around in case we revive a depot list popup.

### Open threads / next session
- **Bubble widget over creature head** still disabled. Math went off during
  local-player walk (camera interpolation isn't accounted for). Would need
  either `Creature:getDrawOffset()` to be exposed correctly OR a different
  positioning API. Code is in `playershop.lua updateBubblePositions` as a
  no-op stub for now.
- **`Player:getVipList()` not exposed** in this TFS build. VIP list gold-color
  + icon when a VIP entry opens shop is wired client-side but the server can't
  iterate VIPs to push targeted STATE_BROADCASTs to watchers. Would need either
  a small C++ binding or a SQL-side query.
- **Tibia.dat / Tibia.spr** show as modified in `otclientv80` git but I haven't
  committed those. Earlier note in §7 covered the OldServ-vs-vanilla swap; the
  current state may have been touched by the user during the session. If
  there's a desired final state, decide and commit separately.
- **Custom item attributes lost** on shop close (depot reinsertion). Fungible
  items (charges, count, actionId) are preserved; custom string attrs and
  imbues are not. Acceptable for now since the server doesn't have many such
  items.
- **Multiple-town depots merge on return**: items returned to depot id 1
  regardless of where they came from. Could store `originDepotId` on the shop
  entry to return precisely. Low priority.
- **Persistence** — shops still don't survive a server restart (intentional —
  per §10's spec section 6). Reopen manually after save.

---

## 14. Day-7 — Player Shop final polish + native skull icon (SHOP_ICON) + walkthrough lock

Big session. Player Shop reached "ship-ready" state. Major moves: ditched the
custom STATE_BROADCAST opcode for the seller icon and used the **native skull
slot of the protocol** instead (instant render via `AddCreature` packet, just
like PK skull); fixed several depot-related bugs that were dating back since
Day-5; reworked the create-shop picker into a sprite grid; locked walkthrough
between players via a focused source patch.

### Why we ditched the custom opcode for the icon

The Player Shop originally drew its visual indicator (the little coin on the
seller's head) via a custom extended opcode (`STATE_BROADCAST = 135`) on a
3-second tick. The flow looked like:

```
Server tick (3s) → for every active shop → broadcast STATE pkt to specs
Client onStateBroadcast(isOpen=1) → creature:setShield(1) + setShieldTexture(...)
```

Two real-world bugs followed from that design:

1. **3-second visual lag when entering spec range**. A buyer who came up the
   stairs / walked into view of a seller had to wait until the next tick fired
   to see the icon. PK skull, by contrast, is instant because the server bakes
   the skull byte into the `AddCreature` packet itself.

2. **Conflict / cleanup pain**. Setting / clearing the shield slot via Lua
   meant we had to manually restore the "real" shield (party shield, etc.)
   when the shop closed, which sometimes raced or left stale icons.

The clean fix was to ride on the protocol's existing skull byte — same
mechanism PK uses — instead of hand-rolling our own broadcasting:

```
TFS protocol (7.72/8.0) AddCreature packet:
  ...
  uint8_t skullByte    ← server writes Player::getSkullClient(viewer) here
  ...
```

By making `getSkullClient` return our new `SHOP_ICON = 7` whenever the
target player is selling, every existing pathway that ships a skull update
to a client (`AddCreature` on appear, `sendCreatureSkull` on change) just
worked, instantly, with zero extra opcodes. The custom STATE_BROADCAST
still exists, but it's now relegated to carrying the **shop text** (for
the "Open Shop" menu hook on others, and locking `iAmSelling` on the
seller's own client). Not on the critical path for the icon anymore.

### The transition problem & `Game.updateCreatureSkull`

There was one wrinkle: `getSkullClient` is only consulted by the server
when it's writing a skull byte to send. The two trigger points are:
- `AddCreature` (when a creature first appears in someone's spec range).
- `sendCreatureSkull` (called from `Game::updateCreatureSkull`).

If a player who's *already visible* opens or closes a shop, neither
trigger fires automatically — the skull stays stale on every nearby
client until the seller leaves and re-enters spec range. So we exposed
`Game::updateCreatureSkull` to Lua and the shop's open/close handlers
now call it explicitly:

```lua
player:setStorageValue(88810, 1)        -- mark as selling
Game.updateCreatureSkull(player)        -- push the new skull to all specs
```

That single call iterates every spectator and ships a `sendCreatureSkull`
packet, which makes every nearby client re-render the icon **on the same
frame** the seller pressed "Iniciar Venda". Identical UX to a /look
command turning into the green text — instant, native, no polling.

### Source patches (require rebuild)

```
cmake --build "C:/Users/Lemos/Desktop/Realera TFS 1.5/build" \
  --config RelWithDebInfo --parallel 8 --target tfs
```

#### `src/const.h` — new skull id
Added `SHOP_ICON = 7` to `enum Skulls_t`. Slot 6 (`SKULL_ORANGE`) was already
defined but never used in any logic — opted for a fresh id so the semantics
are unambiguous ("this is a shop seller, not a PK"). The shipped 7.72/8.0
protocol just reads a single byte for skull, so any 0..255 works as long as
client maps it.

#### `src/player.cpp` — `getSkullClient` patches the skull on-the-fly
```cpp
// PlayerShop: if this player has shop active (storage 88810 == 1), return
// SHOP_ICON to ALL viewers regardless of world/PvP type.
if (creature) {
    const Player* targetPlayer = creature->getPlayer();
    if (targetPlayer) {
        int32_t playerShopFlag;
        if (targetPlayer->getStorageValue(88810, playerShopFlag) && playerShopFlag == 1) {
            return SHOP_ICON;
        }
    }
}
```
That's all that was needed for the icon. Server now writes the new skull byte
into every `AddCreature` packet (when the creature first appears in the spec
range of another player). **No more custom opcode tick** for the icon — just
sits in the protocol like PK does.

#### `src/player.cpp` — `canWalkthrough` / `canWalkthroughEx` simplified
Removed the upstream "ALLOW_WALKTHROUGH in PZ + 2-second cooldown +
position-match" logic entirely. Now both functions just return:
```cpp
if (group->access || creature->isInGhostMode()) return true;
return false;
```
Reason: the upstream logic let click-to-walk *bypass* the cooldown because the
A* pathfinder calls `canWalkthrough` once per evaluated tile (registering
`lastWalkthroughAttempt` and `lastWalkthroughPosition`). When the player
actually arrived at the seller's tile, the second call inside the 2-second
window passed silently. Setinha (manual stepping) only fires the function once
per attempt, so it correctly bumped against the gate. By killing the
walkthrough logic entirely, both setinha and click behave the same: nobody
walks through anybody. GMs (access) and ghost-mode still walk through.

#### `src/luascript.cpp` + `src/luascript.h` — exposed `Game.updateCreatureSkull(creature)`
Already existed in C++ (`Game::updateCreatureSkull` calls
`sendCreatureSkull` on every spec) but had no Lua binding. Without it,
`getSkullClient` only re-evaluates when a spec enters the spec range — so
the **transition** "open/close shop in front of someone already nearby"
was still slow. Now Lua can:
```lua
player:setStorageValue(88810, 1)
Game.updateCreatureSkull(player)   -- pushes the new skull to all specs
```
Implementation:
```cpp
int LuaScriptInterface::luaGameUpdateCreatureSkull(lua_State* L) {
    Creature* creature = getCreature(L, 1);
    if (!creature) { lua_pushnil(L); return 1; }
    g_game.updateCreatureSkull(creature);
    pushBoolean(L, true);
    return 1;
}
```
Also added `registerEnum(SHOP_ICON)` so the Lua constant is available.

### Lua server changes

#### `data/scripts/playershop/02_core.lua`
- `PlayerShop_Open` calls `Game.updateCreatureSkull(player)` right after
  `setStorageValue(88810, 1)`. Icon appears instant for everyone in spec
  range.
- `PlayerShop_Close` does the same right after `setStorageValue(88810, -1)`.
  Icon disappears instant.
- **Recursion-into-containers bug fixed**: this fork does NOT expose
  `Item:getContainer()` (only `Container` methods on the userdata directly,
  since `setItemMetatable` assigns the Container metatable when
  `item->getContainer()` is non-null in C++). The old code did
  `local c = it.getContainer and it:getContainer()` which short-circuited
  to `nil` for every item — meaning **the recursion into BPs in the depot
  never fired**. Now uses `if ItemType(it:getId()):isContainer() then
  it:getSize(); it:getItem(i)` directly. Touched `findItemInDepot`,
  `removeFromDepots`, the cross-slot stock check and
  `PlayerShop_SendInventoryList`.
- **Empty-container filter**: backpacks/bags only enter the picker list if
  they're 100% empty. Defense-in-depth: even if the picker bypassed the
  filter, `removeFromDepots` checks `isCont and getSize() > 0` inline
  before calling `it:remove()`, so a non-empty container can never be
  destroyed by mistake.
- **Stackable vs non-stackable aggregation**: stackables aggregate by
  `itemId` (1 entry total, count summed); non-stackables become one entry
  per instance with `count=1` and a unique virtual `uid` (incremental
  counter). Each entry now carries a `stackable` boolean in the payload.
  Uids are regenerated on every `SendInventoryList` call; client caches
  the snapshot and reuses it across slots so the uid filter (preventing
  double-booking) stays consistent.
- **Buyer rollback if no inv space**: `buyer:addItem(itemId, qty, false)`
  with `canDropOnMap=false`. Returns nil if cap/slots/bag are full → gold
  refund + reject. No more items dropping on the floor.
- **PK can't open shop**: `canOpenShop` rejects skull White/Red/Black.
- **Logout returns items to depot**: `04_events.lua` logout handler calls
  `PlayerShop_Close(playerId, reason, player)` so the depot inserts run
  while the player ref is still valid; server's auto-save persists.
- **Owner-view mode**: clicking "Open Shop" on yourself with an active
  shop opens the same `ShopViewWindow` used by buyers, but in owner mode
  (Comprar buttons hidden, Fechar becomes "Cancelar Loja" → sends
  `OPCODE_SHOP_CLOSE`). Server flag in payload: `isOwner = 1` when
  `buyer == sellerId`. Each successful purchase also re-sends `SHOP_DATA`
  to the seller so the owner-view refreshes live.
- **Green floating sale message**: seller gets `MESSAGE_INFO_DESCR`
  ("VENDA! X comprou Yx Z por N gold..."), routes to `centerGreen` via
  the client's MessageMode mapping (same path as `/look`).

#### `data/scripts/playershop/04_events.lua`
- `stateTick` interval 3000 → 250ms. Now does spec-diff: keeps a
  `LastSeenSpecs[sellerId] = { [specId] = true }` cache and only sends
  `STATE_BROADCAST` to specs that **just** entered the seller's range
  since the last tick. Plus a re-affirm to the seller themself every ~2s
  (8 ticks) to keep `iAmSelling` locked.
  This is now mostly redundant for the icon (skull comes via protocol)
  but still drives: shop text in cache, `iAmSelling` walking lock,
  `sellingCreatures` for the menu hook visibility on others.

### Client changes (`otclientv80`)

#### `modules/gamelib/creature.lua`
```lua
ShopIcon = 7    -- new constant matching server's SHOP_ICON
...
function getSkullImagePath(skullId)
  ...
  elseif skullId == ShopIcon then
    path = '/modules/game_playershop/icons/shop_icon'
  end
end
```
Now `Creature:onSkullChange(7)` (called automatically by the engine when the
server sends the new skull) loads `shop_icon.png` instead of leaving it blank.

#### `modules/game_playershop/playershop.lua`
- Removed the manual `setSkull(1) + setSkullTexture(SHOP_ICON_PATH)` from
  `onStateBroadcast`: it's not needed anymore since the icon comes via
  protocol.
- Removed the `connect(Creature, onAppear, ...)` re-apply hook — also
  redundant.
- `onStateBroadcast(isOpen=0)` now just clears the `sellingCreatures[cid]`
  cache and the `iAmSelling` flag. The skull restoration is the engine's
  responsibility (server sends a new skull update via the same
  `Game.updateCreatureSkull` call).
- Walking/chat/turn locks already gated on `iAmSelling`; that flag stays
  in sync via STATE_BROADCAST as before.

#### `modules/game_playershop/create_shop.lua`
- Picker rewritten to use a **sprite-grid** layout (`PickerCell` style:
  56×64 tile with item sprite + count badge + truncated name + tooltip
  on hover; gold border on hover, brown highlight when selected).
  `PickerWindow` style has search field, scrollable grid, **OK button**
  (next to Cancel; click cell + OK to confirm, double-click also works,
  Enter confirms).
- Search filter is live (case-insensitive substring on item name).
- Already-allocated filter: stackables subtract `count` per `itemId` from
  other slots; non-stackables hide the entry by `uid`. The current slot
  is excluded from subtraction so the user can replace its selection.
- Inventory snapshot is **fetched once per `openCreateShop`** and cached
  in `inventoryList`. `openItemPicker` re-uses the cache (without
  re-requesting). Critical because the server regenerates virtual uids on
  every `SendInventoryList`; if we re-fetched per-slot, the uids saved
  in earlier slots would no longer match.
- Each cell creation wrapped in `pcall` and a `panel:updateLayout()` is
  called at the end — guards against a single bad item id breaking the
  whole picker, and forces grid recalc.
- First `populatePickerList` is deferred via `scheduleEvent(..., 1)`
  to give the grid panel a frame to compute its width before the cells
  are added (otherwise some cells were rendering at position 0,0).

#### `modules/game_playershop/shop_view.lua`
- Buyer view rebuilt on `ShopBuyRow` style (44px row with 36×36 item
  sprite + name + gold price + qty TextEdit + Buy button).
- Owner-mode (`isOwner=1` from server): hides qty/buy on each row, makes
  the close button "Cancelar Loja" (sends `OPCODE_SHOP_CLOSE`).
- `viewSellerId` tracking + `onStateBroadcast(isOpen=0)` auto-closes the
  view if the seller's shop ends while we have it open (last item sold,
  logout, expiration, etc.).
- ESC closes the window without canceling the shop.
- `sellerLine` got `anchors.right + text-auto-resize + text-wrap` so
  long seller names ("Vendedor: Some Long Name") aren't cut off.

#### `modules/game_playershop/playershop.otui`
- Added new styles: `PickerCell`, `PickerWindow`, `QtyWindow`,
  `ShopBuyRow`, plus expanded `ShopViewWindow`.

### Reference: storage key + ids

| Item | Value | Notes |
|---|---|---|
| Storage key | `88810` | `setStorageValue(88810, 1)` = selling, `-1` = not |
| Skull id (server `Skulls_t`) | `SHOP_ICON = 7` | Set by `getSkullClient` when storage flag is 1 |
| Skull id (client `creature.lua`) | `ShopIcon = 7` | Maps to `/modules/game_playershop/icons/shop_icon` |
| Opcode `STATE_BROADCAST` | 135 | Now only used for shop text + `iAmSelling` flag, NOT for icon |
| Opcode `INVENTORY_LIST` | 137 | Carries the new `stackable` byte per entry |
| Opcode `SHOP_DATA` | 134 | Carries `isOwner` byte for owner-view mode |
| Opcode `SHOP_CLOSE` | 131 | Used by owner "Cancelar Loja" button |

### Outstanding (not blockers, future polish)

- **Persistent shop label above the seller's head** (the "balãozinho")
  — **RESOLVIDO sem rebuild do client**. Plot twist: o OTC v8 release
  pré-buildado em `Desktop/otclientv80/otclient_gl.exe` JÁ tem as
  funções `Creature:setTitle(text, font, color)` / `Creature:clearTitle()`
  expostas pro Lua (confirmado via `grep -ao` no binário). Isso usa
  o sistema interno de "title" do OTC, que renderiza um texto colado
  acima do nome (em `creature.cpp drawInformation`, junto ao
  `m_titleCache`) e segue a creature naturalmente quando ela se move,
  sem decay nem chat-pollution.

  Implementação: em `playershop.lua onStateBroadcast(isOpen=1)`,
  chama `creature:setTitle(text, 'verdana-11px-rounded', '#FFD700')`
  com a mensagem da loja em dourado. Em `isOpen=0`, chama
  `creature:clearTitle()`. Hook adicional em `connect(Creature,
  onAppear, ...)` re-aplica o title quando a creature reaparece no
  campo de visão (pq o title é state local do client e some quando
  a creature é destruída/recriada por sair/entrar do spec range).

  Caveat: a função ficou disponível "por sorte" — esse OTC v8 build é
  fork do release 3.2 rev 4 (Feb 2023, commit `aacfe3f`) e os autores
  já tinham incluído `setTitle` no Lua bindings (`luafunctions_client.cpp`
  line 552-554). Outros forks/builds podem não ter. O `pcall`
  envolvendo as chamadas mantém compatibilidade — se a função não
  existir, simplesmente não desenha o title (ícone via skull continua
  funcionando standalone).

- **Lista vazia sem filtro**: this was a real issue earlier in the
  session. Two stacked bugs caused it (see commit
  `77f60ef playershop: real-time picker populate via onGeometryChange`):
  (a) `g_keyboard.bindKeyPress('Return', ...)` raises an error on this
  build of OTC v8 (`Return` key name not recognized → triggers
  `connect(nil, ...)` in keyboard.lua:144), aborting `openItemPicker`
  before `populatePickerList` was ever called on first open. The
  `searchEdit.onTextChange` handler had been registered earlier in the
  function and was the only path running the populate, hence the
  "type to see items" symptom. Fix: dropped the Return/Enter keybinds.
  (b) Even after that, the picker grid panel sometimes reported width=0
  on its first frame, so cells fell at pos 0,0 and were invisible. Fix:
  attach a `onGeometryChange` listener to the gridPanel and re-call
  populatePickerList when the panel ends up with valid dimensions.
  Resolved.
- VIP list color sync — `Player:getVipList()` still not exposed.
- Persistence across server restart — shops still die when server stops.

---

## 15. Day-8 — Per-rune stack cap + drag-drop UX + blank rune NPC sale

### Problem 1 — Rune stacks could grow past their `<charges>` cap
Realera ships runes flagged `FLAG_STACKABLE` in `items.otb`, so multiple casts
or manual drag-merge between BPs could pile a single slot well beyond the
spec'd charges (e.g., a 4-stack of GFB merged with another 4-stack → 8-stack
in one slot). Per-rune cap was never enforced; the engine fell back to the
generic `100` stack max baked all over the inventory code.

**Fix** — hardcoded `100` replaced with a per-item lookup. Added an inline
helper on `Item`:

```cpp
// src/item.h, after getItemCount/setItemCount
uint32_t getStackMax() const {
    const ItemType& it = items[id];
    if (it.isRune() && it.charges > 0) {
        return it.charges;          // SD=1, UH=1, GFB=4, HMM=10, WG=2, ...
    }
    return 100;                     // gold/spear/arrow/etc unchanged
}
```

12 sites of literal `100` switched to `someItem->getStackMax()`:
- `src/container.cpp` lines 370/372 (queryMaxCount loop), 378/380
  (queryMaxCount specific index), 481 (autoStack same-slot match), 488
  (autoStack list scan), and the `freeSlots * 100` term on line 386
  → `freeSlots * item->getStackMax()`.
- `src/game.cpp` lines 1210 (`internalMoveItem` merge cap) and 1322
  (`internalAddItem` merge cap).
- `src/player.cpp` lines 2590/2591 (queryMaxCount inventory loop), 2599
  (`if (item->isStackable()) n += 100;` empty-slot count), 2616/2617
  (queryMaxCount specific slot).

After rebuild, server refuses any add that would push a rune past
`it.charges`. Manual drag-merge of 4-stack onto another 4-stack of GFB now
goes into a free slot instead of mashing into 8.

**Pitfall to remember**: don't grep `100` blindly — most hits are the
"% out of 100" / weight-1g threshold / loot chance / etc. Look for the
specific patterns `100 - .*itemCount` and `getItemCount() < 100`.

### Problem 2 — Drag-drop sent count=1 for runes (1 rune at a time)
Two layers of mismatch in the 8.0 client:
1. The 8.0 `Tibia.dat` flags runes as **charge** items, not stackable. So
   the OTC `item:getCount()` always returns 1 for runes regardless of how
   tall the visible stack is. The visible byte (server stack size) lives
   in `item:getCountOrSubType()`.
2. The default OTC drag handlers gate the count-prompt on `getCount() > 1`,
   so for runes it skipped the prompt **and** sent count=1 to the server.
   Net result: drop a 5-stack on the floor → only 1 rune leaves.

**Fix** — `otclientv80/modules/gamelib/ui/uiitem.lua` and
`otclientv80/modules/game_interface/widgets/uigamemap.lua`:

```lua
local id = item:getId()
if id >= 3147 and id <= 3203 then
    -- 8.0 client.dat rune range (server ids 2260-2316). Runes drop /
    -- move as whole stacks, no quantity prompt.
    local stack = item:getCountOrSubType()
    if stack < 1 then stack = 1 end
    g_game.move(item, toPos, stack)
elseif item:getCount() > 1 then
    modules.game_interface.moveStackableItem(item, toPos)   -- existing prompt
else
    g_game.move(item, toPos, 1)
end
```

Other stackables (gold 3031, spear 2389/clientId 3277, arrow, etc.) keep
the original prompt-based path.

**Sprite-id range derivation** — needed because OTC's `Item:getId()`
returns the **dat clientId**, not the items.otb serverId. Used the existing
`parse_otb.py` to walk every `(serverId, clientId)` pair where
`2260 <= serverId <= 2316` (the entire rune block in items.xml) and read
off min/max client id → 3147..3203. Verified against live drag traces
captured via debug `print()` (e.g. fireball server 2302 → client 3189,
explosion 2313 → 3200).

### Problem 3 — Blank rune wasn't sold by anyone
NPC sale stripped earlier (see day-7 cleanup). Re-enabled only blank rune
across NPCs that share `data/npc/scripts/runes.lua` (Eryn, Rachel, Xodet
in this server). One uncomment in `runes.lua` is enough — every NPC whose
XML has `script="runes.lua"` picks it up:

```lua
shopModule:addBuyableItem({'blank rune', 'blank'}, 2260, 10, 1, 'blank rune')
```

10 gp each. Other rune sales (SD, UH, GFB, …) stayed commented — players
still get them only by conjuring.

### Side-quest: discovered the 12-NPCs-share-Xodet.lua trap
While debugging Xodet's broken trade, learned that `Frans.xml`,
`Rachel.xml`, `Topsy.xml`, `Xodet.xml`, `Asima.xml`, `Chuckles.xml`,
`Fenech.xml`, `Frederik.xml`, `Romir.xml`, `Shiriel.xml`, `Sigurd.xml`,
`Tandros.xml` ALL declare `script="Xodet.lua"`. The sibling files
`Frans.lua`, `Rachel.lua`, `topsy.lua` exist on disk but **no XML
references them** — orphan code. Editing `Frans.lua` to add a shop entry
silently does nothing.

**Lesson**: before editing a per-NPC `.lua`, always grep
`grep -l 'script="<NPC>.lua"' data/npc/*.xml` to confirm anything actually
loads it. Don't trust filename = NPC.

(Note: in **this** Realera server, the equivalent group of NPCs uses
`runes.lua`, not `Xodet.lua`. The 12-NPCs trap is from the parallel
`OT/TFS-1.5-Downgrades` tree; mirrored the lesson here because the same
search-for-the-real-script pattern applies.)

### Files touched

Realera TFS 1.5 (this repo):
- `src/item.h` — `getStackMax()` helper
- `src/container.cpp`, `src/game.cpp`, `src/player.cpp` — replace 12x `100`
- `data/npc/scripts/runes.lua` — uncomment blank rune buyable

`C:\Users\Lemos\Desktop\otclientv80\` (the matching client repo —
`lemosss/otclientv8` master):
- `modules/gamelib/ui/uiitem.lua`
- `modules/game_interface/widgets/uigamemap.lua`

### Open thread

- **Open Shop (player shop) sprite mismatch** — user reports backpack
  rendering as a stone coffin in the shop window. Likely an items.otb ↔
  Tibia.dat clientId desync for backpack items, OR the player shop UI
  passes the wrong id (server vs client) to a sprite render call. Not
  investigated yet; pending a concrete repro item id.

## 16. Day-9 — Depot save trigger fix + PlayerShop server↔client id mismatch + buyer-view UX overhaul

Three independent shop bugs surfaced when the user actually tried to sell items, plus the buyer-view UI got a real layout pass. Each fix is small but the root causes are subtle, so they're documented in detail below.

### Problem 1 — Items put into the depot disappeared on logout

Repro: drop a stack of dice + a backpack into the depot, log out, log back in. Both old depot contents AND the items just placed reappeared in the depot — i.e. the depot was effectively in a "frozen" state and never re-saved.

Root cause: `IOLoginData::savePlayer` only runs the depot DELETE+INSERT block when at least one DepotLocker reports `needsSave()=true` (`src/iologindata.cpp` ~line 800). The locker's `save` flag flips inside `DepotLocker::postAddNotification` / `postRemoveNotification`. But the player puts items in the **DepotChest** (the chest INSIDE the locker), and `DepotChest::postAddNotification` walks the parent chain via `getParent()` — which intentionally jumps TWO levels up (parent.parent → tile), skipping the locker. So the locker's `save` flag never flipped, the whole depot save block was skipped on logout, and the DB held whatever state was there before the session.

Fix (`src/iologindata.cpp` after the existing `for (... player->depotLockerMap)` loop): also check `player->depotChests` for `needsSave()`. Pushed as `56e92cee` on branch `8.0`. After rebuild, depot persists exactly the in-memory state on logout.

### Problem 2 — "Voce nao possui o item do slot 1 no depot" when starting a shop

Repro: open Create Shop, add a Fireball Rune (or any item — also reproduced with backpack and dice), set price, click Iniciar Venda → server rejects with `Voce nao possui o item do slot N no depot.`

Cause: the inventory list packet was packing the item's **clientId** (Cipsoft `Tibia.dat` id) but `findItemInDepot` searches with `it:getId() == itemId` where `Item:getId()` returns the OTB **serverId**. For a Fireball Rune that's serverId 2302 vs clientId 3189 — never equal, always rejected. Worked for items where serverId == clientId by coincidence (e.g. dice 5792).

Fix (two-sided):

**Server** — `data/scripts/playershop/02_core.lua`, `PlayerShop_SendInventoryList`: send BOTH ids in each entry (serverId u16 BEFORE the existing clientId u16). Wire format change is +2 bytes per entry.

**Client** (otcv8-dev `modules/game_playershop/create_shop.lua`):
- `create_shop_inventory` parses both ids; stores `entry.id = clientId` (for `widget:setItemId()` rendering) AND `entry.serverId = serverId` (echoed back on OPEN).
- `assignItemDirect` / `assignItemToSlot` copy `s.serverId = entry.serverId or 0`.
- `populatePickerList`'s `matches` table builder ALSO needs to copy `serverId` — without this, the picker filter loop strips it on the way to the slot. Real bug was here; without it `entry.serverId` arrived `nil` at `assignItemDirect`, the slot stored `0`, and the OPEN packet still sent `itemId=0`. Caught via debug `print` at the OPEN-payload pack site after staring at the trace for 20 minutes.
- `sendShopOpen` packs `s.serverId or 0` instead of `s.entryId`.

Pushed as `1d9be52d` (server) and `4e4d987` + `aa6df29` (client).

**General lesson** for the playershop wire protocol: the server's lookup APIs (`findItemInDepot`, `Player:findItem`, all the depot/inventory walks via `Item:getId()`) want the **server OTB id**. The client renders sprites via `widget:setItemId(clientId)` (Tibia.dat id). Always send both ids and use the right one in each direction. Naming the field `entryId` blurs the distinction — `entry.serverId` / `entry.clientId` would have prevented this whole detour.

### Problem 3 — Drag-drop UI bugs in Create Shop (qty prompt opens twice)

Repro: open the picker, pick a stackable item, the quantity prompt pops up, type 5, click OK → list closes BUT the quantity prompt is still there waiting for another OK.

Cause: OTC dispatched both `cell.onDoubleClick` AND `pickerWindow.okBtn.onClick` for the same gesture (double-click on cell), so `promptCountAndAssign` ran twice, creating two stacked qty windows.

Fix — `promptCountAndAssign` calls `destroyPickerWindow()` BEFORE creating the qty widget. `destroyPickerWindow` sets `pickerSelected = nil`, so the okBtn closure's `if pickerSelected and pickerSelected.entry then` check short-circuits on the second invocation. Pushed as `f54b8a2`.

### Problem 4 — `verdana-11px` font typo + OTUI parse cascade

The seller-bubble font in `playershop.lua` was set to `'verdana-11px'` (no suffix). That .otfont doesn't exist; only `verdana-11px-antialised` / `-monochrome` / `-rounded`. Result: every state-broadcast tick (every 250ms) emitted `ERROR: font 'verdana-11px' not found`. Also: `text: -- g` placeholder in the gold-counter widget was treated as a Lua-style comment by the OTUI parser, breaking the entire ShopViewWindow style declaration with cascading errors. Two unrelated typos that compounded into "buyer view doesn't open at all".

Fix:
- `playershop.lua` — `'verdana-11px'` → `'verdana-11px-antialised'`.
- `playershop.otui` — strip ALL `--` style comment lines (OTUI doesn't accept Lua-style comments at the top level), and `text: -- g` → `text: 0 g`.

Lesson: when the user reports "this whole thing doesn't open", check for OTUI parse errors before assuming a Lua bug. The terminal's `failed to load UI from 'playershop.otui': '' is not a defined style` is the smoking gun for a comment-line / property-name typo killing the parse.

### Buyer view (`ShopViewWindow`) — full layout redesign

Before this session the buyer view was a vertical stack of `ShopBuyRow` widgets (item slot + name + price + qty input + per-row Buy button). User asked for the Onigashima/Priston-Tale style: search bar at the top, sprite grid in the middle, single info panel at the bottom with the selected item's details + a single Buy button + a description box.

New OTUI structure (`modules/game_playershop/playershop.otui`, `ShopViewWindow`):

```
ShopViewWindow (460x470)
├── (sellerLine: visible:false, height:0 — shop blurb shown only via the
│    seller's overhead bubble, not duplicated in the window)
├── searchLbl + searchEdit + searchClearBtn
│    (search row anchored ONLY to the right half of the window per user
│    request: searchEdit.left = parent.horizontalCenter)
├── viewItems (ScrollablePanel, layout:grid, cell-size 38x38, panel_flat
│    texture)
│    └── 1..N ShopBuyCell widgets (one per shop item)
├── infoPanel (UIWidget, 110px tall)
│    ├── selName, priceLbl, amountScroll (HorizontalScrollBar),
│    │   amountLbl, weightLbl  (LEFT column)
│    ├── previewSlot (UIWidget wrapper) > previewItem (Item, default
│    │   /images/ui/item slot bg)
│    │   buyBtn underneath  (MIDDLE column)
│    └── descPanel (panel_flat) > descText  (RIGHT column)
├── footerSep (HorizontalSeparator above closeBtn)
├── goldBox (panel_flat texture, 150x20) — contains goldIcon (UIItem,
│    no slot bg, item-id 3031 = client.dat gold coin) + goldLbl
│    (right-aligned)
└── closeBtn (anchored bottom-right)
```

`shop_view.lua` rewritten to:
- Build cells in a grid via `ShopBuyCell` (replacing `buildItemRow`).
- Track `selectedCell` + `selectedEntry`. `selectCell()` toggles `:setOn` on the focused cell (gold border via `$on` style state).
- Search bar `onTextChange` runs `applySearchFilter()` which `setVisible(false)` on cells whose name doesn't contain the needle. Pure client-side filter.
- `amountScroll` (HorizontalScrollBar) min=1, max=stack count. `onValueChange` updates `amountLbl` AND `previewItem:setItemCount(value)` so the preview sprite badge tracks the chosen amount.
- Single Buy button (`buyBtn`) sends `OPCODE_SHOP_BUY` with `(sellerId, slot, amount)` based on selectedEntry + amountScroll value.
- Double-click on a cell shortcuts to "buy at current amount".

Subtle UI gotchas worth remembering:

- **`Item < UIItem`** (`data/styles/10-items.otui`) bakes `image-source: /images/ui/item` into every `Item` widget. To get a sprite WITHOUT the inset slot frame around it, use `UIItem` directly (skip the style). Used for `goldIcon`. For `cellItem` / `previewItem` we ended up using `Item` so the slot bg matches BP rendering.
- **`/images/ui/panel_bottom`** is 165x160 with a strong inset frame baked in; `image-border: 7` on a small panel gives a clean 9-slice frame, but on tall scrollable panels (the items grid) the middle stretch produces visible horizontal bands. Use `/images/ui/panel_flat` (32x32 plain stone) for the grid + bottom-info panels, keep `panel_bottom` for the chat-style framed boxes only.
- **Forward-anchor refs in OTUI** work for parent-relative anchors but FAIL on cross-anchored pairs like "A.bottom = B.top" + "B.top = A.bottom". Hit this when chaining `searchClearBtn` → `searchEdit` → `searchClearBtn`. Solution: anchor the clear button to a stable reference (`parent.right` + fixed size + `margin-top`) instead of stretching it to match `searchEdit.top/bottom`.
- **OTUI `text:` value parsing** treats `--` as a Lua-ish comment marker only at line start; inside a value it's literal. But `text: -- g` confused the parser regardless and broke the whole style. Avoid `--` in OTUI value strings entirely.

### Gold counter — bank + cash piggyback on SHOP_DATA

Tibia 7.72 doesn't expose the player's wallet to the client (no AmountUpdate packet, no balance query). To show the buyer how much they can spend without a separate roundtrip:

`PlayerShop_SendShopDataTo` walks the buyer's open backpack hierarchy via `Container:getItem()` recursion, summing item counts of gold coin (2148) + plat (2152) ×100 + crystal (2160) ×10000. Combined with `Player:getBankBalance()` for the bank portion. The total (capped at uint32_t max) is appended to the SHOP_DATA payload right after the `isOwner` flag, BEFORE the item count `n`. Client parses it into module-scope `viewBalance` and `goldLbl:setText(tostring(viewBalance))`.

Per-item weight (in 1/100 oz units, the `it.weight` value from items.xml × 100) is also appended to each item entry, between `charges` and `name`. Client formats `e.weight / 100` with two decimals for the Weight: label and the descPanel tooltip.

### Files touched

Realera TFS 1.5 (this repo, branch `8.0`):
- `src/iologindata.cpp` — depot save trigger via depotChests fallback
- `data/scripts/playershop/02_core.lua` — INVENTORY_LIST adds serverId; SHOP_DATA adds buyer balance + per-item weight

otcv8-dev (`lemosss/otcv8-dev`, branch `master`):
- `modules/game_playershop/playershop.otui` — full ShopViewWindow rewrite + ShopBuyCell style + goldBox + searchBar
- `modules/game_playershop/shop_view.lua` — grid build, selection, search filter, balance/weight rendering
- `modules/game_playershop/create_shop.lua` — serverId in match copy + qty prompt double-fire fix
- `modules/game_playershop/playershop.lua` — onGameEnd tears down all shop windows, font fix, dev print cleanup
- `modules/client/client.otmod` — drop dangling `client_mobile` dependency from earlier cleanup commits
- `modules/gamelib/ui/uiitem.lua` + `modules/game_interface/widgets/uigamemap.lua` + `modules/game_interface/gameinterface.lua` — `getEffectiveCount(item)` helper for rune drag (3147-3203 client.dat range = server 2260-2316), routes runes through `moveStackableItem` so the count window respects the visible stack instead of `getCount()=1`. Plus `moveStackableItem.commit()` reads `getItemCountOrSubType()` (raw byte) instead of `getItemCount()` (which returns 1 for charge-flagged dat items even after `setItemCount(N)` populates the visual).

### Day-9 follow-up — Lua compat shims + bank NPCs number formatting

Two NPC-side errors surfaced after the Day-9 push:

1. `data/lib/miscellaneous/050-functions.lua:127: attempt to call a nil value (global 'isNumber')` — fired from Suzy.lua and any NPC that uses `isValidMoney()` from the deposit/transfer flow. Root cause: `data/lib/101-compat.lua` aliases `isNumber = isNumeric` but `isNumeric` itself was never defined anywhere in this fork. Both globals end up nil; `isValidMoney(money)` then crashes.

2. `data/lib/core/player.lua:59: attempt to call a nil value (method 'getPremiumDays')` — fired from Captain Bluebear and any NPC that calls `Player:isPremium()`. Root cause: this TFS exposes `Player:getPremiumEndsAt()` (unix timestamp) but not `Player:getPremiumDays()`. The `core/player.lua` `Player.isPremium` definition calls `getPremiumDays()` directly.

Fix in `data/lib/compat/compat.lua`:

```lua
function isNumeric(n) return type(n) == 'number' end
isNumber = isNumeric

function Player.getPremiumDays(self)
    local endsAt = self.getPremiumEndsAt and self:getPremiumEndsAt() or 0
    if endsAt == 0 then return 0 end
    local left = endsAt - os.time()
    if left <= 0 then return 0 end
    return math.floor(left / 86400)
end
```

### Bank NPCs — `formatGold` thousand-separator + strip Lua float `.0`

Suzy still saying `Your account balance is 509988.0 gold.` — Lua `tostring(number)` renders integers via the float formatter so any value > 0 prints with the `.0` suffix, and 6-7 digit balances are unreadable. User asked for `509.988` style (dot every 3 digits, no decimal).

Helper added to `data/lib/compat/compat.lua` (global, available to all NPC scripts):

```lua
function formatGold(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    if out:sub(1, 1) == '.' then out = out:sub(2) end
    return out
end
```

Applied across **24 NPC scripts** (`bank.lua` + 23 town-banker copies that each kept their own per-NPC dialog instead of delegating to the shared `bank.lua`): `Ebenizer.lua`, `Eighty.lua`, `Elgar.lua`, `Eva.lua`, `Ferks.lua`, `Finarfin.lua`, `Gnomillion.lua`, `Jefrey.lua`, `Jessica.lua`, `Kaya.lua`, `Kepar.lua`, `Lokur.lua`, `Murim.lua`, `Muzir.lua`, `Naji.lua`, `Paulie.lua`, `Plunderpurse.lua`, `Raffael.lua`, `Rokyn.lua`, `Siestaar.lua`, `Suzy.lua`, `Virgil.lua`, `Wentworth.lua`, `Znozel.lua`.

Patches done via Python regex (more reliable than 24 individual sed calls) — patterns wrapped:
- `player:getBankBalance() .. " gold` → `formatGold(player:getBankBalance()) .. " gold`
- `count[cid] .. " gold` / `... of your` / `... platinum coins` / `... crystal coins` / `count[cid] * 100 .. " of your` — same wrapping

Numeric arithmetic (`if count[cid] < 1`, `player:depositMoney(count[cid])`, `removeItem(ITEM_GOLD_COIN, count[cid] * 100)`) intentionally NOT touched — those need raw numbers.

**Lesson** (already known from earlier sessions but worth restating): town bankers in this datapack never delegate to `bank.lua`; each NPC has its own copy of the dialog. Any future bank-side change has to be applied across the 24-file group via bulk script. Same trap as the `Xodet.lua` orphan-script note from Day-8.

### Day-9 simplification — drop client-side seller restrictions, keep only the server anchor

User decision: stop client-side babysitting of the seller. The character is allowed to TRY to walk / turn / click / chat normally; the only enforcement is the server warping them back to the anchor tile if they actually moved. Cleaner UX, less code.

**Removed (`otcv8-dev`):**

1. `modules/game_walking/walking.lua` `walk(dir, ticks)` — was early-returning when `modules.game_playershop.iAmSelling` (~line 274). Removed.
2. `modules/game_walking/walking.lua` `turn(dir, repeated)` — same iAmSelling early-return (~line 414). Removed.
3. `modules/game_interface/gameinterface.lua` left-click autowalk — `if iAmSelling then return false end` inside the autoWalkPos branch (~line 779). Removed.
4. `modules/game_interface/gameinterface.lua` right-click swallow — early-return at top of `processMouseAction` that swallowed right-click on other creatures during shop. Removed entirely.
5. `modules/game_console/console.lua` chat block — `sendCurrentMessage` had a whitelist that only allowed `/shop`/`!fecharloja` while iAmSelling. Removed.

**Kept (server-side, in `data/scripts/playershop/04_events.lua`):**

```lua
local tick = GlobalEvent("PlayerShopTick")
tick:interval(500)
tick:onThink(function()
    for sellerId, shop in pairs(ActiveShops) do
        local seller = Player(sellerId)
        if seller then
            local cur = seller:getPosition()
            if not shop.anchorPos then
                shop.anchorPos = cur
            elseif cur.x ~= shop.anchorPos.x or cur.y ~= shop.anchorPos.y or cur.z ~= shop.anchorPos.z then
                if PlayerShop_TileIsPZ(shop.anchorPos) then
                    seller:teleportTo(shop.anchorPos, false)
                else
                    PlayerShop_Close(sellerId, "Shop closed (left protection zone).")
                end
            end
            ...
        end
    end
end)
```

So the seller may type / click / right-click / attack / turn / etc. all they want — every 500ms the tick checks if their tile changed and slams them back. Still tight enough that nobody can actually leave. Final follow-up: user kept WASD / arrow-key movement blocked client-side (subjective UX choice — they don't want the visual "step + warp" twitch from keyboard mashing), so `walk()` got its iAmSelling early-return PUT BACK while `turn()` stayed open. The `Player:onTurn` event in `data/events/scripts/player.lua` ALSO had a `sendCancelMessage("Voce nao pode virar com a loja aberta.")` block that had to be removed for turning to actually go through.

**To revert and re-enable client + server locks** (in case Idle Shop / similar later needs the seller frozen):

| File | What to put back |
|---|---|
| `otcv8-dev/modules/game_walking/walking.lua` `walk()` (after `if not player or g_game.isDead()...`) | `if modules.game_playershop and modules.game_playershop.iAmSelling then return end` (currently in place — keyboard movement still blocked) |
| `otcv8-dev/modules/game_walking/walking.lua` `turn()` (right after the local player) | same `iAmSelling` early-return (currently REMOVED — turning allowed) |
| `otcv8-dev/modules/game_interface/gameinterface.lua` `processMouseAction()` autowalk branch | `if modules.game_playershop and modules.game_playershop.iAmSelling then return false end` before `player:autoWalk(autoWalkPos)` |
| `otcv8-dev/modules/game_interface/gameinterface.lua` `processMouseAction()` top | early `if mouseButton == MouseRightButton and iAmSelling then return true end` swallow |
| `otcv8-dev/modules/game_console/console.lua` `sendCurrentMessage()` (before the chat-disable check) | the iAmSelling whitelist block — only allow `/shop ...` to pass through |
| `Realera TFS 1.5/data/events/scripts/player.lua` `Player:onTurn` (top of function, before the access check) | `if ActiveShops and ActiveShops[self:getId()] then self:sendCancelMessage("...") return false end` to stop the server's onTurn dispatch |

### Open thread

- **Shop Pass (48h consumable)** — pending: a Lua-action item that, when used, sets storage `STORAGE_SHOP_PASS_EXPIRES = 88811 = os.time() + 48*3600`, stacking. `canOpenShop()` rejects with "You need a Shop Pass to open a shop." if the storage is `<= os.time()`. Item id TBD.
- **Shop Idle** — bigger feature. Three architectures discussed (NPC ghost / player offline-active / persistence-only). User to pick before implementation.
- **Seller view (`CreateShopWindow`) redesign** — second screenshot reference. Description-focused with Idle Shop / Edit Description / History buttons, slider-based price entry. Old slot-list still in place.
- **History** — per-shop sales log; needs new persistence (storage table or new SQL table).

---

## 17. Day-10 — Seller-view grid rewrite + qty-modal + draft restore + info-panel polish

All edits client-side this day (`otcv8-dev/modules/game_playershop/`). Server (TFS) untouched. Branch: `master` on `lemosss/otcv8-dev`.

### Seller view (`CreateShopWindow`) — grid rewrite

The old vertical-list seller layout was replaced with a grid of `ShopSellerCell`s mirroring the buyer view (same 36×36 cells, same info panel below, same description box on the right).

- **Dynamic `+` cell**: `ensureTrailingPlus()` keeps exactly **one** trailing empty cell at the end of the grid. Filling it auto-spawns a new `+` after it (until `MAX_SLOTS = 20`). Removing a slot destroys the widget entirely (no empty placeholders) and `ensureTrailingPlus()` re-adds a `+` if needed.
- `slots[]` is now indexed `{ entryUid, entryId, serverId, count, charges, price, name, stackable, widget }`. `selectedSlotIndex` is module-scoped.
- Click handler: empty cell → opens picker. Filled cell → `selectSlot(index)` (highlights + populates info panel).
- Info panel: `slotName`, `slotPriceLbl` + `slotPriceEdit` (live-editable), `slotAmountLbl`, `slotRemoveBtn`, `previewSlot`/`previewItem`, `descPanel`/`descText`. Price changes update `slots[index].price` instantly (validated 1..1e9; out-of-range turns the edit red).
- `commitCreateShop()`: walks filled slots in order, packs `entryUid:u32`, `serverId:u16`, `count:u16`, `price:u32` per item.

### Modal qty dialog

The "How many?" prompt for stackable items used to drift behind the create / picker windows when the user clicked outside it. Fixed via a transparent overlay that sits BETWEEN qtyWindow and everything else:

```lua
local overlay = g_ui.createWidget('UIWidget', rootWidget)
overlay:fill('parent')
overlay:setBackgroundColor('#00000000')
overlay:setFocusable(false)
overlay.onMousePress = function() return true end  -- swallow all clicks
qtyWindow:raise()
qtyWindow:focus()
```

After `qtyWindow:raise()` the z-order is `[..., createWindow, overlay, qtyWindow]`. Clicks inside qtyWindow's bounds reach its children (OK/Cancel/edit). Clicks outside hit the overlay and are eaten by the `return true`. Belt+suspenders: a `closeQty()` helper unified by a `destroyed` guard handles OK / Cancel / Enter / Escape, and tears down both overlay and qtyWindow together.

### Pre-load rejected draft (and clear on success)

When the server rejects the OPEN payload (e.g. "Invalid price item slot 1"), the client used to drop everything and the seller had to re-pick all items from scratch. Now:

1. `commitCreateShop()` already cached `lastSavedSlots = { [idx] = { uid, id, serverId, count, charges, price } }` before closing the window.
2. `openCreateShop()` now sets `pendingRestoreDraft = lastSavedSlots ~= nil and next(lastSavedSlots) ~= nil`.
3. `create_shop_inventory()` (the inventory-list response handler) calls `restoreDraftSlots()` BEFORE `populatePickerList()` so the picker filters consider the items already consumed by restored slots.
4. `restoreDraftSlots()` matches saved entries against the fresh inventory:
   - Non-stackable: by `uid` (each depot instance unique).
   - Stackable: by `serverId`, count clamped to `min(saved.count, available)`.
   - Items that no longer exist (sold / moved) are silently skipped — no phantom slots.
5. After re-fill, `s.price = saved.price` is written back so the user doesn't re-type prices.

**Cache lifecycle** — the cache must NOT persist past a successful open or the user gets a confusing "ghost previous shop" on every Open Shop click. Cleared in two places:
- `playershop.lua` `onStateBroadcast` when `cid == lp:getId() and isOpen == 1` (server confirmed the shop is up): `lastSavedText = nil; lastSavedSlots = nil`.
- `onGameEnd` (Ctrl+Q / character switch) — already clears it.

REJECT does NOT clear (server sends `isOpen=0` after a REJECT, but the cache-clear is gated on `isOpen == 1`).

| Situation | `lastSavedSlots` | Next Open Shop |
|---|---|---|
| Reject | kept | grid auto-restored |
| Open succeeded → user closes shop later | cleared at open | empty grid |
| Logout / Ctrl+Q | cleared in `onGameEnd` | empty grid |

### Info-panel spacing — Create Shop AND Buyer view

Both `infoPanel`s (`CreateShopWindow` and `ShopViewWindow`) had the price label hugging the item name because the price field is a `TextEdit` (taller than a Label) anchored to `priceLbl.verticalCenter`, so its top edge rose above the label and visually touched the line above. Fix:

| | Create Shop | Buyer |
|---|---|---|
| `priceLbl margin-top` | 4 → **14** | 4 → **14** |
| Amount label anchor | `slotPriceLbl.bottom` → **`slotPriceEdit.bottom`** | (already on `amountScroll.bottom`) |
| Amount margin-top | 6 → **8** | 4 → **8** |
| Below-amount margin-top | 6 → **8** (Remove btn) | (n/a) |

Now both panels look identical: name → 14px → price line → 8px → amount → 8px → button(s).

### `+` glyph in empty seller cells

The original `Label { text: + ; font: terminus-14px-bold }` rendered fine but felt cheap. Tried bumping to `sans-bold-16px` — broke (rendering glitch / clipped baseline). Final solution: **draw the `+` as two crossing UIWidget rectangles**, font-independent and pixel-perfect:

```otui
UIWidget
  id: cellPlus
  anchors.centerIn: parent
  size: 16 16
  phantom: true

  UIWidget   -- horizontal bar
    anchors.centerIn: parent
    size: 14 2
    background-color: #b8b8b8
    phantom: true

  UIWidget   -- vertical bar
    anchors.centerIn: parent
    size: 2 14
    background-color: #b8b8b8
    phantom: true
```

The wrapper keeps the `cellPlus` id so `cell.cellPlus:setVisible(true/false)` (called by `setCellEmpty`/`setCellFilled`) works unchanged — hiding the wrapper hides both bars. `phantom: true` everywhere lets hover events bubble up to the parent cell, which now has `$hover: background-color: #ffffff14` for a subtle clickable feedback.

**OTUI gotcha (re)hit during this work**: `--` is NOT a valid comment in OTUI. Adding `-- description` lines inside a style block makes the parser treat them as broken declarations. Stick to no inline comments, or describe styles in CLAUDE.md / Lua-side instead.

### Files touched (otcv8-dev)

- `modules/game_playershop/playershop.otui` — ShopSellerCell rewrite (+ hover + 2-rect `+`), CreateShopWindow grid layout, info-panel spacing on both windows.
- `modules/game_playershop/create_shop.lua` — full rewrite for grid + dynamic `+` + draft restore + modal qty.
- `modules/game_playershop/playershop.lua` — `onStateBroadcast` clears draft cache on confirmed open; minor tidy.

No server-side changes today.

---

## 18. Day-11 — Sales history (lifetime SQL log) + scrollbar polish + rune-shop crash root fix

Big day. Three independent threads landed:
1. Full **History tab** in the create-shop window (paginated lifetime sales log, SQL-backed).
2. **Scrollbar / X clear button alignment** + EN translation pass on residual PT-BR strings.
3. **Root-cause fix** for the native crash that happened when cancelling a shop with runes listed.

Branches: `lemosss/TFS-1.5-Downgrades` 8.0 (server) and `lemosss/otcv8-dev` master (client).

### History tab — server side (`Realera TFS 1.5`)

New revscript `data/scripts/playershop/07_history.lua` creates and queries `playershop_history`:

```sql
CREATE TABLE IF NOT EXISTS `playershop_history` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_guid`  INT UNSIGNED NOT NULL,
    `buyer_name`   VARCHAR(40)  NOT NULL,
    `item_id`      SMALLINT UNSIGNED NOT NULL,
    `item_name`    VARCHAR(120) NOT NULL,
    `item_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `price_total`  BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `ts`           INT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_seller_ts` (`seller_guid`, `ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

Schema runs idempotently at boot via `db.query`. Three Lua entry points:

- `PlayerShop_LogSale(sellerGuid, buyerName, itemId, itemName, count, priceTotal)` — wired into `PlayerShop_DoBuy` (`02_core.lua` line ~590) right after the seller is bank-credited. Uses `db.asyncQuery` so the BUY transaction never blocks on disk. Defensive truncation (40/120 chars) protects against malformed names blowing up the INSERT.
- `PlayerShop_FetchHistory(sellerGuid, page, pageSize)` — `LIMIT/OFFSET` over the `(seller_guid, ts DESC, id DESC)` ordering. Returns `(entries, totalEntries, totalPages)`. Page is 1-indexed; pageSize defaults to 20 (clamped to 1..100).
- `PlayerShop_SendHistoryPage(player, page, pageSize)` — wraps fetch into the OPCODE_SHOP_HISTORY wire payload.

Two new opcodes (in `01_config.lua` `PlayerShopOpcode` and the matching client constants):

- `HISTORY_REQUEST = 139` — C→S: `u16 page, u16 pageSize`
- `HISTORY = 140` — S→C: `u16 currentPage, u16 totalPages, u32 totalEntries, u16 entryCount, then per entry: u32 ts, str buyer, str itemName, u16 count, u32 priceTotal`

`03_opcodes.lua` dispatches `HISTORY_REQUEST` to `SendHistoryPage`.

### History tab — client side (`otcv8-dev`)

`CreateShopWindow` was redesigned — bottom row reordered to match the Onigashima reference screenshot:

```
[gold-counter] [Start Shop] ───── [History] [Close]   ← items mode (default)
[gold-counter] [Start Shop] ───── [Items]   [Close]   ← history mode
```

OTUI changes:
- `cancelBtn` renamed to `closeBtn` (semantic cleanup).
- `summaryBox` (text "X items, total: Y gold") replaced by `goldBox` matching the buyer view: panel_flat + image-border + UIItem goldIcon (3031 = client.dat gold coin id) + Label `goldLbl` showing thousand-separated total expected revenue.
- `historyBtn` and `itemsBtn` declared at the same anchor, toggled via `setVisible`.
- New `historyPanel` overlaying the items grid area when active: header row (`Date | Buyer | Description | Price`), `histHeaderSep`, scrollable `histListPanel` (verticalBox layout), `histFooterSep`, footer with `histEntries` label + centered pagination cluster `|< < N/M > >|`. New `HistoryRow` style — 16px tall thin row holding `rowDate / rowBuyer / rowDesc / rowPrice` labels (anchored Date→Buyer→Desc(flex)→Price right-aligned).
- `descClearBtn` and `searchClearBtn` got `margin-right: 3` so their right edge lines up with the scrollbar's right edge instead of sticking 3px past it.

Lua changes (`create_shop.lua`):
- `historyMode` boolean + `historyCurrentPage / historyTotalPages / historyTotalEntries` module-scope state. `HISTORY_PAGE_SIZE = 20`.
- `enterHistoryMode()` / `enterItemsMode()` flip visibility of `ITEMS_MODE_WIDGETS = { 'shopText', 'descLbl', 'descClearBtn', 'slotsPanel', 'scrollBar', 'infoPanel' }` against `historyPanel` and swap the bottom-right buttons.
- `requestHistoryPage(n)` clears the list, updates pagination state, sends OPCODE_SHOP_HISTORY_REQUEST with `(page, HISTORY_PAGE_SIZE)`.
- `renderHistoryEntries(entries)` (called from `onShopHistory` in `playershop.lua`) destroys the list children and builds one `HistoryRow` per entry. Date formatted as `DD/MM HH:MM` (locale-agnostic, fits 90px column). Description is `'%dx %s'` for count > 1 else just the name; tooltip set on overflow.
- `refreshHistoryFooter()` updates `histEntries`/`histPageLbl` and enables/disables pagination buttons (`|<` `<` disabled at page 1, `>` `>|` disabled at last page).
- `openCreateShop` resets `historyMode=false`/`page=1` so the next session always starts on the items grid.

`HistoryRow` initially had a `$hover: background-color: #ffffff14` tint that made the rows flicker as the mouse moved; user disliked it, removed (commit `7b6ca5a`).

### Scrollbar polish

The three vertical scrollbars (picker / create / buyer) and the horizontal `amountScroll` were aligned to match the MiniWindow scrollbar visual model used by Skills/Inventory:

| | Before | After |
|---|---|---|
| `pickScrollBar width` | 12 (override) | default 13 |
| All 3 verticals `margin-right` | 0 | 3 |
| `amountScroll pixels-scroll` | (not set) | true |
| `amountScroll step` | (default) | 1 |

Always-visible (NO `$!on: width: 0` — user explicitly wanted the bar fixed, not collapsing-on-fit like MiniWindow).

### Residual PT-BR translations

Found and translated:
- `'Voce esta longe demais. Aproxime-se do vendedor.'` (red `displayBroadcastMessage` in `gameinterface.lua` left-click intercept) → `'You are too far away. Get closer to the seller.'` via `displayStatusMessage` (white above chat).
- `'(nenhum item bate com a busca)'` / `'(esta loja nao tem itens)'` → `'(no items match the search)'` / `'(this shop has no items)'`.
- `'Sua loja: '` (owner-view banner) → `'Your shop: '`.
- Cell tooltip `'cada'` → `'each'`.
- `qtyLbl text: Quantidade:` → `Quantity:`.

### Buyer balance fix

`PlayerShop_SendShopDataTo` was using a manual `countItemInBP` walk that only scanned `CONST_SLOT_BACKPACK`. Coins held in the player's hand / ammo / non-BP slots were ignored from the displayed balance, while `PlayerShop_DoBuy` correctly used `Player:getMoney()` (which scans every slot + nested containers + converts plat/crystal to gp). Result: display showed less than the player could spend. Replaced the manual walk with `buyer:getMoney()` so display and charge agree.

### Bug fixes (rune-related)

Three native-engine bugs surfaced this day and were fixed at the root:

**1. `Item:setCount` is not bound** — `02_core.lua` line ~237 in the depot-strip code did `it:setCount(c - left)` to keep the unsold remainder when a partial-stack was listed (e.g. seller has 5 GFB runes, lists 4 → keep 1). `Item:setCount()` is NOT registered in this TFS 1.5 build (only `getCount`, `transform`, `remove`, `split`). The Lua error aborted `PlayerShop_Open` mid-flight and left the depot half-stripped. Fix: replaced with `it:remove(pulled)` — `internalRemoveItem(item, count)` is the canonical path, modifies the stack in place to (count - pulled) when partial, deletes when full.

**2. Sales-history seller key was a runtime creature ID** — `LogSale` and `SendHistoryPage` were using `Player:getId()` (runtime creature id, reassigned every login) instead of `Player:getGuid()` (persistent DB pk = `players.id`). Result: a sale logged in session N would never appear when the seller relogged for N+1 because the WHERE clause looked for the new creature id. Both call sites switched to `getGuid()`.

**3. Shop-cancel crash on partial-rune lists — ROOT CAUSE FIX** — when a player listed 4 of a 5-stack of runes and clicked Cancel Shop, the server CRASHED natively (real segfault, not Lua error). Diagnosis took a debug-print pass through every step of `PlayerShop_Close` to narrow it to `chest:addItem(2302, 4)`.

   The crash was deep in `Game::internalAddItem` (`game.cpp:1320-1352`) — the merge code path for stackable items. `Item::getStackMax()` (`item.h:960`) for runes returns the items.xml `charges` value, which was inconsistent with what `spells.xml` actually conjures:

   | Rune id | items.xml had | spells.xml conjures | Stack actually seen |
   |---|---|---|---|
   | 2292 envenom | charges=1 | charges=5 | up to 5 |
   | 2302 fireball | 2 | 5 | up to 5 |
   | 2304 great fireball | 2 | 4 | up to 4 |
   | 2308 soulfire | 3 | 5 | up to 5 |
   | 2311 heavy magic missile | 5 | 10 | up to 10 |
   | 2313 explosion | 3 | 6 | up to 6 |

   Player has a 5-stack but engine thinks max=2 → on merge, `n = min(stackMax(2) - existing(1), addQty(4)) = 1`, leftover `count = 4-1 = 3`. The code recurses to add the 3-stack to a chest where the only existing fire-bomb stack is now at the (engine-believed) max. Internal pointer math during the recursive add ends up dereferencing an Item that was already `ReleaseItem`-ed. Segfault.

   **Two attempted fixes**, settled on the second:

   - First attempt (commit `82286959`'s neighbor, never landed): a Lua-side workaround that walked the chest manually with `Item:transform` to top up existing stacks before falling back to `addItem`. Worked but added 50+ lines and a parallel implementation of merge logic. Abandoned in favor of the root fix.
   - Final fix (commit `2f0ff9d3`): synced `data/items/items.xml` charges values to match `spells.xml`. Now `getStackMax()` returns the real max — `n = min(stackMax(5) - 1, 4) = 4`, `count = 0`, fully-merged path runs cleanly without recursion. Native engine merge works correctly without any Lua workaround. Six rune ids touched (see table above).

   **Lesson**: in this codebase, `data/items/items.xml charges` is the SINGLE SOURCE OF TRUTH for both rune charges-per-cast AND stack max. When introducing or changing rune behavior in `spells.xml`, mirror the value in `items.xml` or the engine's stack/merge math will bug out silently for partial-stack operations.

### Test data inserted

For paginated history demo, 30 then 40 records inserted into `playershop_history` for `MS Lemos` (guid=5):
- Mix of 11 distinct buyer names
- 13 distinct rune/coin/equipment ids
- Counts 1..1000x (exercises the `Nx item` formatter)
- Prices 5g .. 480.000g (exercises thousand-separator)
- Timestamps spanning seconds-ago to ~58 days ago (exercises `ts DESC` ordering)

40 entries / 20 per page = 2 pages — `|<` `<` disabled on page 1, `>` `>|` disabled on page 2, footer alternates between `1/2` and `2/2`.

### Files touched

**Server (`Realera TFS 1.5`):**
- `data/scripts/playershop/07_history.lua` — NEW. Schema + LogSale + FetchHistory + SendHistoryPage.
- `data/scripts/playershop/01_config.lua` — added `HISTORY_REQUEST = 139` / `HISTORY = 140` to PlayerShopOpcode table.
- `data/scripts/playershop/02_core.lua` — wired `PlayerShop_LogSale` into DoBuy; switched to `getGuid()`; replaced broken `Item:setCount` with `Item:remove(pulled)`; replaced manual `countItemInBP` walk with `Player:getMoney()`.
- `data/scripts/playershop/03_opcodes.lua` — dispatch `HISTORY_REQUEST` to `SendHistoryPage`.
- `data/items/items.xml` — six rune charges values synced to spells.xml.

**Client (`otcv8-dev`):**
- `modules/game_playershop/playershop.otui` — bottom-row layout rework, `historyPanel` + `HistoryRow` styles, scrollbar margins, X clear button alignment, qtyLbl translation, hover removal on history rows.
- `modules/game_playershop/create_shop.lua` — history mode toggle + pagination + render entries.
- `modules/game_playershop/playershop.lua` — opcode constants 139/140 + `onShopHistory` parser + register/unregister.
- `modules/game_playershop/shop_view.lua` — empty-search hint, owner-view banner, cell tooltip translations.
- `modules/game_interface/gameinterface.lua` — too-far message switched to `displayStatusMessage` (EN, white).

---

## 19. Day-12 — Walkthrough on shop sellers + open-shop tile validation + create-shop UI polish

Three threads in this session:
1. **Engine patch + client mirror** so other players can walk through a seller whose shop is currently active (no more shop-corridor barriers).
2. **Open-shop validation**: 3x3 area must be free of other players, and seller can't be on a depot locker tile or directly behind one.
3. **Create-shop window UI polish**: PickerCell rewrite (icon-only, tooltip-named), unified hover tint across all 3 cell types, History view widens dynamically, column dividers added, goldBox widened+right-aligned, instant menu-hook registration.

### 19.1 Walkthrough on shop sellers (C++ engine + client mirror)

**Problem.** A row of player shops planted on a stair landing or PZ chokepoint blocks every buyer's path: setinha (WASD), arrow keys, AND click-to-walk all hard-bounce off the seller's tile. Buyers had to push each seller out of the way one tile at a time, and the seller's `iAmSelling` anchor would warp them right back. Unusable in practice.

**Server-side fix (`src/player.cpp`).** `Player::canWalkthrough` and `Player::canWalkthroughEx` are the engine's "can this player be walked over" decision points. Patched both to return true when the target creature is a Player whose `STORAGE_PLAYERSHOP_SELLING = 88810` is set to 1 (matches `PlayerShopConfig.storageKey` from `01_config.lua`):

```cpp
static constexpr uint32_t PLAYERSHOP_SELLING_STORAGE = 88810;

static bool isPlayerActiveShopSeller(const Creature* creature) {
    const Player* other = creature ? creature->getPlayer() : nullptr;
    if (!other) return false;
    int32_t value;
    return other->getStorageValue(PLAYERSHOP_SELLING_STORAGE, value) && value == 1;
}

bool Player::canWalkthrough(const Creature* creature) const {
    if (group->access || creature->isInGhostMode()) return true;
    if (isPlayerActiveShopSeller(creature)) return true;  // NEW
    return false;
}

bool Player::canWalkthroughEx(const Creature* creature) const {
    if (group->access) return true;
    if (isPlayerActiveShopSeller(creature)) return true;  // NEW
    return false;
}
```

`canWalkthrough` controls actual movement permission (used by `Tile::queryAdd` -> `internalMoveCreature`); `canWalkthroughEx` controls the client visual hint (semi-transparent rendering in `protocolgame.cpp:3087`'s `0x00/0x01` byte).

The 88810 constant is hardcoded with a comment pointing back to the Lua source of truth — if the storage key ever changes in `01_config.lua`, update this side too.

**Client-side mirror (`otcv8-dev/modules/game_walking/walking.lua`).** Initially after the C++ patch, click-to-walk worked but WASD/arrow walks died silently. Root cause: `walking.lua` line 376 does `if toTile and toTile:isWalkable() then` BEFORE sending the walk packet. `Tile:isWalkable()` returns false the moment any creature is on the destination, so the buyer's WASD step never even reached the server. Click-to-walk uses a different path (autoWalk) that doesn't run this check.

Fix: before the early-return, scan `toTile:getCreatures()` for anyone in `modules.game_playershop.sellingCreatures` (the cache populated by `OPCODE_SHOP_STATE_BROADCAST`). If found, treat the destination as walkable from the client's perspective so the packet gets sent — the server then validates via the C++ `canWalkthrough` and lets the move through.

```lua
local destHasShopSeller = false
if toTile then
    local shopMod = modules.game_playershop
    if shopMod and shopMod.sellingCreatures then
        for _, c in ipairs(toTile:getCreatures() or {}) do
            if shopMod.sellingCreatures[c:getId()] then
                destHasShopSeller = true; break
            end
        end
    end
end
if toTile and (toTile:isWalkable() or destHasShopSeller) then
    ...
```

**End-to-end flow now:**
1. Server: shop opens -> sets storage 88810 = 1 + sends STATE_BROADCAST.
2. Buyer's client: receives STATE_BROADCAST -> caches the seller in `sellingCreatures[cid]`.
3. Buyer presses WASD -> walking.lua sees the seller is in cache -> skips the isWalkable bounce -> sends walk packet.
4. Server: `Tile::queryAdd` -> `canWalkthrough(seller)` -> reads storage 88810 == 1 -> returns true -> move allowed.
5. Visually: `canWalkthroughEx` returns true -> client renders the seller semi-transparent so the buyer SEES that the tile is passable.

**To revert** (in case Vanguard kills the binary or some side-effect surfaces):
- `src/player.cpp` -> revert the `isPlayerActiveShopSeller` helper + remove the two `if` checks; rebuild.
- `otcv8-dev/modules/game_walking/walking.lua` -> remove the `destHasShopSeller` block + revert the `if` to `if toTile and toTile:isWalkable() then`.

**Build note.** Vanguard locked `tfs.exe` again on the relink. Standard workaround: `taskkill //F //IM tfs.exe` first, then rebuild. CMake build dir stays at `build/RelWithDebInfo/`.

### 19.2 Open-shop tile validation

Two new checks added to `canOpenShop` in `data/scripts/playershop/02_core.lua` so sellers can't park their shop on path-blocking spots.

**Player nearby (3x3) — `PlayerShop_OtherPlayerNearby(seller)`**

Walks the 8 adjacent SQMs + the seller's own tile. Any OTHER player found -> reject. Prevents shop-barriers across stair landings and chokepoints (where multiple sellers would form an impassable wall together with the shopping crowd).

```lua
for dx = -1, 1 do
    for dy = -1, 1 do
        local tile = Tile(Position(pos.x + dx, pos.y + dy, pos.z))
        if tile then
            for _, c in pairs(tile:getCreatures() or {}) do
                if c and c:isPlayer() and c:getId() ~= sid then
                    return c
                end
            end
        end
    end
end
```

Reject message: *"You need a clear 3x3 SQM area around you to open a shop (no other players within 1 tile in any direction)."*

**Depot proximity — `PlayerShop_OnBlockedDepotTile(pos)`**

Iterated through several designs (3x3, 5x5 box, Manhattan-2 diamond) and landed on the **minimum useful blocking**: just two specific tiles per depot — the locker tile itself, and the tile directly behind the locker. Direction-aware via the 4 locker sprite ids:

```lua
local DEPOT_BEHIND_OFFSET = {
    [2589] = {  0, -1 },   -- faces S -> behind = N
    [2590] = { -1,  0 },   -- faces E -> behind = W
    [2591] = {  0,  1 },   -- faces N -> behind = S
    [2592] = {  1,  0 },   -- faces W -> behind = E
}
```

Algorithm: (1) seller's own tile has `ITEM_TYPE_DEPOT`? Reject. (2) For each cardinal neighbor of the seller, if that neighbor has a depot whose `DEPOT_BEHIND_OFFSET` points back at the seller (i.e., the locker is facing AWAY from the seller, putting the seller on its back side), reject.

Reject message: *"You can't open a shop on a depot locker tile or directly behind one."*

**Why "minimum blocking" instead of an area buffer.** Earlier iterations used a 3x3 or 5x5 around the depot, but those rejected innocent spots that don't actually obstruct buyer access (e.g., 2 tiles diagonally from the locker on a wide PZ floor). Sellers complained the rule felt arbitrary. The locker-behind-only rule reflects the only spot a seller can stand that's both physically reachable AND on someone else's natural walking path to the depot.

**Caveat about the orientation map.** The id->direction mapping (`2589 = south-facing`, etc.) is the standard convention but never directly verified against the sprite art. If you ever see a shop allowed on the actual back of a locker (or rejected on the front), swap pairs in `DEPOT_BEHIND_OFFSET` until it lines up.

### 19.3 Create-shop window UI polish

A bunch of small pieces of polish (already individually committed in `3ef6b18`, `5b46349`, `63ad170`) — recap here so the shape of the window is documented in one place after these landed.

**PickerCell rebuilt.** Old `PickerCell` was 56x64 with the item icon at the top and a left-aligned name label below (`die`, `backpack`, `fireball.`, etc.) with a bar truncate at 8 chars. Felt Diablo-style and mismatched the rest of the Tibia-feel UI. Replaced with a clean 38x38 cell that's just the item sprite + count badge + tooltip on hover. Picker grid `cell-size` and scroll `step` updated to match. The unused `truncate()` helper was deleted.

**Hover unified.** All three cell types (`PickerCell`, `ShopSellerCell`, `ShopBuyCell`) standardized at 38x38 with `$hover: background-color: #ffffff22`. The Item inside each is 34x34 centered, leaving a visible 2px frame all around for the hover tint to show through. Earlier the seller/buyer cells were 36x36 with 1px margin and the tint was barely visible.

**History view widens dynamically.** Clicking History expands the create-shop window from 460 to 620 px wide and re-centers horizontally on the screen so a user docked to the right edge isn't pushed off-screen. Returning to Items mode shrinks back to 460. Without this, big price values like "12.345.678" or long buyer names would crowd the columns.

**History column dividers.** Three `VerticalSeparator` widgets between the columns (Date | Buyer | Description | Price), spanning from the header top to the footer separator. Positioned 6 pixels to the LEFT of each column boundary so the line sits in the gap BEFORE the next column's text instead of bisecting the first letter of "Buyer"/"Description"/"Price". Column widths bumped (90/110/70 -> 100/140/100); separator margins followed (`margin-left: 102/242, margin-right: 124`).

**goldBox in the seller window — widened + right-aligned.** Was 100 px wide with `goldLbl` having only `anchors.right: goldIcon.left` (no left anchor or text-align), so big totals visually drifted right and slid behind the gold-coin icon. Bumped to 140 px, added `anchors.left` + `text-align: right` + 6/4 px margins. Now numbers up to ~14 chars (`999.999.999`) render flush against the right edge, never overlapping the icon.

**"Open Shop" menu hook is instant.** `init()` in `playershop.lua` was wrapping the `addMenuHook` calls in `scheduleEvent(..., 1500)` — defensive 1.5-second delay from early development. Result: after Ctrl+R reload, every other right-click menu entry was there immediately but "Open Shop" lagged in 1.5s later. OTC's module load order already guarantees `game_interface` is initialized before our `init()` runs (because we depend on it via `modules.game_interface.addMenuHook`), so the scheduleEvent is unnecessary. Removed; hooks now register synchronously and Open Shop appears instantly with the rest of the menu.

### Files touched (Day-12)

**Server (`Realera TFS 1.5`):**
- `src/player.cpp` — `canWalkthrough` + `canWalkthroughEx` walkthrough on shop sellers; needs rebuild.
- `data/scripts/playershop/02_core.lua` — `PlayerShop_OtherPlayerNearby` + `PlayerShop_OnBlockedDepotTile` + `DEPOT_BEHIND_OFFSET` map + 2 new checks in `canOpenShop`.

**Client (`otcv8-dev`):**
- `modules/game_walking/walking.lua` — destHasShopSeller mirror so WASD/arrow walks reach the server.
- `modules/game_playershop/playershop.otui` — PickerCell rewrite + cell sizes/hovers unified + History column dividers + goldBox widen.
- `modules/game_playershop/playershop.lua` — `init()` registers menu hooks synchronously.
- `modules/game_playershop/create_shop.lua` — history mode resize-and-recenter + truncate() removed.
- `modules/game_playershop/shop_view.lua` — tooltip thousand-separator + " g" suffix; dead `fmtGold` helper removed.

**Build:** `tfs.exe` rebuilt from the `player.cpp` patch.

---

## Day-13 — Inventory swap + premium overflow + free-account travel + rune NPC re-enable + Open Shop sprite + Yalahar cleanup

### Cross-session debugging note: this server now lives in `Realera OT/Realera TFS 1.5/`

The folder was reorganized this day from `Desktop/Realera TFS 1.5/` to
`Desktop/Realera OT/Realera TFS 1.5/`. The OTC client moved the same way:
`Desktop/Realera OT/otclientv80/`. Several hours were wasted today
editing `Desktop/OT/TFS-1.5-Downgrades/` (a parallel 7.72 project) NPCs
while the user was actually testing this Realera 8.0 server. The
auto-loaded CLAUDE.md when the cwd is `Desktop/OT/` now warns to verify
which server is actually running before editing — see
`Desktop/OT/CLAUDE.md` top banner.

### Per-rune stack cap (`Item::getStackMax()`)

OTB flags every rune `FLAG_STACKABLE`, but the engine had `100` hardcoded
all over the inventory code so a player could drag a 4-stack of GFB onto
another 4-stack and end up with 8 charges in one slot — beyond the rune's
`<charges>` value. Added an inline helper:

```cpp
// src/item.h
uint32_t getStackMax() const {
    const ItemType& it = items[id];
    if (it.isRune() && it.charges > 0) {
        return it.charges;          // SD=1, UH=1, GFB=4, HMM=10, WG=2 …
    }
    return 100;                     // gold/spear/arrow stay at 100
}
```

12 sites of literal `100` swapped to `someItem->getStackMax()`:
`container.cpp` 370/372/378/380/386/481/488,
`game.cpp` 1210/1322,
`player.cpp` 2590/2591/2599/2616/2617.

Don't grep `\b100\b` blindly — most hits are percentages / weight
thresholds / loot chances. Look for `100 - .*itemCount` and
`getItemCount() < 100`.

### Drag-drop runes as a whole stack (otclientv80 client)

8.0 `Tibia.dat` flags runes as **charge** items, not stackable. So in OTC
`item:getCount()` returns 1 always for runes; the visible byte (server
stack count) lives in `item:getCountOrSubType()`. Default OTC drag
handlers gate the count-prompt on `getCount() > 1`, so dropping a 5-stack
of GFB on the floor only sent count=1 → 1 rune moved per drop.

Both `modules/gamelib/ui/uiitem.lua` and
`modules/game_interface/widgets/uigamemap.lua`:

```lua
local id = item:getId()
if id >= 3147 and id <= 3203 then
    -- 8.0 client.dat rune range (server ids 2260-2316). Whole stack.
    local stack = item:getCountOrSubType()
    if stack < 1 then stack = 1 end
    g_game.move(item, toPos, stack)
elseif item:getCount() > 1 then
    modules.game_interface.moveStackableItem(item, toPos)
else
    g_game.move(item, toPos, 1)
end
```

**The 3147-3203 range was derived empirically.** OTC's `Item:getId()`
returns the dat clientId, NOT the server itemid. Standard 7.x dat had
runes at 2260-2316 (matching server ids), but the 8.0 dat shifts them
into 3147-3203. Walked `parse_otb.py` over the rune block in items.xml to
read the (serverId → clientId) mapping; verified live with debug prints
during a real drag (fireball server 2302 → client 3189; explosion 2313
→ 3200; SD 2268 → 3155; backpack 1988 → 2854).

### Player Shop sprite renders the wrong item — fix

User reported: a backpack inside an Open Shop window rendered as a
stone coffin, even though spawning the same item via `/i` showed the
correct backpack.

Root cause: `data/scripts/playershop/02_core.lua` was packing the server
itemid into the extended-opcode payload that builds the trade window:

```lua
-- Wrong (sends server id 1988):
payload = payload .. PlayerShop_PackU16(entry.itemId)
-- Right (sends client id 2854 for backpack):
payload = payload .. PlayerShop_PackU16(it:getClientId())
```

The OTC widget's `setItemId()` indexes `Tibia.dat`, so it expects the
**clientId**. The standard NPC trade window is fine because TFS itself
converts via `it.clientId` in `protocolgame.cpp:AddShopItem`. Custom
extended opcodes have to do the conversion manually. Fixed both shop
sites in 02_core.lua (line 467 buyer view, line 704 owner picker).

**Pattern to remember**: any time a Lua script ships an item id over
`sendExtendedOpcode` for a widget render, wrap with
`ItemType(serverId):getClientId()`.

### Equipment slot swap from ground / container

`Player::queryAdd` only returned `RETURNVALUE_NEEDEXCHANGE` (the swap
trigger) when the source cylinder was a `Player` slot or `DepotChest`.
Dragging from a `Tile` (ground) or `Container` (backpack) onto an
already-equipped slot fell through to `NOTENOUGHROOM` ("there is not
enough room"). Added `Tile` and `Container` to the cast list at
`player.cpp:2580` — equipping a sword off the floor now drops the
currently-held weapon to the same tile, mirroring DP-to-slot behavior.

### Premium-days uint16 overflow on free accounts

`protocollogin.cpp:135`:

```cpp
output->add<uint16_t>((account.premiumEndsAt - time(nullptr)) / 86400);
```

For a free account `premiumEndsAt = 0`, the subtraction gave a large
negative `time_t` that wrapped into uint16 as ~44961 days. Every free
account showed "44961 days of premium" on the login screen (and possibly
unlocked premium gating elsewhere if the client trusted the value).
Clamp to 0 when `premiumEndsAt <= now`. C++ change, requires rebuild.

### Free-account travel restricted to free cities only

The captains' local `addTravelKeyword` helpers all passed
`premium = false` to `StdModule.travel`. Combined with the
`not parameters.premium` short-circuit at modules.lua:209, every
destination from every captain was free-account-accessible. Cipsoft 8.0
rule: **free accounts only travel to Thais, Carlin, Venore, Ab'Dendriel,
Kazordoon**. Anything else is premium.

Single source of truth in `data/lib/miscellaneous/free_cities.lua`:

```lua
FREE_CITY_DESTINATIONS = {
    ['thais']=true, ['carlin']=true, ['venore']=true,
    ["ab'dendriel"]=true, ['ab\'dendriel']=true, ['kazordoon']=true,
}
function isPremiumDestination(keyword)
    if not keyword then return true end
    return not FREE_CITY_DESTINATIONS[string.lower(keyword)]
end
```

29 captain scripts had their hardcoded `premium = false` replaced with
`premium = isPremiumDestination(keyword)` (31 sites total — Captain
Fearless and Jack Fate have two travel branches each). Same regex-
friendly pattern across all captain files: the local
`addTravelKeyword(keyword, ...)` function passes its first arg to the
helper. **To change the policy later, edit ONLY the table in
`free_cities.lua`.**

### Travel cost L>=50 gate removed

Two paths in `data/npc/lib/npcsystem/modules.lua` had
`if cost and cost > 0 and player:getLevel() >= 50 then`:
- `StdModule.travel` (the one that actually charges money)
- `StdModule.say` (the dialog renderer that announces the cost)

Net effect on a level-49 player: NPC said "for free" but the .travel
path silently charged the cost (after I removed the gate from .travel
earlier in the session). The dialog was lying. Removed `>= 50` from BOTH
so the announced cost matches the deducted cost, regardless of level.

### Yalahar removed from active captains

Yalahar is Tibia 8.5; this server's .otbm has no Yalahar geometry. The
captains had `addTravelKeyword('yalahar', Position(32816, 31272, 6), …)`
guarded by storage flags that turn the captain into "I'm sorry but I
don't sail there" — but the destination is unmapped. Stripped:

- 9 `addTravelKeyword('yalahar', …)` lines across Bluebear, Fearless,
  Greyhound, Max, Seagull, Sinbeard, Charles, Jack Fate, Petros.
- 44 dialog/voice text lines across 11 captains had `{Yalahar}` /
  `, Yalahar` mentions cleaned. Regex scoped to lines containing
  `keywordHandler:addKeyword` / `local voices` / `npcHandler:say(` so
  identifiers like `Storage.InServiceofYalahar` stay intact (the latter
  is used by quest NPCs that now live in `data/npc/deadfiles/`).

### Quest NPCs without spawns moved to deadfiles

The "In Service of Yalahar" questline (Tibia 8.5) was imported into
this server but never had spawns set up — the city doesn't exist. Moved
the dormant quest NPC files (no spawn entries in `global-spawn.xml`) to
`data/npc/deadfiles/`:

- `Yalahari` (Mission 03 quest giver)
- `Mr. West` / `Mr West.lua` (Mission 04)
- `Tamerin` (Mission 05)
- `Maritima` (Mission 07)

`Palimuth` (Mission 01) and the seven Mission 02 watchmen (Barry, Bruce,
Hal, Oliver, Peter, Reed, Tony) were already in deadfiles before this
session.

**Policy: do NOT touch `global-spawn.xml`.** When in doubt about
removing a script/NPC, check if the spawn entry exists. If yes, leave
the script in place (a missing XML/script with a live spawn throws a
boot warning that the user accepts). Siflind is the canonical example —
Ice Islands quest NPC, spawn at (32361, 31029, 6) in Svargrond region.
Almost moved to deadfiles before noticing the spawn; restored.

### `maxMessageBuffer` 4 → 8

Player got muted after 4 messages in 1500ms. Bumped to 8 in `config.lua`.
Decay window in `player.cpp:1514` (1500ms) untouched. **`config.lua` is
gitignored** so this change doesn't ship via git — re-applied per
instance.

### NPC name conventions discovered the hard way

Saw on the Day-12 / earlier sessions: the OT/ tree had 12 NPCs all
declaring `script="Xodet.lua"` — Frans.lua / Rachel.lua / topsy.lua were
orphan code never loaded. **Same trap exists here**: always grep
`grep -l 'script="<NPC>.lua"' data/npc/*.xml` before editing a
per-script file. Today specifically, "Mr. West.xml" (with dot) referenced
"Mr West.lua" (without dot); "Siflind.xml" (typo) referenced
"Silfind.lua". Names don't have to match.

### Day-13 file index

Realera server (this repo):
- `src/item.h` — `getStackMax()` helper
- `src/container.cpp`, `src/game.cpp`, `src/player.cpp` — 12 hardcoded
  `100` replaced + slot-swap cylinder cast list
- `src/protocollogin.cpp` — premium days clamp
- `data/scripts/playershop/02_core.lua` — `getClientId()` for sprite
- `data/lib/miscellaneous/free_cities.lua` (new)
- `data/lib/lib.lua` — register free_cities.lua
- `data/npc/lib/npcsystem/modules.lua` — `StdModule.travel` and
  `StdModule.say` `>=50` removal
- 29 captain scripts (Bluebear, Fearless, Charles, Greyhound, Max,
  Seagull, Seahorse, Sinbeard, Anderson, Buddel, Brodrosch, Captain
  Breezelda, Carlson, Chemar, Gewen, Gurbasch, Imbul, Iyad, Jack Fate,
  Lorek, Maris Fenrock, Nielson, Old Adall, Pemaret, Petros, Pino,
  Sebastian Nargor, Sebastian, Svenson, Uzon) — premium policy via
  helper. Of those, 11 also had Yalahar text stripped.
- `data/npc/deadfiles/` (gitignored, NOT committed): dormant Yalahar
  quest NPCs (Yalahari/Maritima/Mr. West/Tamerin xml+lua + previously
  parked entries)

`Realera OT/otclientv80/`:
- `modules/gamelib/ui/uiitem.lua` and
  `modules/game_interface/widgets/uigamemap.lua` — rune drag whole-stack

Git remotes pushed:
- `lemosss/TFS-1.5-Downgrades` branch `8.0` (server)
- `lemosss/otclientv8` branch `master` (client)

**Builds**: `tfs.exe` rebuilt three times this session — for the stack-
cap patch, the inventory swap, and the premium overflow.

---

## Day-14 — NPC trade audit, Malunga sorcerer teacher, GM bypass, sprite-less item purge

### `/reload` talkaction registered + `logCommand` stub

`data/talkactions/scripts/reload.lua` was sitting in the repo with the
full `reloadTypes` table (actions / talkactions / npc / items / spells /
…) but never declared in `data/talkactions/talkactions.xml`. Typing
`/reload anything` returned "Unknown command". Added the entry next to
`/pos`:

```xml
<talkaction words="/reload" separator=" " script="reload.lua" />
```

Once registered, the script blew up on first use:
`attempt to call a nil value (global 'logCommand')`. Both `reload.lua`
and `force_raid.lua` audit-log via `logCommand(player, words, param)`
but no lib defines it. Stubbed in `data/lib/compat/compat.lua`:

```lua
function logCommand(player, words, param)
    local name = (player and player.getName and player:getName()) or '?'
    local line = string.format('[%s] %s: %s %s',
        os.date('%Y-%m-%d %H:%M:%S'), name, words or '', param or '')
    print(line)
    local f = io.open('data/logs/commands.log', 'a')
    if f then f:write(line, '\n'); f:close() end
end
```

Both fixes need a server restart on first deploy because `compat.lua`
is loaded at boot (not by `/reload`) and the broken `/reload` itself
can't reload `/reload`. After the restart, `/reload <type>` works for
subsequent edits.

### Katana lever simplified (action 3107)

`data/actions/scripts/switch/rook/katana door.lua` used to recreate a
runtime wall at (32177, 32148, 11) every toggle to gate access — but
the map already had a static wall there, so the engine was painting a
door over existing geometry. Stripped the wall toggle. Lever now just
spawns/removes a teleport at (32178, 32144, 11) → (32174, 32147, 11).
The exit-side teleport at (32171, 32149, 11) was already in the
.otbm.

### Travel L>=50 cost gate removed

Two paths in `data/npc/lib/npcsystem/modules.lua` had
`if cost and cost > 0 and player:getLevel() >= 50 then`:

- `StdModule.travel` (the one charging gold)
- `StdModule.say` (the dialog renderer that shows the cost)

A level-49 player would see "for free" but get charged silently after
my Day-13 partial fix to `.travel` only. Removed `>= 50` from BOTH so
the announced cost matches the deducted cost regardless of level.

### `Urkalio` + `Hofech` `module_shop=1` added

Both XMLs declared `shop_buyable` but missed
`<parameter key="module_shop" value="1" />`. `parseParameters` only
creates a `ShopModule` when that flag is non-zero, so neither NPC's
trade window opened — saying "trade" hit the FocusModule's farewell
fallback. One-line fix per XML.

### 12 double-registered shops consolidated to Lua-only

`Bashira / Carina / Chephan / Dario / Edvard / Eremo / Irea /
Livielle / Rachel / Shanar / Shiriel / Tesha` all declared
`module_shop=1` with a `shop_buyable` list in their XML AND a separate
`ShopModule:new() + addBuyableItem` block in their Lua. Both modules
push to `npcHandler.shopItems` and register a duplicate `trade`
keyword. Functional but wasteful. Migrated each XML's items into the
Lua (using the `Cf*` alias map from `data/npc/lib/configuration.lua`
to deduplicate by serverId), then stripped the four shop parameters
from each XML.

**Format trap to remember**:
`shopModule:addBuyableItem(names, itemid, cost, itemSubType, realName)`
— the 4-arg shorthand `(names, id, price, name)` makes `itemSubType`
the name string. `addBuyableItem` then defaults `realName` to
`ItemType:getName()` which returns "" for items only in `items.otb`
(no `items.xml` entry), so `shopItems` ends up with `name=""` and the
NPC's "I'm selling X" dialog renders as `, , ,` holes. Always pass
the 5-arg form when migrating, even if subType is meaningless: just
use `1`.

### Rachel cleanup

Of the 14 lines migrated to Rachel, all 14 were post-7.72/8.0 items
the user explicitly didn't want sold (modern potion line, three flask
sizes, Wand of Voodoo, spellwand, talon). Removed the migrated block
entirely. Rachel keeps her original Lua-defined offer (spellbook,
magic lightwand, life/mana fluid + bps, wands, rods, bp_sd, bp_uh)
and sells (vial, all wands and rods).

Verified for the 13 stripped items that they have no monster drops,
so removing them from Rachel removes them from the server entirely.
Talon (2151) was the only would-be-removed item with monster loot,
and Voodoo (8922) is sold by Haroun/Romir/Siflind, so neither is
actually gone — left as-is in their other sources.

### Rune charges sync across the 3 sources

User-defined rune charge table:

```
Animate Dead          1 -> 2
Envenom               5 -> 3
Explosion             6 -> 3
Great Fireball        4 -> 2
Heavy Magic Missile  10 -> 5
Magic Wall            3 -> 4
Soulfire              5 -> 2
```

Updated three sources together so they don't drift:
1) `data/items/items.xml` `<attribute key="charges">` — drives
   `Item::getStackMax()` (the per-rune stack cap from Day-13).
2) `data/spells/spells.xml` `<rune charges="N">` for spell info display.
3) `data/spells/scripts/conjuring/*.lua` — the count argument of
   `creature:conjureItem(reagent, conjureId, count)`.

Frost Magic Missile (`adori glaci`) was in the user's reference list
but has no `<instant>/<rune>/script` in this server's spells.xml — left
out of the sync.

### `config.lua` rate edits (gitignored, per-instance)

- `rateExp = 1`, `rateSkill = 1`, `rateLoot = 1`, `rateMagic = 1`
- `experienceStages = { {minlevel = 1, multiplier = 1} }` (collapsed
  the 5-stage Realera staircase to a single 1x band so the
  `rateExp` number alone controls XP)
- `maxMessageBuffer = 4 -> 8`

`config.lua` is gitignored. Re-apply per instance.

### GM bypass on six quest-gated NPCs

`Alesar / Hairycles / Haroun / Nah'Bob / Rashid / Yaman` each have a
`local function onTradeRequest(cid)` callback (registered via
`CALLBACK_ONTRADEREQUEST`) that returns false unless the player has a
specific quest storage value. ADM Lemos can't open the trade window
without doing the quest. Patched the callback to short-circuit on GM
access:

```lua
local _gmPlayer = Player(cid)
if _gmPlayer and _gmPlayer:getGroup() and _gmPlayer:getGroup():getAccess() then
    return true
end
-- existing storage check stays unchanged below
```

**Pitfall** — first patch attempt used Python's `re.sub` with
`'\\1...'` as a regular triple-quoted string. `\\1` parsed by Python
becomes `\1` which is the literal byte `0x01` — NOT the regex group
backreference. Replacement scrubbed the `local function
onTradeRequest(cid)` line and inserted a control character, breaking
the entire script load. NPCs went silent (no greet, no anything)
until git-checkout + re-patch with `r'\1...'` (raw string).

### 4 spawnless NPCs moved to `data/npc/deadfiles/` (3 ended up there)

- `Jessica1` — duplicate of Jessica, no spawn entry
- `Alesar1` — duplicate of Alesar, no spawn
- `Captain HabaOpenSea` — no spawn
- `Nah'bob` — moved here briefly, then **restored** (see below)

The Nah'bob move was a mistake. My Python spawn check used a
case-sensitive grep for `name="Nah'bob"` (lowercase b) which missed
the actual spawn entries that use `name="Nah'Bob"` (capital B).
Server boot started yelling
`[Error - Npc::loadFromXml] Failed to load data/npc/Nah'Bob.xml`
on the spawner. Moved the XML back to `data/npc/Nah'Bob.xml`. Lesson:
**spawn name lookups must be case-insensitive** — Tibia map names
have inconsistent casing (`Nah'Bob` vs `Mr. West` vs `Siflind` typo
for `Silfind`).

### NPC walkaway "Good bye, -1." — Lua scope bug fix

User report: Tothdral and other NPCs greeted with the player's name
but walkaway messages showed `Good bye, -1.`. Bug at
`data/npc/lib/npcsystem/npchandler.lua` line 494:

```lua
local player = Player(cid)
if player then
    local playerName = player:getName()
    -- ...
else
    playerName = -1
end

local parseInfo = { [TAG_PLAYERNAME] = playerName }
```

`local playerName = player:getName()` is declared INSIDE the `if`
block, so its scope ends at the matching `end`. The `parseInfo` line
references a GLOBAL `playerName` that's only set in the `else`
branch (-1) or by some prior unrelated NPC's invocation. So the
`else` value -1 leaks across NPC interactions for any subsequent
walkaway message. Fixed by declaring `local playerName = -1` above
the if/else:

```lua
local playerName = -1
if player then
    local n = player:getName()
    if n then playerName = n end
end
local parseInfo = { [TAG_PLAYERNAME] = playerName }
```

This file is shared by all NPCs, so the fix is global.

### Malunga converted to Sorcerer Guild Leader (spell teacher)

The user noticed Malunga's trade window had 38 quest items, **0 of
them dropped from any monster** in this server, all 38 had
`clientId=0` in items.otb (no sprite). Pure dead inventory — players
visiting her saw an empty/broken trade. Converted her into a
sorcerer-only spell teacher (Liberty Bay):

- Stripped `module_shop=1` and the `shop_sellable` list from
  `data/npc/Malunga.xml`.
- Rewrote `data/npc/scripts/Malunga.lua` Gregor-style with a `teach`
  helper that wires `keywordHandler:addKeyword({name})` to
  `StdModule.say` ("Would you like to learn X for N gold?") plus
  `yes`/`no` children. `yes` calls `StdModule.learnSpell` with
  `vocation = 1` (sorcerer; master sorcerer is implicit via vocation
  inheritance).
- Hooked all 46 sorcerer-only `<instant>` spells from `spells.xml`
  with Cipsoft 8.0 reference prices (Light free, Find Person 80,
  Light Healing 170, Magic Shield 450, Great Fireball 1200, Magic
  Wall 1900, Sudden Death 3000, Ultimate Explosion 5000).

**Trap**: first version used the spell incantation (`exura vita`,
`adori flam`) as the keyword, but players type the spell NAME
(`ultimate healing`, `fireball`). Fixed by using
`string.lower(name)` as the primary keyword and adding the
incantation as an `addAliasKeyword` so both forms work.

### Bulk-remove sprite-less items from 47 NPC shops

User asked to clean every NPC's inventory of items that don't render
in 8.0. Heuristic: an item is sprite-less if its `items.otb` clientId
is `0` AND it has no `<item>` entry in `items.xml`. Walked all NPC
Lua scripts (resolving `Cf*` aliases) and XML `shop_buyable` /
`shop_sellable` / `shop_buyable_containers` parameters; dropped any
matching line/entry. Total: 4 Lua lines + 296 XML entries removed
across 47 NPCs.

Heaviest casualties:
- `Rashid` -79 (the wandering trader's entire post-8.0 buyback list)
- `Tothdral` -12, `Topsy` -12, `Siflind` -17, `Romir` -14
- 9 furniture sellers (Eddy/Hofech/Janz/Nydala/Ukea/Vera/Yoem/Peggy/
  Gamon) -6 to -7 each (8.5+ bed kits, chimney, trophy stand)
- 5 gem sellers (Briasol/Chantalle/hanna/Tezila/Jessica) -8 each
- Cedrik / Robert / Dario - special arrows + 8.5 bolts

After this pass, NPC trade windows render cleanly — every item shown
has a real client sprite. Gameplay impact: players can no longer farm
post-8.0 loot to vendor at Rashid (he was buying 79 items that don't
exist in the world anyway, since 0 monsters dropped them — net
neutral).

### Day-14 file index

Server (this repo):
- `data/talkactions/talkactions.xml` — register `/reload`
- `data/lib/compat/compat.lua` — `logCommand` stub
- `data/actions/scripts/switch/rook/katana door.lua` — lever
  simplified
- `data/npc/lib/npcsystem/modules.lua` — drop L>=50 gate
- `data/npc/lib/npcsystem/npchandler.lua` — walkaway -1 fix
- `data/npc/Urkalio.xml` + `data/npc/Hofech.xml` — module_shop=1
- 12 consolidated NPCs (XML + Lua pairs)
- `data/npc/scripts/Rachel.lua` — migrated block stripped
- `data/npc/Malunga.xml` + `data/npc/scripts/Malunga.lua` — sorcerer
  spell teacher
- `data/items/items.xml`, `data/spells/spells.xml`,
  `data/spells/scripts/conjuring/*.lua` — rune charges sync
- 6 NPC Lua scripts — GM bypass (Alesar / Hairycles / Haroun /
  Nah'Bob / Rashid / Yaman)
- 4 NPCs moved to `data/npc/deadfiles/` (Jessica1, Alesar1,
  Captain HabaOpenSea, [Nah'Bob restored])
- 47 NPC shops cleaned (XML and/or Lua)

`config.lua` (gitignored, NOT committed):
- `rateExp/Skill/Loot/Magic = 1`, single-band experienceStages,
  maxMessageBuffer = 8

### Open thread — vocation spell teachers

Server has `needlearn="0"` on 73 spells and `needlearn="1"` on 40
(default = "0", auto-learn). User wants every spell to require
NPC-buy (Cipsoft 8.0 model). Pending tasks for next session:
1) Flip every `needlearn` to `1` (or set the default in spells.xml
   parser). Need to verify which spells should remain auto-learned
   (probably none for vocation spells; some script-only utility
   spells maybe).
2) Pick canonical 8.0 NPC teachers for each vocation:
   - **Sorcerer** — `Malunga` already setup (Day-14). Add `Lea`
     (Thais) and `Muriel` (Thais) for redundancy.
   - **Druid** — convert `Hjaern` (Carlin) and `Padreia` (Carlin),
     `Maealil` (Ab'Dendriel), `Chondur` (Liberty Bay).
   - **Paladin** — convert `Elane` (Ab'Dendriel) and `Razan` (Edron).
     Both currently exist as shop/addon NPCs; replace inventory.
   - **Knight** — `Gregor` (Ab'Dendriel) already a teacher; add
     `Ulrik` (Kazordoon) and `Niccolai` (Thais — needs creation).
3) Use the same `teach(name, words, price, level)` helper pattern
   from Malunga, customize per vocation. Spell prices from Tibia
   wiki 8.0 reference.

---

## 13. Day-15 — Spellbook lib + addon dialog purge

### Big picture

Two intertwined cleanups happened in one session:

1. **Spell teacher network**: 29 NPCs across the 4 vocations now sell
   every spell of their vocation (Cipsoft 8.0 prices, level gates),
   driven by a shared library (`data/npc/lib/spellbook.lua`). All 117
   instant spells in `data/spells/spells.xml` were flipped to
   `needlearn="1"` so they MUST be bought from an NPC.
2. **Addon/outfit dialog purge**: 37 NPCs that offered Tibia 8.6+
   addon quests had that dialog stripped — Realera doesn't grant
   custom outfits or addons; the player picks any outfit/addon on
   character creation. Non-addon dialog (other quests, shops, voice,
   chat keywords) was preserved on each NPC.

Plus: Cassino moved to deadfiles (gambling NPC, not used).

### Spellbook library — `data/npc/lib/spellbook.lua`

New file. Single shared catalog of every learnable spell per vocation
with Cipsoft 8.0 reference prices. Each NPC who teaches spells just
calls:

```lua
Spellbook.teach(npcHandler, keywordHandler, vocId, Spellbook.<voc>)
```

Vocation IDs: `1=sorc, 2=druid, 3=pal, 4=knight`. Promoted IDs (5-8)
inherit automatically via TFS `learnSpell`.

Catalog format per entry: `{name, words, price, level}` — e.g.
`{'Fireball', 'adori flam', 1200, 27}`. Prices and levels match the
8.0 wiki reference. The catalog is sorted by name length DESC before
keyword registration so longer names register first (otherwise
`great fireball` would substring-match `fireball`).

`Spellbook.teach` registers, per spell:
- A keyword node on the spell name (`fireball`)
- An alias on the incantation (`adori flam`) when it differs
- `yes` / `no` child keywords for the buy flow

Plus a single generic `spells` help keyword per NPC (vocation-aware
text with 4 example spell names that render as clickable
`{spell name}` links). For hybrid teachers (Eroth, Rahkem teach
sorc + druid via two `Spellbook.teach` calls), the help text
auto-extends to "all sorcerer and druid spells".

The lib is auto-loaded from `data/npc/lib/npc.lua`:
```lua
dofile('data/npc/lib/spellbook.lua')
```

**To revert the whole spell teacher network**: delete
`data/npc/lib/spellbook.lua` + the dofile line, then `git checkout`
each of the 29 spell teacher scripts back to before this session.
Spells without `needlearn="1"` would also need restoring in
`spells.xml` (33 lines flipped).

### Spell teacher NPCs (29) — explicit greet + Spellbook.teach

Each spell teacher's greet is now explicit so the player knows they
teach spells without having to guess the keyword:

> *"Greetings, |PLAYERNAME|. I teach &lt;voc&gt; {spells}. What would you
> like to learn?"*

For 5 NPCs that ALSO have a shop (XML `module_shop="1"`), the greet
mentions both:

> *"...I teach &lt;voc&gt; {spells} and {trade} a few items..."*

For NPCs with a `greetCallback` (dynamic per-player greet — Duria,
Etzel, Marvik, Muriel, Umar), the dynamic message itself was
modified to include the spell mention.

| NPC | Vocation | City | Has shop? |
|---|---|---|---|
| Asrak | knight | ? | no |
| Chatterbone | sorcerer | ? | no |
| Chondur | druid | Liberty Bay | YES |
| Duria | knight | Kazordoon | no |
| Elane | paladin | Ab'Dendriel | YES |
| Eroth | sorc + druid | hybrid | no |
| Etzel | sorcerer | Kazordoon | no |
| Gregor | knight | Ab'Dendriel | no |
| Gundralph | druid | ? | no |
| Hagor | paladin | ? | no |
| Hjaern | druid | Nibelor | no |
| Lea | sorcerer | Carlin | no |
| Legola | paladin | Carlin | (empty) |
| Lungelen | sorcerer | ? | no |
| Maealil | druid | Ab'Dendriel | no |
| Malunga | sorcerer | Liberty Bay | no |
| Marvik | druid | Thais | no |
| Muriel | sorcerer | Thais | no |
| Padreia | druid | Carlin | no |
| Rahkem | sorc + druid | Darashia | no |
| Razan | paladin | Edron | no |
| Shalmar | druid | ? | no |
| Smiley | druid | ? | no |
| Thorwulf | knight | ? | no |
| Trisha | knight | Carlin | no |
| Umar | paladin | (Marid djinn) | no |
| Ulrik | knight | Kazordoon | YES |
| Ustan | druid | Port Hope | YES |
| Sam | knight | Thais | YES (shop only — see below) |

**Reverted from spell teaching mid-session** — these were given
`Spellbook.teach` by my prior automation but in real Cipsoft 8.0 they
are NOT teachers (just shop NPCs); user explicitly asked to revert:
- **Gorn** (Thais general goods) — `Spellbook.teach` removed; he
  remains a regular merchant. His own dialog already said
  `"Magic? Ask a sorcerer or druid about that."`.
- **Sam** (Thais blacksmith) — same treatment. Greet reverted to
  *"Welcome to my shop, adventurer |PLAYERNAME|! I {trade} with
  weapons and armor."*. Old Backpack quest + 2000 steel shields
  Foolish Quest preserved.

### Addon/outfit dialog purge (37 NPCs)

**Policy**: Realera's character creation lets you pick any outfit
and any addon directly. So every Tibia 8.6+ NPC chain that gave
players outfits/addons is dead code in this server. We removed only
the addon-related branches; everything else (other quests, shop
trade, chat, voice) is preserved.

**Removal patterns applied**:
- `addOutfit(N)` / `addOutfitAddon(N, X)` calls — removed.
- Storage variables tied to addon progression
  (`Storage.OutfitQuest.*`, `foriental`, `fmage`, etc.) — removed.
- Helper functions named `*First`, `*Second`, `OrientalFirst`,
  `BeggarFirst`, etc. — removed.
- Keywords `addon`, `outfit`, and addon-specific item names
  (`shoulder spike`, `scimitar`, `hooded cloak`, `dress`, `staff`,
  `hat`, etc.) — removed.
- `creatureSayCallback` blocks that only handled addon flow —
  removed; `setCallback(CALLBACK_MESSAGE_DEFAULT, …)` registration
  removed when callback was empty.
- Multi-quest NPCs (Avar Tar, Lugri, The Queen of the Banshees,
  etc.): only the addon branch was excised; the other branches
  (cookie quest, KitNo task, seventh seal quest, etc.) stay.

**Effect classes** (so you know what to expect from each NPC):

| Class | Result | NPCs |
|---|---|---|
| Pure addon NPC | Reduced to greet-only stub | Atrad, Myra, Ajax, Bron, Erayo, Morgan |
| Addon + spell teacher | spellbook preserved, addon stripped | Razan, Trisha, Elane, Gregor, Hjaern, Ustan |
| Addon + shop/quest hub | shop & non-addon dialog preserved | Habdel, Cornelia, Lubo, Hanna, Norma, Sandra, Tom, Sam, King Tibianus, Queen Eloise, Emperor Kruzak, Bozo, Amber |
| Mixed quest NPC | only addon branch removed | Ariella, Avar Tar, Hjaern, Lugri, The Queen of the Banshees, Simon the Beggar, Irmana, Miraia, Lynda, Chondur |
| One-line keyword strip | only `outfit` keyword removed | Gelagos, Vescu (kept troll flavor) |

**Full list of 37 NPCs touched**: Atrad, Habdel, Myra, Razan, Trisha,
Ajax, Amber, Ariella, Avar Tar, Bozo, Bron, Chondur, Cornelia, Elane,
Emperor Kruzak, Erayo, Gregor, Hanna, Hjaern, Irmana, King Tibianus,
Lubo, Lugri, Lynda, Miraia, Morgan, Norma, Queen Eloise, Sam, Sandra,
Simon the Beggar, The Queen Of The Banshees, Tom, Ustan, Zoltan,
Gelagos, Vescu.

**To revert addon stripping for any single NPC**:
```
git checkout <commit-before-this-session> -- data/npc/scripts/<Name>.lua
```
Each NPC was a separate edit so reverting one doesn't affect others.

### Cassino moved to deadfiles

`Cassino.xml` and `cassino.lua` moved to `data/npc/deadfiles/` and
`data/npc/deadfiles/scripts/` respectively. He was a gambling/casino
NPC; only spawn reference was already in `bkp/global-spawn_bkp.xml`
(historical backup), nothing in the live spawn. Revert: just `git mv`
both files back to the original locations.

### NPC compat shim — `npchandler:say` nil-focus tolerance

(Kept from previous Realera session, mentioned here for context: many
spell teacher NPCs and addon NPCs called `npcHandler:say('text')`
without passing a focus. Lua 5.5 raises 'table index is nil' on the
resulting `self.eventSay[nil]`. The lib falls back to the most recent
focus, then to ambient `selfSay`. See `data/npc/lib/npcsystem/`.)

### Helper scripts produced this session

- `move_unused_npcs.py` — sweeps NPC XMLs in `data/npc/` whose name
  doesn't appear in `data/world/global-spawn.xml`; moves them and
  their matching script into `data/npc/deadfiles/`. Untracked
  before — committing now. Re-runnable.
- `sync_and_clean_npcs.py` — earlier 3-phase NPC cleanup helper.
  Reference / re-runnable.

Both scripts are idempotent — they can be re-run safely after future
spawn changes.

### Day-15 file index

```
data/npc/lib/spellbook.lua                NEW — shared catalog + Spellbook.teach
data/npc/lib/npc.lua                      MODIFIED — dofile spellbook.lua
data/spells/spells.xml                    MODIFIED — needlearn=1 across all instants
data/npc/scripts/<29 spell teachers>.lua  MODIFIED — explicit greet + Spellbook.teach
data/npc/scripts/<37 addon-strip NPCs>.lua MODIFIED — addon dialog removed
data/npc/scripts/Gorn.lua                 REVERTED — Spellbook.teach removed
data/npc/scripts/Sam.lua                  REVERTED — Spellbook.teach removed (kept blacksmith)
data/npc/Cassino.xml                      MOVED → deadfiles/
data/npc/scripts/cassino.lua              MOVED → deadfiles/scripts/
data/npc/deadfiles/                       NEW DIR (1000+ NPCs) — accumulated from earlier
                                          unused-NPC sweeps; committing now.
data/world/bkp/                           NEW DIR — backups of original world.otbm/spawns
move_unused_npcs.py                       NEW — unused-NPC sweep helper
sync_and_clean_npcs.py                    NEW — 3-phase NPC cleanup helper
```

### Things still NOT done (carry forward)

1. **Premium gating audit** — Server policy: every NPC of a vocation
   teaches the FULL spell list. There are no premium-only spells;
   free and premium accounts buy from the same NPCs at the same
   prices. (Premium only gates city access via captains —
   `data/lib/miscellaneous/free_cities.lua`.) `Spellbook.teach`
   passes `premium = false` always. If we ever want premium-locked
   spells, change the per-spell call site.
2. **Niccolai / Thais knight teacher** — section 12's open thread
   suggested creating a Thais knight teacher; not done. Gregor in
   Ab'Dendriel + Sam in Thais (now reverted to non-teacher) means
   Thais has no knight teacher locally. Not blocking — Gregor is one
   boat ride away.
3. **Test pass on the 28 spell teachers** — User flagged that they
   should sit down and verify each NPC actually responds to "hi" /
   "spells" / spell name / "yes". Sample success: Lea answers all 4
   correctly after this session's fixes.

---

## 14. Day-15.5 — `queryDestination` engine bugs and Lua workarounds

While testing as GM, the user surfaced three bugs that all trace back
to the same routine: `Player::queryDestination` in `src/player.cpp`.
They all manifest in different ways but the algorithm has two
distinct flaws:

### Bug A — autoStack merge with maxed-out target replaces the target

`player.cpp:2727` (and the parallel container path at 2784):
```cpp
if (inventoryItem->equals(item) && inventoryItem->getItemCount() < 100) {
    index = slotIndex;
    *destItem = inventoryItem;
    return this;
}
```

The merge target is selected if `count < 100`. But for stackable
runes the actual cap is `getStackMax()` which equals `it.charges`
from items.xml (e.g., 4 for fireball, 5 for SD). A maxed-out
4-charge fireball (4/4) is still `< 100`, so it gets returned as a
merge target.

`internalAddItem` then runs `n = min(stackMax - itemCount, m) = 0`,
fails to merge any charges, falls into the `count == itemCount`
branch and calls `toCylinder->addThing(index, item)`. For
single-item slots like hands `Player::addThing` just overwrites
`inventory[index]` — the maxed rune in hand is **replaced by a
1-charge new rune**, losing the original.

**Symptoms it caused**:
- `/i fireball rune` while a 4/4 fireball is in hand → the hand
  rune resets to 1 charge (the old one is lost).
- `/i sudden death rune` repeatedly with a full main BP → SDs
  pile up overflowing through inner BP slots, "phantom" slots
  appear past index 20 because nested containers get pushed
  around.
- Casting `adori flam` with a blank rune in an inner BP → the
  newly-conjured fireball gets routed into hand (or onto an
  existing rune in hand), each subsequent cast replaces the hand
  rune so the player ends up with one rune total no matter how
  many blanks they consume.

### Bug B — BFS container traversal prefers shallow siblings over deep children

`player.cpp:2747-2802` builds a queue of every container reachable
from the player's slots, processes it FIFO. When a container A is
processed and we descend into its child container B, B is pushed to
the END of the queue rather than processed next. So if there is
another sibling container C also in the slot list, C is tried
before B.

**Symptoms**:
- Player has full main BP with an inner BP inside (with space).
  Buys 3 parcels at NPC. The 1st and 2nd land in hands, the 3rd
  has nowhere to go — engine routes it into one of the hand
  parcels (an empty sibling container) instead of descending into
  the inner BP that has free slots.
- Player has 10k crystal coins in ammo slot, full main BP +
  inner-BP-with-space, buys 3 parcels. The displaced coins flow
  into the new parcel that took the ammo slot rather than into
  the inner BP.

The intuitive behaviour is DFS: when a sibling is full, descend
into its children before moving to the next sibling.

### Why we did NOT patch the engine yet

Both bugs are 4-6 line patches in one source file, but
`queryDestination` runs on every item placement in the game
(loot drops, NPC trade, manual moves, addItem calls, etc.). A
behavioural change there has wide blast radius — could shift loot
distribution, trade window UX, container behaviour for monsters
that pick up items, etc.

The user wants to ship gameplay fixes first and keep the engine
binary unchanged for now (no rebuild required). So we mitigated at
the Lua level for the two highest-impact paths.

### Fix 1 — `data/talkactions/scripts/create_item.lua` (`/i` GM command)

Detects rune ItemType and takes a separate code path:

```lua
if itemType:isRune() then
    local fullCharges = math.max(1, itemType:getCharges())
    for i = 1, runesToCreate do
        local item = Game.createItem(itemType:getId(), fullCharges)
        local ret = player:addItemEx(item, false, INDEX_WHEREEVER, FLAG_IGNOREAUTOSTACK)
        if ret ~= RETURNVALUE_NOERROR then break end
    end
end
```

Key choices:
- `Game.createItem(id, fullCharges)` — each `/i fireball rune`
  produces a fresh 4/4 rune (not a 1-charge stacker), regardless
  of how many casts came before.
- `addItemEx(item, false, INDEX_WHEREEVER, FLAG_IGNOREAUTOSTACK)`
  — `false` is `canDropOnMap=false` so failures don't silently
  drop on the floor, and the flag tells `queryDestination` to
  skip the bugged autoStack branch entirely. Each rune lands in
  a real free slot or fails cleanly with "Not enough room.".
- Non-rune behaviour unchanged (gold, fluids, regular items keep
  the old `player:addItem` path).

### Fix 2 — `data/spells/lib/spells.lua` (`Player:conjureItem`)

The vanilla impl was `removeItem(blank) + addItem(rune)`. Both
calls funnel through the buggy `queryDestination`. The reliable
fix is what original Cipsoft did: transform the blank rune in
place. Same cylinder, same slot, just new id and charges. No
queryDestination, no addItem, no map drop.

```lua
local reagent = self:getItemById(reagentId, true)  -- deep search
if not reagent then return ... end
reagent:transform(conjureId, conjureCount)
```

`Item:transform` calls `Game::transformItem` which for items of
the same `type` (rune→rune) updates id and subtype atomically in
the same cylinder slot — exactly the behaviour spells should
have.

After this fix:
- Cast `adori flam` with blank in inner BP → fireball appears in
  inner BP at the blank's old slot. Hand untouched.
- Cast again with another blank → second fireball appears in inner
  BP. Player accumulates runes one per cast as expected.

### What's still NOT fixed

The parcel/crystal-coin displacement (Bug B) still affects normal
gameplay (NPC trade, container-to-container moves). The fix
requires the engine DFS patch:

```cpp
// in queryDestination, when pushing subContainer to the queue:
containers.insert(containers.begin() + i + 1, subContainer);  // DFS
// instead of:
containers.push_back(subContainer);  // BFS (current)
```

Plus the autoStack threshold should compare against `getStackMax`
not `100`:

```cpp
if (inventoryItem->equals(item) && inventoryItem->getItemCount() < inventoryItem->getStackMax()) {
```

Both at lines 2727 and 2784.

Two patches, ~3 lines total, same file (`src/player.cpp`).
Requires `cmake --build build --target tfs` rebuild. Open thread
for next session if the parcel issue becomes a real player
complaint.
