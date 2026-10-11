# Fire Response

A responder fetches water from a well and returns to extinguish a burning woodpile.

## Main features

- Running between the well and the fire.
- A real water container and completed filling/pouring stages.
- Three completed trips extinguish the fire; interruptions cancel unfinished work.

## Demo files

- Module: [DEMO-NPC-19-Fire-Response.mod](DEMO-NPC-19-Fire-Response.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_fire`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Watch the responder spot a burning woodpile, run to the well, fill a water container and return to pour it. Three completed trips extinguish the fire. TEST restarts the fire; STATUS shows strength, water and trips. Dialogue interrupts unfinished work.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
