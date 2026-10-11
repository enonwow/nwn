# Shop Hours

A merchant opens and closes the shop according to the time of day.

## Main features

- The merchant approaches the door and confirms its open/locked state.
- Trading starts only after arrival at the counter.
- Blocked approaches retry; STATUS reports the schedule and door state.

## Demo files

- Module: [DEMO-NPC-09-Shop-Hours.mod](DEMO-NPC-09-Shop-Hours.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_shop`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

TEST switches between 10:00 and 22:00. The merchant approaches the clear door point, opens or closes the door, confirms its state, then goes to the counter or home. Trade is available only at the counter after confirmed opening. STATUS shows the desired schedule, door state, completed cycles and any failed approach. A blocked action retries after 30 seconds.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
