# Work and Shifts

Two alternating teams work at assigned stations, take breaks, and hand over the active shift.

## Main features

- Four workers: two in shift A and two in shift B.
- Confirmed arrival, ten seconds of work, then a four-second break.
- The shift bell swaps teams; interruptions cancel unfinished work.

## Demo files

- Module: [DEMO-NPC-24-Work-Shifts.mod](DEMO-NPC-24-Work-Shifts.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_shift`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Two workers in shift A begin on duty and two workers in shift B rest. Workers arrive at their own work positions, finish ten seconds of work, take a four-second break, then return. TEST rings the shift bell and swaps A/B. A change or conversation cancels unfinished work. STATUS shows the active shift, each worker state and completed work cycles.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
