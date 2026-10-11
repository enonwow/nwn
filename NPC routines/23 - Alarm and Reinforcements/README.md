# Alarm and Reinforcements

An attacked guard calls nearby guards, who respond according to their own perception.

## Main features

- Reinforcements must hear or see the alarm.
- A responder attacks only after seeing the attacker; otherwise it searches the reported location.
- RESET ends the staged incident and returns guards to their posts.

## Demo files

- Module: [DEMO-NPC-23-Alarm-Reinforcements.mod](DEMO-NPC-23-Alarm-Reinforcements.mod)
- Required HAK: None; this demo uses game resources.
- Routine script: `rt_alarm`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

TEST starts a staged attack on the watch guard. Guards that hear or see the alarm respond. A responder attacks only after seeing the attacker; otherwise it runs to the reported alarm location and searches briefly. RESET ends the incident and returns guards to their posts. The staged attacker is neutral to you.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
