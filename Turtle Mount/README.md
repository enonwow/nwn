# Turtle Mount

A rideable giant turtle for Neverwinter Nights: Enhanced Edition. It works with the game's own 1.69 horse system: right-click the turtle and choose **Mount**, ride it like a horse, then choose **Dismount**. You do not need NWNX or new rider animations.

## Main features

- The game's own **Mount / Dismount** actions from the right-click menu and the horse radial menu (`x3_inc_horse`), for players and NPCs (`HorseMount`, `HorseDismount`).
- The rider sits on the shell with the legs on both sides of it. Tested in game with human, elf, dwarf and halfling riders of both genders. Smaller races get a smaller turtle, matching the rider's size.
- Walking, running, turning and taking hits play turtle animations that stay in step with the rider's animations.
- Reins run from the bit in the turtle's beak to the rider's left hand and follow the hand in all 167 mounted rider animations. This includes walking, running, weapon and shield poses, casting, emotes and falls.
- After dismounting, the turtle comes back next to the rider as the rider's mount, the same way a horse does.

## Demo files

- Module: [Module/DEMO-Turtle-Mount.mod](Module/DEMO-Turtle-Mount.mod)
- Required HAK: [Hak/turtlemount.hak](Hak/turtlemount.hak). It contains the models, textures, portrait, `appearance.2da`, `tailmodel.2da` and the scripts (NWScript source and compiled code).
- The area uses only base game tiles (City Exterior). No other HAK is needed.

## Installation

1. Copy `Module/DEMO-Turtle-Mount.mod` to your Neverwinter Nights user-data `modules` directory.
2. Copy `Hak/turtlemount.hak` to the user-data `hak` directory. Keep its filename unchanged.

## Try it

Start a new game in **DEMO-Turtle-Mount**. A turtle stands 3 m to your right on a flat city plaza. Right-click it and choose **Mount**. Walk and run around, draw a weapon, cast a spell, then right-click yourself (or use the horse radial menu) and choose **Dismount**.

## How it works

### The turtle is a horse "tail"

In the 1.69 horse system a mounted rider switches to the mounted phenotype (3). Its animations (`h_ba` and its supermodels) contain both the rider and the horse skeleton. The horse itself is a tail model attached to the rider, and the engine plays the tail animation that has the same name as the rider's current animation.

The turtle uses the same mechanism:

| Resource | What it is |
| --- | --- |
| `c_ridturtle` | The turtle standing in the world: a normal creature (appearance row 15100) with simple-creature animations. |
| `c_ridturtlet` | The tail model the rider carries while mounted (`tailmodel.2da` row 5050). Its 167 animations have the names of the mounted rider's animations (`pause1`, `walk`, `run`, `1hreadyr`, `conjure1`, ...). Each one has exactly the rider animation's length, so both loops stay in step. |
| Blueprint `c_ridturtle` | Local variables read by `x3_inc_horse`: `X3_HORSE_TAIL` = 5050 (this makes the creature a mount), `X3_NO_MOUNT_ANIMATE` = 1, `X3_HORSE_FOOTSTEP` = 11 (lizard steps instead of hooves), `X3_HORSE_PREMOUNT_SCRIPT` and `X3_HORSE_PREDISMOUNT_SCRIPT` = `turtle_mnt`. |

### Seat height and size

The stock mounted animations are made for a horse: the saddle is about 1.75 m high, and the rider's legs wrap a body about 0.6 m wide.

- **Size:** the turtle is 2.25 m long, so its shell fits between the rider's knees. At bigger sizes the shins go into the shell.
- **Height:** in the tail model the turtle stands 0.90 m higher, with the shell just under the saddle. While mounted, `turtle_mnt` lowers the whole rider with a visual transform (`SetObjectVisualTransform`, translate Z) by 0.90 m × the mounted appearance's `WING_TAIL_SCALE`, so the turtle's feet touch the ground. It follows the horse scripts' own timing for 8 s after mounting and dismounting, and it is re-checked when a player enters the area.

### Reins that follow the hand

The mounted rider animations contain a node, `rein_lhand_h`, that follows the left hand holding the reins. The game's horse uses it for its own reins. The turtle tail model has a node `zrein` keyed with the same positions in each of the 167 animations. The ends of the two leather straps hang on it. The other ends are skinned to the bit in the turtle's beak, and in between they run along the cheek and over the neck, so the straps follow the turtle's head.

For this to land in the hand, the tail must scale exactly like the rider. The HAK's `appearance.2da` sets `WING_TAIL_SCALE` of `Dwarf_mounted_f` to 0.82 and `Human_mounted_f` to 0.988 (base game: 0.777 and 1), matching the `setanimationscale` of those rider models. All other races already match.

### Scripts

| Script | Event | What it does |
| --- | --- | --- |
| `turtle_load` | Module OnModuleLoad | Runs the stock `x3_mod_def_load`, then sets `X3_HORSE_DISABLE_SPEED` (a turtle does not get the +99 % mounted speed bonus). |
| `x3_mod_def_enter` | Module OnClientEnter | Stock script: gives players the horse radial menu. |
| `turtle_enter` | Area OnEnter | Spawns one turtle next to the entering player (once per area). |
| `turtle_mnt` | Turtle pre-mount and pre-dismount | Keeps the rider's visual lowering in step with the tail change. |
| `turtle_inc` | Include | Constants (tail row, appearance row, lift) and helpers (`TurtleSync`, `TurtleSpawn`). |

## Using it in your own module

1. Add `turtlemount.hak` to your module. If your module already has `appearance.2da` or `tailmodel.2da`, merge rows 15100 (appearance) and 5050 (tailmodel), plus the two `WING_TAIL_SCALE` changes, into your own tables, and update `TURTLE_APP` and `TURTLE_TAIL` in `turtle_inc` if you use other row numbers.
2. Use the stock horse event scripts (`x3_mod_def_load` or `turtle_load`, and `x3_mod_def_enter`), or call `HorseAddHorseMenu` yourself.
3. Copy the `c_ridturtle` blueprint from the demo module, or create the creature with `TurtleSpawn(location)`.

## Limitations

- Mounting and dismounting are instant. The stock mount animations climb to a horse's saddle height, which does not fit a turtle.
- During rider animations that have no turtle motion of their own (attacks, casting, emotes), the turtle plays its idle animation. Only the reins move with the hand.
- The tail model is large (about 25 MB) because the turtle is keyed every frame in all 167 animations.
- Jousting animations (`custom3lp`, `custom4lp`, `custom5lp`) are not supported.
