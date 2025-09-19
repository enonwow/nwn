#include "nwnx_events"
#include "lib_g_lockpick"

void main()
{
   object oPC = OBJECT_SELF;
   string sKey = NWNX_Events_GetEventData("KEY");
   string sCurrentEvent = NWNX_Events_GetCurrentEvent();

   if (sCurrentEvent == "NWNX_ON_INPUT_KEYBOARD_BEFORE")
   {
      if(sKey == "A" || sKey == "D")
      {
         GothicLockpickChangeImage(oPC, sKey);
      }
   }
}
