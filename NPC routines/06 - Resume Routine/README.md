# Resume Routine

An NPC resumes its normal patrol after a conversation or a temporary interruption.

## Main features

- Dialogue pauses normal movement.
- The routine resumes after the interruption ends.
- Conversation and combat interruption can be tested.

## Demo files

- Module: [DEMO-NPC-06-Resume-Routine.mod](DEMO-NPC-06-Resume-Routine.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_resume`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Talk to the NPC, then end the conversation. The NPC should resume the patrol. TEST forces a short interruption. You can also test a combat interruption.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
