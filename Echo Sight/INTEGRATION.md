# Echo Sight — Integration Guide

## Overview

Echo Sight is a psychometric system. Characters can activate special placeable objects
("echo anchors") to witness vision-texts of past events burned into a location.
Absorbed visions are stored in a per-character SQL Codex (NUI window).
Consuming a vision from the Codex grants a permanent stat bonus.

## Hooks to wire up

| Hook | Script | Notes |
|---|---|---|
| Module OnLoad | `sys_on_load` | Creates SQLite tables (`esi_echoes`, `esi_active_bonuses`) |
| Module OnClientEnter | `sys_on_enter` | Re-applies permanent bonuses after relog |
| Placeable OnUsed | `sys_on_use` | Attach to each echo placeable individually |

If your module already has OnLoad/OnClientEnter handlers, add one call each:
```
// in existing OnLoad:
#include "lib_esi_def"
EsiCreateTables();

// in existing OnClientEnter:
#include "lib_esi"
EsiReapplyAllBonuses(GetEnteringObject());
```

## Creating echo placeables

1. Place any placeable in the Toolset (a book, a blood stain, a cracked altar, etc.).
2. Set its **OnUsed** script to `sys_on_use`.
3. In the placeable's Variables tab, set:

| Variable | Type | Description |
|---|---|---|
| `ESI_ECHO_TITLE` | String | Short title shown in the Codex list |
| `ESI_ECHO_TEXT` | String | Full vision text (player-facing, Polish recommended) |
| `ESI_ECHO_CAT` | Int | Category: 0=Murder, 1=Battle, 2=Ritual, 3=Betrayal, 4=Agony |
| `ESI_ECHO_DC` | Int | Spot DC to succeed (0 = always succeeds) |
| `ESI_ECHO_BTYPE` | Int | Bonus type: 0=none, 1=attack, 2=saves, 3=search, 4=temp HP |
| `ESI_ECHO_BVAL` | Int | Bonus magnitude (1–5 recommended; temp HP multiplied by 5) |
| `ESI_ECHO_TRAUMA` | Int | 1 = traumatic — deals 1d4 psychic damage on absorb |
| `ESI_ECHO_FLAVOR` | String | One-line summary shown in the Codex list |

## Opening the Codex from a chat command or menu

Call `EsiOpenCodex(oPC)` from any script where `oPC` is the player character.
Example: add a chat command handler that calls `EsiOpenCodex(GetPCSpeaker())`.

## NWNX dependencies

None. The module uses only the vanilla NWN:EE NUI API and SQLite
(`SqlPrepareQueryCampaign` targeting the `"esi"` campaign database).

## Running the demo

1. Place a placeable with OnUsed set to `test_esi`.
2. Use it 3 times to cycle through 3 different echoes (Murder, Ritual, Battle).
3. Use it a 4th time to open the Codex and see all 3 entries.
4. Select an entry and click "Pochłoń Echo" to consume it for its bonus.

## Files

| File | Purpose |
|---|---|
| `sql_esi.nss` | SQLite schema and all query functions |
| `lib_esi_def.nss` | Constants, bind names, helper functions (category names, bonus application) |
| `lib_esi.nss` | NUI construction (Codex window, Vision window) and gameplay logic |
| `lib_esi_ev.nss` | NUI event handler (button clicks, window close) |
| `sys_on_load.nss` | Module OnLoad: create tables |
| `sys_on_enter.nss` | Module OnClientEnter: reapply bonuses |
| `sys_on_use.nss` | Placeable OnUsed: trigger echo interaction |
| `test_esi.nss` | Demo script cycling through 3 sample echoes |
| `lib_nui.nss` | Shared NUI utilities (copied from existing modules) |
| `lib_nui_utility.nss` | Shared NUI dimension helpers |
