# Codex Bestiarum — Integration Guide

## Overview

The Bestiary module lets players study creatures they encounter, accumulating
knowledge per racial type. At three knowledge tiers (5 / 20 / 75 studies) lore
entries unlock, and at tiers 2–3 passive combat bonuses (+AB, +damage) are
applied as permanent SupernaturalEffects and restored on every login.

## Quick start (fresh module)

1. Add all files from `scripts/` into your module's HAK or script folder.
2. Wire up the four module events below.
3. Place the `test_bst` script on any placeable (a tome, lectern, or notice
   board) as its **OnUsed** event — this opens the codex UI for the using PC.

## Module event hooks

| Module Event | Script to call |
|---|---|
| **OnModuleLoad** | `sys_on_load` |
| **OnClientEnter** | `sys_on_enter` |
| **OnPlayerTarget** | `sys_on_target` |

If your module already has scripts for these events, **do not replace them**.
Instead, call the Bestiary function from within your existing scripts:

```nwscript
// Inside your existing OnModuleLoad:
#include "sql_bst"
// ...
BstCreateTables();

// Inside your existing OnClientEnter:
#include "lib_bst"
// ...
if(GetIsPC(oPC) && !GetIsDM(oPC)) BstApplyBonuses(oPC);

// Inside your existing OnPlayerTarget:
#include "lib_bst"
// ...
BstHandleTarget(GetLastPlayerToDoTarget());
```

## Optional: automatic kill registration (no NWNX)

The study mechanic is **player-initiated** (click a creature in the codex).
If you prefer kills to register automatically when a creature dies, add this
to whichever script runs as the creature's **OnDeath**:

```nwscript
#include "lib_bst"

// Inside OnDeath script body:
object oVictim = OBJECT_SELF;
object oKiller = GetLastKiller();

// Climb to the PC master (handles henchmen / summoned creatures as killers)
if(GetIsObjectValid(GetMaster(oKiller))) oKiller = GetMaster(oKiller);
if(!GetIsPC(oKiller) || GetIsDM(oKiller)) return;

int nType    = GetRacialType(oVictim);
int nRaceIdx = BstTypeToRaceIndex(nType);
if(nRaceIdx < 0) return;

// Only register if this creature hasn't been studied manually by this PC
if(!GetLocalInt(oVictim, BST_LVAR_STUDIED))
{
    SetLocalInt(oVictim, BST_LVAR_STUDIED, 1);
    int nOldKills = BstGetKills(oKiller, nRaceIdx);
    BstAddStudy(oKiller, nRaceIdx);
    if(BstGetTier(nOldKills + 1) > BstGetTier(nOldKills))
        BstApplyBonuses(oKiller);
}
```

The typical targets for this OnDeath script are:
- `nw_c2_default7` replacement in your HAK (affects all creatures with no
  custom death script)
- Every custom creature blueprint that has its own OnDeath handler

## NWNX-based automatic kill tracking (optional)

If NWNX_Events is available, you can subscribe in `sys_on_load`:

```nwscript
#include "nwnx_events"
// At the end of BstCreateTables() or in OnModuleLoad:
NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_KILL_AFTER", "bst_on_nwnx_kill");
```

Then create `bst_on_nwnx_kill.nss`:

```nwscript
#include "lib_bst"
#include "nwnx_events"

void main()
{
    object oKiller = OBJECT_SELF;
    object oVictim = StringToObject(NWNX_Events_GetEventData("TARGET"));
    if(!GetIsPC(oKiller)) return;
    int nIdx = BstTypeToRaceIndex(GetRacialType(oVictim));
    if(nIdx < 0) return;
    int nOld = BstGetKills(oKiller, nIdx);
    BstAddStudy(oKiller, nIdx);
    if(BstGetTier(nOld + 1) > BstGetTier(nOld))
        BstApplyBonuses(oKiller);
}
```

## Dependencies

| Dependency | Required? | Notes |
|---|---|---|
| NWN:EE (1.87+) | **Yes** | `TagEffect` / `GetEffectTag` API used for effect management |
| SQLite campaign DB | **Yes** | DB name: `"bestiary"` — created automatically |
| NWNX | No | Optional for automatic kill tracking; see above |

## What was intentionally omitted

- **No icon assets** — no custom TGA/DDS files are needed; the codex UI uses
  standard NWN text elements only.
- **No item rewards** — tier-up gives passive effects only; distributing
  physical items on tier-up would require additional item blueprints in the HAK.
- **No cooldown on study mode** — the one-study-per-creature-instance rule
  prevents abuse without needing a timer.
- **No creature sub-type differentiation** — all Undead share one knowledge
  pool; individual species tracking would multiply tables and UI complexity.
