# Interrogation Chamber — Integration Guide

## Hooks to wire in your module

| Event              | Script              | Notes                                       |
|--------------------|---------------------|---------------------------------------------|
| OnModuleLoad       | `sys_on_load`       | Creates SQL tables + seeds default secrets  |
| OnClientEnter      | `sys_on_enter`      | Notifies PC about nearby prisoners          |
| Placeable OnUsed   | `test_intr`         | Opens the interrogation window              |

## Marking a prisoner

Set the following local variable on any creature you want to be interrogatable:

| Variable            | Type | Value | Meaning                       |
|---------------------|------|-------|-------------------------------|
| `INTR_IS_PRISONER`  | Int  | 1     | Marks creature as a prisoner  |
| `INTR_SECRET_75`    | String | *   | (Optional) custom secret at 75% resistance threshold |
| `INTR_SECRET_50`    | String | *   | (Optional) custom secret at 50% threshold            |
| `INTR_SECRET_25`    | String | *   | (Optional) custom secret at 25% threshold            |
| `INTR_SECRET_0`     | String | *   | (Optional) custom secret at 0 (broken) threshold     |

If no custom LVAR secrets are set, the system looks up the creature's ResRef in
the `intr_confessions` SQL table (see `sys_on_load.nss` for seeding examples),
then falls back to generic flavor text keyed by racial type.

## Adding custom confessions via script

```nss
#include "sql_intr"
IntrAddConfession("your_creature_resref", 75, "Spotykamy sie o swicie...");
IntrAddConfession("your_creature_resref", 50, "Haslo to Czerwona Gwiazda...");
IntrAddConfession("your_creature_resref", 25, "Skarbiec jest pod kaplicq...");
IntrAddConfession("your_creature_resref",  0, "Zdradze wszystko! Zmilujtcie!");
```

## NWNX dependencies

None. The module uses only vanilla NWScript + NUI + campaign SQLite.

## Mechanics summary

| Method        | Skill check           | Resistance drop (success / fail) | Moral cost |
|---------------|-----------------------|----------------------------------|------------|
| Przesluchanie | INT + Lore vs DC 12+  | -20 / -5                         | 0          |
| Zastraszenie  | STR + Intimidate vs DC 10+ | -25 / -10                   | 1          |
| Tortury       | None (automatic)      | -30 / —                          | 3          |
| Podstep       | CHA + Bluff vs DC 11+ | -35 / +10 (backfire)             | 1          |

Moral cost ≥ 10 within one session triggers an alignment shift toward evil
(5 points per 10 cost) when the window is closed.

Tortury: 8% chance of prisoner death when resistance ≤ 25.

## SQL tables

- `intr_confessions` — custom secrets by ResRef + threshold (global campaign DB "intr")
- `intr_sessions` — log of completed interrogation sessions (pc_uuid, prisoner_uuid, broken, moral_cost)
- `intr_conflog` — log of each individual secret revealed
