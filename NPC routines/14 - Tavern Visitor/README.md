# Tavern Visitor

Guests find a tavern seat, order ale, receive a bottle, drink, and leave.

## Main features

- Three visitors share two reserved seats.
- An innkeeper prepares and serves orders sequentially.
- Guests wait for delivery; the next visitor waits for a free seat.

## Demo files

- Module: [DEMO-NPC-14-Tavern-Visitor.mod](DEMO-NPC-14-Tavern-Visitor.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_tavern`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Three visitors share two tavern seats. The innkeeper prepares ale at the bar, serves each order in turn, then returns to work. Guests remain seated until their bottle arrives, drink it and leave. The third visitor waits for a free seat. TEST restarts all visits; STATUS shows orders and bottles served.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
