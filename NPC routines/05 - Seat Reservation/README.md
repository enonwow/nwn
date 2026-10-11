# Seat Reservation

NPCs reserve available chairs, sit for a while, then stand up and release them.

## Main features

- Three NPCs compete for two chairs.
- Seat reservations prevent simultaneous use.
- Seats become available again when a visitor leaves.

## Demo files

- Module: [DEMO-NPC-05-Seat-Reservation.mod](DEMO-NPC-05-Seat-Reservation.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_seat`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Three NPCs compete for two chairs. Watch them reserve a seat, sit, wait, stand and release it. Use TEST to restart.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
