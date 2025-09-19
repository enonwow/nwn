#include "nwnx_events"

void main()
{
    NWNX_Events_SubscribeEvent("NWNX_ON_INPUT_KEYBOARD_BEFORE", "event_kb_input");
}
