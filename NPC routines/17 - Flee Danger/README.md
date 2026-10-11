# Flee Danger

An NPC runs from a threat, waits in safety, and later walks home to resume normal duties.

## Main features

- Escape movement uses running.
- Running can resume after dialogue or a combat round.
- Normal walking and patrol resume after the threat expires.

## Demo files

- Module: [DEMO-NPC-17-Flee-Danger.mod](DEMO-NPC-17-Flee-Danger.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_escape`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Use TEST while the NPC can see you. The NPC runs to safety, waits until the threat expires, then walks home and resumes the patrol. Running also resumes after dialogue or a combat round. You can also attack the NPC to supply a threat.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
