# Crime Witness

A witnessed theft triggers a report, a guard search, and recovery of the exact stolen parcel.

## Main features

- The witness must see the theft.
- The guard searches visible suspects or carriers and can stop/search a nearby player.
- The recovered parcel returns to its chest; escaping sight can evade the search.

## Demo files

- Module: [DEMO-NPC-16-Crime-Witness.mod](DEMO-NPC-16-Crime-Witness.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_witness`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

Take the merchant parcel from the chest while the witness sees you. The witness reports the theft, then the guard searches for a visible suspect or carrier. Stay nearby to be stopped and searched; the guard recovers the exact stolen parcel and returns it to the chest. Escape sight or leave the area to evade the search. TEST resets the case and returns the parcel; STATUS shows progress.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
