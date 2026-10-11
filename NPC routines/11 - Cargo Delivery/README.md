# Cargo Delivery

A worker picks up a real item from a source container and delivers it to a destination.

## Main features

- Actual inventory transfer, rather than a visual-only gesture.
- Source pickup and destination delivery are separate stages.
- Inspect the destination inventory; TEST creates another order after completion.

## Demo files

- Module: [DEMO-NPC-11-Cargo-Delivery.mod](DEMO-NPC-11-Cargo-Delivery.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_cargo`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Watch the worker transfer a real item from the source container to the destination container. Inspect the destination inventory. Once delivery ends, TEST creates another order.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
