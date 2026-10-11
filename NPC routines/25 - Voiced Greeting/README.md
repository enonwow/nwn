# Voiced Greeting

Two NPCs meet, face each other, and exchange the prepared voice clips before returning home.

## Main features

- Original SVM_16_SMALLTALK and SVM_17_SMALLTALK recordings from the bundled HAK.
- Three-second turn spacing; both participants wait until the reply finishes.
- Original audio is preserved, with English captions; interruptions cancel pending speech.

## Demo files

- Module: [DEMO-NPC-25-Voiced-Greeting.mod](DEMO-NPC-25-Voiced-Greeting.mod)
- Required HAK: [npc_sounds.hak](npc_sounds.hak)
- Routine script: `rt_voice`. Its formatted NWScript source and compiled code are embedded in the MOD; remaining scripts are event/control adapters.

## Try it

Install the files as described in the [collection README](../README.md#installation), then start a new game in this demo.

TEST starts a short voiced exchange using the prepared npc_sounds.hak clips. Alena and Brenna meet and face each other. Alena says I saw it myself; Brenna replies Everyone knows about it now after three seconds. Both stay for three seconds after the reply, then return home. Original audio is preserved; captions and controls are English. Turn up sound-effects volume. Conversation, combat or death cancels pending turns. STATUS shows progress.

Use INSTRUCTIONS to repeat the in-game help and STATUS to inspect progress. Allow time for approach and action animations.
