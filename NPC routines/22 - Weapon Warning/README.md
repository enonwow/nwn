# Weapon Warning

A watch guard gives a visible armed player three warnings before attacking.

## Main features

- Warnings are six seconds apart, with another six seconds after the final warning.
- Unequipping the weapon or leaving sight cancels pending escalation.
- TEST can lend a sword; RESET ends the demonstration incident.

## Demo files

- Module: [DEMO-NPC-22-Weapon-Warning.mod](DEMO-NPC-22-Weapon-Warning.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_weapon`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

The watch guard starts friendly. A visible player carrying a weapon receives three warnings, six seconds apart, then the guard attacks six seconds after the final warning. Unequip the weapon or leave sight to cancel. TEST loans a short sword when your hands are empty; click again to put away that exact loan. Your own equipment is preserved. RESET ends the demonstration incident.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
