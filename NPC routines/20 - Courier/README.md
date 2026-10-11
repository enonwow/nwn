# Courier

A courier appears, runs to the player, delivers a sealed dispatch, then runs away and disappears.

## Main features

- The letter is placed directly in the recipient inventory.
- Delivery and exit are separate confirmed stages.
- Repeated TEST during an active delivery creates no duplicate courier or letter.

## Demo files

- Module: [DEMO-NPC-20-Courier.mod](DEMO-NPC-20-Courier.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_courier`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

A courier appears at the street entrance, runs to you, hands a sealed dispatch into your inventory, runs away and disappears at a distant exit. TEST calls another courier after the previous one leaves. STATUS shows delivery and the last letter; repeated TEST during an active delivery creates no duplicates.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
