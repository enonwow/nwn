# Honor Duels — integration

PvP honor-duel system with configurable rules, gold stakes, an arena
bounded by the challenger's location, and an honor ranking.

## What you get

- Honor board (placeable -> NUI window with 3 tabs: Challenges / History / Ranking).
- Challenge via targeting mode with opponent selection.
- Pre-send configuration: win condition (first blood / to the death /
  until yield), rules (no magic, no potions/scrolls, no crits), gold stake.
- Popup on the challenged side: accept / decline.
- 5-second countdown, automatic temporary hostility, HUD with HP bars.
- Tick every 1s: HP check, arena bounds (10m radius), win condition.
- Forfeit on flee (>6s outside the arena) or yield.
- Honor: +10 win, -3 loss, -15 decline, -25 forfeit, +5 bonus on a death-duel kill.
- Stakes: winner takes both halves; mutual death = refund.
- Persistence: SQLite (campaign-scope, database name `duel`).

## Requirements

- NWN:EE (NUI + JSON API).
- No NWNX (pure NWScript).

## Wiring module hooks

In your module's event handlers, call the corresponding entry points:

### `OnModuleLoad`
```nwscript
ExecuteScript("sys_on_load", OBJECT_SELF);
```
Creates the SQL schema and expires stale challenges.

### `OnClientEnter`
```nwscript
ExecuteScript("sys_on_enter", OBJECT_SELF);
```
Registers the player in the honor table and notifies them about pending challenges.

### `OnPlayerTarget`
```nwscript
ExecuteScript("sys_on_target", OBJECT_SELF);
```
Handles target selection after the player clicks "Throw down the gauntlet".
If you already use `OnPlayerTarget` for another module (e.g. Mailbox, Spell Macro),
merge the dispatch logic — call each handler conditionally based on context.

## Opening the honor board

On a placeable (e.g. an honor board, town square notice, signpost), set its
OnUsed handler to:

```nwscript
#include "lib_duel"
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDuelMainWindow(oPC);
}
```
(Equivalent to the bundled `test_duel.nss`.)

## Design notes

- **Arena** is the challenger's location at the moment the challenge is created.
  Radius is 10m. The challenged player must come within 1.5x the radius to
  accept.
- **Rules** (no_magic / no_items / no_crit) are persisted and displayed,
  but their enforcement (block spellcasting, block item use, neutralize crits)
  is **not** wired up in this version — that requires `OnSpellCastAt` /
  `OnUseItem` hooks. Left as a future extension.
- **Hostility** uses `SetIsTemporaryEnemy` / `SetIsTemporaryNeutral`. Other
  players are not blocked from interfering — for a real server, add a PvP
  zone or block intervention via `OnPhysicalAttacked`.
- **Offline stakes**: if the challenger logs out before a response, the gold
  is lost (MVP limitation). A real server should refund via Mailbox.
- **Killing blow** counter only increments when the win condition is
  TO_DEATH; first blood and yield do not increment `kills`.

## Files

| File                  | LOC | Role                                            |
|-----------------------|----:|-------------------------------------------------|
| `lib_duel_def.nss`    | 240 | Constants, statuses, rules, layout, formatters. |
| `sql_duel.nss`        | 339 | Schema (`duels` + `duel_honor`) + CRUD.         |
| `lib_duel_flow.nss`   | 526 | State machine: submit/accept/decline/begin/    |
|                       |     | tick/yield/end + honor and stake handling.      |
| `lib_duel_ui.nss`     | 338 | Main window (3 tabs) + list feed.               |
| `lib_duel_hud.nss`    | 272 | Active-duel HUD + incoming + challenge config   |
|                       |     | popups.                                         |
| `lib_duel_ev.nss`     | 261 | NUI event router for all 4 windows.             |
| `lib_duel.nss`        |  38 | Public facade (`#include` + targeting helper).  |
| `sys_on_load.nss`     |   7 | Schema init + expire.                           |
| `sys_on_enter.nss`    |  18 | Honor registration + pending notification.      |
| `sys_on_target.nss`   |  13 | Targeting -> challenge config popup.            |
| `test_duel.nss`       |   8 | OnUsed entry point for the honor-board placeable.|
| `lib_nui.nss`         | 108 | NUI helper layer (copied from Mailbox).         |
| `lib_nui_utility.nss` |  98 | NUI helper layer (copied from Mailbox).         |

## Intentionally omitted (consider for v2)

- Rule enforcement (no_magic / no_items / no_crit) requires `OnSpellCastAt`
  and `OnUseItem` hooks — significant refactor outside MVP scope.
- Seconds / witnesses.
- Salute animations (bow, sword salute) — risk of conflict with combat
  readiness.
- PvP zone (block other players from interfering).
- Refunding stakes via Mailbox for offline players.
- HAK with main-window background art and an honor-board icon.
