# Guard Relief

Two guards perform an orderly change of watch without leaving the post unattended.

## Main features

- The duty guard waits for the replacement to arrive.
- Both guards face each other and exchange ordered reports.
- Only a completed handover releases the outgoing guard.

## Demo files

- Module: [DEMO-NPC-07-Guard-Relief.mod](DEMO-NPC-07-Guard-Relief.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_relief`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

The duty guard holds the post until the relief guard arrives. They face each other and exchange two ordered reports, then the outgoing guard returns to rest. The first change starts after about 12 seconds; later watches last at least 48 seconds. TEST requests the next change when both guards are ready. STATUS shows who is on duty and completed changes. Talking to either guard interrupts the handover without sending the duty guard away.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
