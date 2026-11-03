// OnUsed script for a demo dig-site placeable.
// Place this script on any placeable to turn it into a dig site.
// Set local int EXC_ERA (0-3) on the placeable to choose the era.
// Set local string "EXC_SITE_TAG_OVERRIDE" to override the tag used for per-PC tracking
// (useful when you want multiple placeables of the same resref to be distinct sites).

#include "lib_exc"

void main()
{
    object oPC   = GetLastUsedBy();
    object oSite = OBJECT_SELF;

    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Validate tag — must be unique per site
    if(GetTag(oSite) == "")
    {
        SendMessageToPC(oPC, "[Wykopaliska] Błąd: placeable nie ma tagu. Ustaw unikalny tag.");
        return;
    }

    ExcOpen(oPC, oSite);
}
