# Demonic Pacts — Integration Guide

## Required Module Event Hooks

| Event | Script |
|-------|--------|
| OnModuleLoad | `sys_on_load.nss` |
| OnClientEnter | `sys_on_enter.nss` |
| OnHeartbeat | `sys_on_heartbeat.nss` |

If your module already has scripts on these events, call the Demonic Pacts
functions from within them:

```nss
// in your existing OnModuleLoad:
#include "sql_pact"
// ...
PactCreateTables();

// in your existing OnClientEnter:
#include "lib_pact"
// ...
if(GetIsPC(GetEnteringObject()))
    DelayCommand(3.0, PactCheckAndApply(GetEnteringObject()));

// in your existing OnHeartbeat (fires every 6 s):
#include "lib_pact"
// ...
object oPC = GetFirstPC();
while(GetIsObjectValid(oPC)) { PactCollectToll(oPC); oPC = GetNextPC(); }
```

## Opening the Window

Place a custom placeable in the world (Altar of Covenants) and assign
`test_pact.nss` to its **OnUsed** event.

## NWNX Dependencies

None. Pure NWN EE (build 8193.24+) is required for:
- `EffectSetTag` / `GetEffectTag`
- `SqlPrepareQueryCampaign` / `SqlStep`

## Campaign Database

`pact.sqlite3` is created automatically on module load in the campaign
database directory. Table: `pact_active` (one row per signed pact).

## Adjusting the Toll Interval

Change `PACT_TOLL_INTERVAL` in `lib_pact_def.nss` (default: 7200 seconds).
Set to 60 or 120 during testing.

## Adjusting Break Penalties

`PACT_BREAK_HP_COST` — instant HP damage on voluntary pact break (default 20).
`PACT_BREAK_CURSE_SECS` — duration of the stat-penalty curse (default 1800 s).
