# Voice of Stone – Głos Kamienia

Dark-fantasy inscription system. Players carve messages on Stone Tablets,
bless others' writing, and absorb esoteric knowledge from blood-written texts.

## Hooks to wire

| Hook | Script |
|------|--------|
| Module OnLoad | `sys_on_load` |
| Module OnClientEnter | `sys_on_enter` |
| Tablet placeable OnUsed | `test_ins` |

## Tablet placeable setup

1. Place any placeable in the toolset.
2. Set its **Tag** to a unique string, e.g. `ins_tablet_crypt`.
3. Set its **OnUsed** script to `test_ins`.
4. Repeat for each tablet location; inscriptions are isolated per-tag.

The `sys_on_enter` script auto-detects placeables tagged `ins_tablet` or
`INS_TABLET` (first match in area). Give them a more specific tag
(e.g. `ins_tablet_market`) and the system will still work because
`InsOpenWindow` always reads the tablet's actual tag at call time.

## NWNX dependencies

None. Pure NWN:EE NWScript and NUI.
Requires NWN:EE build **8193+** for `TagEffect` / `GetEffectTag`.

## SQL

Campaign database: `stone_inscriptions`
Tables: `inscriptions`, `ins_votes`, `ins_reads`

Created automatically on first module load via `InsCreateTables()`.
Migrations are idempotent (`CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`).

## Expiry

* Normal inscription: 72 hours.
* Blood inscription: 216 hours (3×).
* 10+ blessings: permanent (`expires_at = 0`).
* Each blessing extends life by +1 hour (and grants permanence at threshold).
* `InsExpireOld()` is called on module load and every client enter.

## Blood inscription bonus

Reading a blood inscription you did not write grants **+1 Lore (Wiedza)**
for 1 hour (supernatural, tagged `INS_BLOOD_LORE`).
Stacks up to **+3**; the stack cap is defined in `INS_BLOOD_BONUS_MAX`.

## Deliberately omitted

* Inscription images / icons in HAK (purely text-based, no asset dependencies).
* Per-area listing (tablets are tag-namespaced, not area-namespaced).
* Inscription deletion by author (intended to feel permanent and weighty).
* Server-side rate limiting per player (one inscription per session would need
  a heartbeat check; left for server owner to add via `InsGetCount` filter).
