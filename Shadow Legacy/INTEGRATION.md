# Shadow Legacy — Dziedzictwo Cieni

Persistent cross-character legacy system. When a PC dies, their achievements
are crystallized into a **Legacy Record** tied to the player's CD key. The next
character that player creates can visit a **Memory Stone** placeable and claim
one legacy — gaining a permanent passive blessing at the cost of a matching burden.

## Hooks to wire up

| Module event        | Script               | Notes                                      |
|---------------------|----------------------|--------------------------------------------|
| OnModuleLoad        | `sys_on_load`        | Creates SQLite tables                      |
| OnClientEnter       | `sys_on_enter`       | Tracks areas visited, re-applies effects, notifies |
| OnPlayerDeath       | `sys_on_death`       | Detects curse state, records legacy        |
| OnPlayerRest (fin.) | `sys_on_rest`        | Re-applies TemporaryHitpoints              |
| NPC OnDeath         | `sys_on_npc_death`   | Increments PC kill counter                 |
| NUI Event script    | `lib_sleg_ev`        | Set via `NuiCreate` — already wired internally |

If you use multiple OnClientEnter scripts, call `ExecuteScript("sys_on_enter", oPC)`
from your main enter handler rather than replacing it.

## Memory Stone placeable

- Create any placeable in the Toolset.
- Set its **OnUsed** script to `test_sleg`.
- The demo block at the top of `test_sleg.nss` seeds three test legacies; remove it for production.

## Legacy types and thresholds

| Type       | Trigger condition                           | Blessing                        | Burden                          |
|------------|---------------------------------------------|---------------------------------|---------------------------------|
| Warrior    | ≥40 kills, fighter/barbarian class          | +2 attack (melee)               | −2 Will vs. mind spells         |
| Mage       | Level ≥5, wizard/sorcerer class             | +5 Spell Resistance             | −2 Fortitude save               |
| Rogue      | ≥15 kills, rogue class                      | +3 Hide, +3 Move Silently       | −2 Will save                    |
| Martyr     | ≥3 PC deaths                                | +10 temporary HP (per rest)     | −1 attack rolls                 |
| Wanderer   | ≥12 unique areas visited                    | +2 Animal Empathy, +2 Survival  | −1 AC (dodge)                   |
| Devout     | Level ≥4, divine class                      | +2 saves vs. divine effects     | −2 Reflex save                  |
| Cursed     | Died with an active curse/ability decrease  | +25% fire resistance            | −1 Strength (EffectCurse)       |

## Dependencies

- **Vanilla NWN:EE only** — no NWNX required.
- Uses `SqlPrepareQueryCampaign` with campaign name `"shadow_legacy"`.
  Make sure campaign DB is enabled on your server.

## What was intentionally omitted

- **Multiple active legacies**: A character can hold only one. Adding more would
  require careful stacking logic and balance work beyond this module's scope.
- **Legacy abandonment UI**: Players cannot drop an active legacy. A DM console
  command to clear `claimed_uuid` in the DB is sufficient for edge cases.
- **Inheritance chain limits**: Currently all past legacies of a CD key are visible.
  You may wish to cap this (e.g. last 5) by adding `LIMIT 5` in `SlegGetLegacies`.
- **Custom icons / HAK assets**: The module uses text-only NUI; no custom images
  are needed. Add a background image by inserting a `NuiDrawListImage` call in a
  draw list on the root group if desired.
