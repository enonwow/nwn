# Meeting

Two NPCs meet, face each other, exchange lines in order, and return home.

## Main features

- Separate meeting positions and confirmed arrival.
- The second participant answers after the first line.
- Both stay until the reply ends; interruptions cancel pending turns.

## Demo files

- Module: [DEMO-NPC-13-Meeting.mod](DEMO-NPC-13-Meeting.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_meeting`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Two NPCs walk to separate meeting positions and face each other. The initiator asks first; the partner answers after the first line finishes. Both stay until the reply finishes, then return home. Use TEST for a new meeting or talk to either participant to interrupt and resume the exchange.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
