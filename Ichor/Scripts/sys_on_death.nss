#include "lib_ichor"

// Hook this into the module's OnDeath (or creature's OnDeath) event.
// OBJECT_SELF is the dying creature.

void main()
{
    object oDead = OBJECT_SELF;

    // Mark the corpse so nearby PCs can harvest.
    IchorMarkCorpse(oDead);

    // Notify the killing PC if one is nearby.
    if(GetLocalString(oDead, "ICHOR_TYPE") == "") return;

    object oKiller = GetLastKiller();
    if(!GetIsPC(oKiller)) return;

    string sTypeName = IchorTypeName(GetLocalString(oDead, "ICHOR_TYPE"));
    SendMessageToPC(oKiller,
        "[Ichor] Ciało " + GetName(oDead) + " zawiera esencję: "
        + sTypeName + ". Użyj narzędzia Ichoru w ciągu "
        + IntToString(ICHOR_HARVEST_SEC / 60) + " minut.");
}
