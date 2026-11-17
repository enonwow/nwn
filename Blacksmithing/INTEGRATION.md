# Kuźnia — Blacksmithing Workshop

Dark-fantasy item crafting: forge weapons, armour, and shields from raw materials at an anvil. Quality depends on a Strength + Craft check.

## Hooks to wire in

| Event | Script |
|---|---|
| OnModuleLoad | call or include `sys_on_load` |
| OnClientEnter | call or include `sys_on_enter` (optional — shows material hint) |
| Anvil/Forge placeable → OnUsed | `test_smit` (demo) or your own wrapper that calls `SmithOpenWindow(GetLastUsedBy())` |

## HAK items required

Create five inventory items with the following tags (the forge checks `GetTag()`):

| Tag | Suggested name | Notes |
|---|---|---|
| `smit_iron` | Żelazna Sztabka | stackable, e.g. weight 1.0 |
| `smit_leather` | Pasek Skóry | stackable |
| `smit_bone` | Odłamek Kości | stackable |
| `smit_wood` | Belka Drewna | stackable |
| `smit_gem` | Surowy Klejnot | stackable, rarer — used only in advanced recipes |

The `test_smit.nss` demo creates these by tagging a scroll blueprint; replace with proper items in production.

## SQL

Uses `SqlPrepareQueryCampaign("smith", …)` — a campaign DB named **smith**. No NWNX required.

Tables:
- `smith_recipes` — 15 built-in recipes (seeded once at module load, idempotent).
- `smith_history` — per-PC forge history, capped at 15 rows per character.
- `smith_meta` — single-row seed flag.

## Quality system

The forging roll is `d20 + STR modifier + Craft Trap rank` (the closest proxy for smithing in NWN base skills) versus the recipe's DC:

| Roll vs DC | Quality | Effect |
|---|---|---|
| < DC−5 | 1 — Kruche | name prefix only; no property |
| DC−5 to DC−1 | 2 — Pospolite | standard item |
| DC to DC+4 | 3 — Dobre | +1 Enhancement / AC |
| DC+5 to DC+9 | 4 — Wyborne | +2 Enhancement / AC |
| ≥ DC+10 | 5 — Mistrzowskie | +3 Enhancement / AC |

Weapons receive `ItemPropertyEnhancementBonus`; armour and shields receive `ItemPropertyACBonus`.

## Adding custom recipes

```nss
SmithInsertRecipe(
    100,              // unique id (> 15 to avoid collision with defaults)
    SMIT_CAT_WEAPON,  // or SMIT_CAT_ARMOR / SMIT_CAT_SHIELD
    "Miecz Nocy",     // display name
    "my_darksword",   // resref of the blueprint
    "Opis po polsku.", // flavour text
    jMaterials,       // json array from SmithMat() calls
    16                // craft DC
);
```

Call this from `sys_on_load` after `SmithSeedRecipes()`. Use `INSERT OR IGNORE` semantics (already handled by `SmithInsertRecipe`).

## Deliberately omitted

- Levelling / progression unlock per recipe (all recipes visible from the start).
- Fail-roll item destruction (quality 1 items are weak but the player keeps them).
- NWNX hooks — the module uses only the NWN:EE base API.
- Visual forge animation / particle effects (require NWNX_Object or custom HAK).
