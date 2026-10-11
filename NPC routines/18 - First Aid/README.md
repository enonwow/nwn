# First Aid

A medic approaches an injured patient and performs a short treatment.

## Main features

- Close approach, mutual orientation and a three-second hand-work gesture.
- Only completed treatment restores up to eight HP and displays a healing effect.
- Dialogue, combat or death cancels unfinished treatment.

## Demo files

- Module: [DEMO-NPC-18-First-Aid.mod](DEMO-NPC-18-First-Aid.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_healer`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

TEST removes 10 HP from the patient. The medic approaches closely, faces the patient and works with their hands for 3 seconds. Only completed treatment restores up to 8 HP and shows a small healing effect on the patient. STATUS shows patient HP and completed treatments. Dialogue, combat or death interrupts pending treatment.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
