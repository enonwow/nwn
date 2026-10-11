# Service Queue

Customers join a queue, advance in ticket order, and complete service.

## Main features

- Three customers demonstrate ordered service.
- Waiting positions advance as the queue clears.
- TEST restarts the queue for another run.

## Demo files

- Module: [DEMO-NPC-15-Service-Queue.mod](DEMO-NPC-15-Service-Queue.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_queue`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Three customers queue in ticket order, advance and complete service. Use TEST to restart the queue.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
