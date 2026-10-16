# Szynkarz — Integration Guide

## What it does

Tavern brewing system with 8 dark-fantasy drink recipes. Players collect ingredients,
brew drinks at a Brewing Kit placeable, and store them in a per-character "cellar" (SQL).
Drinking applies recipe-specific effects and adds intoxication points; intox decays
over time via heartbeat and crosses threshold bands that toggle stacking stat effects.

## Hooks to connect

| Event | Script to call / chain |
|---|---|
| Module OnModuleLoad | `sys_on_load.nss` (or call `SynCreateTables()` from your existing load script) |
| Module OnClientEnter | `sys_on_enter.nss` (or call `SynOnClientEnter(GetEnteringObject())`) |
| Module OnHeartbeat | `sys_module_hb.nss` (or call the inner loop from your existing HB script) |

If you already have scripts for these events, add `#include "lib_syn"` and call the
corresponding function instead of replacing your script.

## Brewing Kit placeable

1. Create a placeable in the toolset (any model — a barrel, cask, or alembic works well).
2. Set its **OnUsed** script to `test_syn.nss`.
3. The window opens automatically for any non-DM PC who activates it.

## Ingredient items

Each ingredient is identified by item **tag** (not resref). Create items in your HAK
or palette with the following tags, then distribute them as loot or merchant stock:

| Tag | Polish name |
|---|---|
| `syn_hop` | Chmiel |
| `syn_barley` | Słód Jęczmienny |
| `syn_midnight` | Korzeń Północy |
| `syn_honey` | Miód Dzikich Pszczół |
| `syn_wormwood` | Piołun |
| `syn_bone_dust` | Proch Kostny |
| `syn_grapes` | Czarne Winogrona |
| `syn_blood` | Świeża Krew |
| `syn_ghost_ess` | Esencja Zjaw |
| `syn_moonwater` | Woda Księżycowa |
| `syn_iron_fil` | Opiłki Żelaza |
| `syn_cinder` | Korzeń Żużlowy |
| `syn_spider_ven` | Jad Pająka |
| `syn_arcane_cry` | Kryształ Arkanistyczny |

Items can stack freely; the brewing logic drains the required quantity from whatever
stacks are present.

## NWNX dependencies

None. All persistence uses `SqlPrepareQueryCampaign("szynkarz", ...)` (vanilla EE
campaign DB). No NWNX plugins required.

## Testing

Set `SetLocalInt(GetModule(), "SYN_DEBUG", 1)` in OnModuleLoad to enable a debug flag.
When the flag is active, activating the Brewing Kit placeable prints the required
ingredient tags to the player's chat log so you can create matching items manually.

## What was intentionally omitted

- **Addiction mechanic** — easily added as a fourth SQL column tracking drink frequency
- **Brewing mini-game** — kept as a single button; timing/skill-check minigame could extend the brew tab
- **Drink stacking / limits** — currently a player can drink indefinitely; a cap at e.g. 3 drinks before forced rest would add balance
- **DM panel** — no DM-facing UI for inspecting or resetting player intox
- **Item resrefs for brewed drinks** — drinks exist only in SQL, not as physical item objects; add `CreateItemOnObject` if physical hand-off between players is needed
