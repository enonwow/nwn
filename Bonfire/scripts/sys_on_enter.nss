#include "lib_bfire_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    string sUUID = GetObjectUUID(oPC);
    BfireEnsurePC(sUUID);

    // If the PC has never rested (flasks at default 5), this is effectively
    // their first session — nothing extra needed.
    // Flasks are already seeded via INSERT OR IGNORE in BfireEnsurePC.

    int nFlasks = BfireGetFlasks(sUUID);
    if(nFlasks < BFIRE_MAX_FLASKS)
        SendMessageToPC(oPC,
            "[Ognisko] Masz " + IntToString(nFlasks) + " Flaszek Ocalenia. "
            "Odpocznij przy ognisku, by uzupełnić zapasy.");
}
