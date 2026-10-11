# Gate Inspection

A guard approaches the player and starts a gate inspection conversation.

## Main features

- Player interaction through a dedicated inspection dialogue.
- A trading answer completes the inspection.
- TEST can trigger another inspection near the guard.

## Demo files

- Module: [DEMO-NPC-08-Gate-Inspection.mod](DEMO-NPC-08-Gate-Inspection.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_gate`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Use TEST near the guard. The guard approaches and starts an inspection dialogue. Select the trading answer and watch the inspection end.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
