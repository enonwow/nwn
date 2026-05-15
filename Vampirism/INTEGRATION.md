# Vampirism — Integration Guide

## What it does

A persistent vampire-curse system for NWN:EE. Characters infected via a
test placeable (or an attacker with a custom script) accumulate a **blood
level** (0–100) that drains 1 point every 6 seconds. A compact NUI panel
shows the blood bar, current tier, active modifiers, and daylight hazard.

The player feeds by clicking **Karmi się**, selecting a living creature
within 3.5 m, and draining 15 HP → gaining 25 blood. The cure requires
a `vamp_holy_blood` item in inventory.

### Blood tiers

| Range | Name | Effects |
|-------|------|---------|
| 75–100 | Sytość | +2 STR/DEX, Regen 2 HP/s |
| 50–74 | Zaspokojenie | +1 STR/DEX, Regen 1 HP/s |
| 25–49 | Głód | No modifiers |
| 10–24 | Wygłodzenie | −1 STR/DEX/CON |
| 1–9 | Szał Krwi | −3 STR/DEX/CON, −50% move speed |
| 0 | Konanie z Głodu | −6 STR/DEX, −4 CON, −75% move speed |

Sun damage: **1d6 divine damage per tick** when outdoors (exterior area)
during daytime.

---

## Files

```
Vampirism/scripts/
  sql_vamp.nss       Campaign DB layer (vampirism.sqlite)
  lib_vamp_def.nss   Constants, NUI bind names, forward declarations
  lib_vamp.nss       Core logic: effects, NUI layout, feeding, cure
  lib_vamp_ev.nss    NUI event handler (assigned to VAMP_WINDOW)
  sys_on_load.nss    OnModuleLoad: CREATE TABLE + start 6 s HB loop
  sys_on_enter.nss   OnClientEnter: restore effects + open window
  sys_on_target.nss  OnPlayerTarget: route feed result
  test_vamp.nss      OnUsed placeable: infect / give cure item
  lib_nui.nss        Shared NUI helpers (copy from any other module)
  lib_nui_utility.nss Shared NUI utility helpers
```

---

## Hooks to wire up

In the Aurora Toolset (or via `.mod` properties):

| Event | Script |
|-------|--------|
| **OnModuleLoad** | `sys_on_load` (or call `ExecuteScript("sys_on_load", GetModule())` from your existing load script) |
| **OnClientEnter** | `sys_on_enter` (merge if you already have one) |
| **OnPlayerTarget** | `sys_on_target` (merge if you already have one) |

Place a **Placeable** with its **OnUsed** event set to `test_vamp`.

---

## No NWNX required

The module is pure NWN:EE NWScript + built-in SQLite
(`SqlPrepareQueryCampaign`). No NWNX plugins needed.

---

## Cure item

Create a **Unique Power (Self Only)** item with tag **`vamp_holy_blood`**
(resref can match). The test script will spawn it from inventory for
testing; in production it should be a craftable or loot-table item.

---

## What was intentionally omitted

- **Vampire appearance change** — integration with the Appearance module
  is non-trivial; left for a follow-up.
- **NPC vampire attackers** — infection-on-hit from existing creatures
  would require editing their OnHit scripts; documented as an extension
  point rather than implemented here.
- **Thirst for PC blood** — feeding on other PCs is enabled but there is
  no forced-PvP gating; server rules govern whether this is allowed.
- **Vampire spawn abilities** (e.g. bat form, charm gaze) — future
  expansion; current scope focuses on the blood-management loop.
