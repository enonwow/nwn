# Home and Sleep

A resident follows a day/night schedule, returns to a bedroom, and rests on a bedroll.

## Main features

- Two rooms connected by an open doorway, with a non-blocking bedroll.
- Arrival and the queued rest command are confirmed before the routine records rest.
- Morning wakes the resident and sends them back; dialogue/combat interrupts the schedule.

## Demo files

- Module: [DEMO-NPC-21-Home-Sleep.mod](DEMO-NPC-21-Home-Sleep.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_home`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

The demo starts at 22:00. Watch the resident leave the daytime room, walk through the open doorway to the bedroom and lie on the bedroll. TEST switches to 10:00: the resident gets up and returns to the daytime room. Click TEST again for another night. STATUS reports arrival and whether the queued rest command executed. Conversation or combat interrupts the routine; it resumes when safe.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
