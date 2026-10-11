# Lamplighter

A lamplighter visits three lamps and changes their lights for day or night.

## Main features

- Arrival, facing and a completed work gesture precede each light change.
- Lamps are processed in sequence.
- The worker returns home; STATUS reports each lamp.

## Demo files

- Module: [DEMO-NPC-12-Lamplighter.mod](DEMO-NPC-12-Lamplighter.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_lamps`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Use TEST to switch between 10:00 and 22:00. The lamplighter walks to each lamp, faces it, finishes the work gesture, then changes its light. After all three lamps, he returns home. STATUS shows progress and each lamp state.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
