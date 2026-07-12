# Inquisition System — Integration Guide

## What It Does

Tracks heretical acts committed by PCs and maintains a persistent **Inquisition Rating**
(0–100) per character. As the rating grows the PC crosses four tiers — Under Suspicion,
Accused, Convicted, Condemned — each with escalating mechanical penalties (-Charisma,
-AC, -Saving Throws) and floating-text notifications.

Players can reduce their rating through:
- **Confession** — pay gold to a priest; reduces by 15 points.
- **Public Recantation** — broadcast announcement to the area; reduces by 25 points,
  cooldown of one in-game hour.

DMs have a separate control panel to view all suspects, add charges manually,
and issue pardons.

## Files

| File | Purpose |
|---|---|
| `Scripts/sql_inq.nss` | SQLite schema + all queries |
| `Scripts/lib_inq_def.nss` | Constants, IDs, flavor helpers |
| `Scripts/lib_inq.nss` | Core logic, effect application, NUI layout |
| `Scripts/lib_inq_ev.nss` | NUI event handler (registered via `NuiCreate`) |
| `Scripts/sys_on_load.nss` | Module OnLoad: creates tables |
| `Scripts/sys_on_enter.nss` | ClientEnter: restores effects, upserts PC name |
| `Scripts/test_inq.nss` | OnUsed placeable: opens dossier (PC) / DM panel (DM) |

## Dependencies

- **NWScript + NUI only** — no NWNX required.
- **Campaign DB**: uses `SqlPrepareQueryCampaign("inquisition", ...)`.
  The `inquisition` campaign DB is auto-created by SQLite on first use.

## Hooks to Wire in Toolset

| Event | Script |
|---|---|
| Module → OnModuleLoad | `sys_on_load` |
| Module → OnClientEnter | `sys_on_enter` |

The `lib_inq_ev.nss` script is passed as the 4th argument to `NuiCreate` for
each window — no module-level OnNuiEvent hook needed for routing.

## Adding a Heretical Act Programmatically

```nwscript
#include "lib_inq"

// Called from any spell, item, or area script to flag a PC:
InqAddCharge(oPC, INQ_ACT_FORBIDDEN_MAGIC);   // +12 rating
InqAddCharge(oPC, INQ_ACT_DARK_RITUAL);        // +25 rating
```

Available act IDs and their weights:

| Constant | Weight |
|---|---|
| `INQ_ACT_FORBIDDEN_MAGIC` | +12 |
| `INQ_ACT_BLASPHEMY` | +8 |
| `INQ_ACT_FORBIDDEN_TOME` | +15 |
| `INQ_ACT_DEMON_CONTACT` | +18 |
| `INQ_ACT_UNDEAD_CONSORTING` | +20 |
| `INQ_ACT_DARK_RITUAL` | +25 |

## Test Placeable

Place a placeable with `test_inq` as the **OnUsed** script:
- **PC** clicks it → opens their personal Dossier window.
- **DM** clicks it → opens the DM control panel.
- Set local int `inq_test_act` (0–5) on the PC before clicking to inject a test charge.

## What Was Deliberately Omitted

- **Inquisitor NPC spawning** — the DM panel has a pardon/charge tool but does not
  auto-spawn NPC patrols; that requires campaign-specific creature blueprints.
- **Offline effect persistence** — stat penalties are re-applied on `ClientEnter`;
  they are not stored as item properties and will not persist across reboots for offline PCs.
- **Informant mechanic** — shifting charges to another PC was scoped out to avoid
  potential abuse; could be added in a future revision.
- **Rating decay over time** — no passive decay; intentional so charges feel meaningful.
