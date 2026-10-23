# Combat Stances — Integration Guide

## Hooks

| Module event       | Script to call (or add to existing) |
|--------------------|--------------------------------------|
| OnModuleLoad       | `sys_on_load.nss`                    |
| OnClientEnter      | `sys_on_enter.nss`                   |
| OnClientLeave      | `sys_on_leave.nss`                   |
| Trainer placeable OnUsed | `test_stn.nss`                 |

If these hooks are already occupied by other scripts, merge the single function calls:

```nss
// OnModuleLoad
StnCreateTables();

// OnClientEnter
StnRegisterPlayer(oPC);
StnApplyEffects(oPC, StnGetActiveStance(oPC));
if(StnGetActiveStance(oPC) != STN_STANCE_READY)
    CreateStanceWidget(oPC);

// OnClientLeave
StnRemoveEffects(oPC);
```

## Placement

1. Place any placeable in-world with **OnUsed** set to `test_stn`.
   This serves as the Stance Trainer. Label it „Mistrz postaw" or similar.
2. Players interact with it to open the Stance Book and unlock/adopt stances.

## SQL / Persistence

All data is stored in campaign database **"stances"** (one SQLite file).
No external dependencies (NWNX not required).

## Files added

```
Combat Stances/scripts/lib_stn_def.nss   — constants, bind IDs, forward decls
Combat Stances/scripts/lib_stn.nss       — core logic, UI build/feed
Combat Stances/scripts/lib_stn_ev.nss    — NUI event handler
Combat Stances/scripts/sql_stn.nss       — SQLite schema + queries
Combat Stances/scripts/sys_on_load.nss   — OnModuleLoad: create tables
Combat Stances/scripts/sys_on_enter.nss  — OnClientEnter: register + restore stance
Combat Stances/scripts/sys_on_leave.nss  — OnClientLeave: remove effects
Combat Stances/scripts/test_stn.nss      — Trainer placeable OnUsed
```

## Stances

| ID | Name               | Always free | Effects |
|----|--------------------|-------------|---------|
| 0  | Oczekiwanie        | yes         | None (neutral) |
| 1  | Uderzenie Gwaltowne| yes         | AB +2, AC -2 |
| 2  | Zelazna Obrona     | yes         | AB -2, AC +3, Saves +1 |
| 3  | Szal Krwi          | 500 GP      | Damage +1d6, AC -5, Immunity: fear/charm |
| 4  | Mrok w Oczach      | 400 GP      | Concealment 15%, Move Silently +4, Hide +4 |
| 5  | Pieczen Smierci    | 600 GP      | Regenerate 1/6s, Save vs Death +2, CHA -2 |

## NWN EE features used

- `TagEffect` / `GetEffectTag` for tracking and removing stance effects
- `EffectRegenerate` with tick interval
- `EffectConcealment`
- `NuiList` with `NuiListTemplateCell`
- `NuiSetGroupLayout` is NOT used (single-layout window)
- `SqlPrepareQueryCampaign` with `ON CONFLICT` upsert (requires SQLite 3.24+, available in NWN EE 8193.36.14+)
