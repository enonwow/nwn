#include "lib_bur"

// OnPlayerTargeting event handler.
// Chain other targeting handlers before/after the BurOnPlayerTarget call
// when integrating with an existing module that already uses this event.

void main()
{
    BurOnPlayerTarget(OBJECT_SELF);
}
