#include "lib_mia"

// OnUsed script for a test Placeable.
// - PC uses it: injects 30 exposure points into themselves (simulates entering a tainted zone).
// - DM uses it: opens the management panel.
// Place a Placeable with this script in your module for QA purposes.
void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsPC(oUser)) return;

    if(GetIsDM(oUser))
    {
        MiaCreateDmPanel(oUser);
        return;
    }

    // Quick demo: mark the current area as level-5 Necrotic, inject starter exposure
    string sTag = GetTag(GetArea(oUser));
    MiaSetArea(sTag, 5, MIA_TYPE_NECROTIC);

    int nExposure = GetLocalInt(oUser, MIA_LVAR_EXPOSURE) + 30;
    if(nExposure > MIA_MAX_EXPOSURE) nExposure = MIA_MAX_EXPOSURE;
    SetLocalInt(oUser, MIA_LVAR_EXPOSURE, nExposure);
    SetLocalInt(oUser, MIA_LVAR_TYPE,     MIA_TYPE_NECROTIC);

    MiaShowGauge(oUser);
    MiaStartTick(oUser);

    SendMessageToPC(oUser, "[Opar - test] Obszar zatruto (Nekrotyczny, poz. 5). "
        + "Ekspozycja: " + IntToString(nExposure) + "/"
        + IntToString(MIA_MAX_EXPOSURE)
        + ". Użyj ponownie jako MG, by otworzyć panel zarządzania.");
}
