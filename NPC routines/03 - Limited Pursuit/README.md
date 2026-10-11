# Limited Pursuit

A guard chases a target within a limited distance, then returns to the home post.

## Main features

- A 14-metre home limit prevents endless pursuit.
- The guard breaks off the chase and returns home.
- TEST starts a repeatable pursuit.

## Demo files

- Module: [DEMO-NPC-03-Limited-Pursuit.mod](DEMO-NPC-03-Limited-Pursuit.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_leash`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Use TEST to make the guard chase you. Move more than 14 metres from the guard home point. The guard should stop chasing and return home.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
