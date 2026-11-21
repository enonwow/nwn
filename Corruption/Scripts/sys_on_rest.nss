// sys_on_rest.nss  –  Corruption: OnPlayerRest (FINISHED) hook
// Two effects on rest:
//   1. Sanctuary area: resting here cleanses COR_SANCTUARY_REDUCTION points.
//   2. Nightmare: corrupted characters (stage >= FALLEN) may receive a vivid
//      description of their soul's state as a lore moment.

#include "lib_cor"

void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC)) return;
    if(GetLastRestEventType() != REST_EVENTTYPE_REST_FINISHED) return;

    int nCorruption = GetLocalInt(oPC, COR_LVAR_CORRUPTION);
    int nStage      = CorGetStage(nCorruption);

    // Sanctuary bonus
    object oArea = GetArea(oPC);
    if(GetLocalInt(oArea, COR_LVAR_AREA_SANCTUARY))
    {
        if(nCorruption > 0)
        {
            SendMessageToPC(oPC,
                "[Korupcja] Święte miejsce łagodzi ciemność twej duszy.");
            CorReduceCorruption(oPC, COR_SANCTUARY_REDUCTION);
        }
        return;
    }

    // Nightmare messages for corrupted PCs (flavor only, no mechanical effect)
    if(nStage >= COR_STAGE_FALLEN)
    {
        string sNightmare;
        switch(nStage)
        {
            case COR_STAGE_FALLEN:
                sNightmare =
                    "Budzisz się pokryty zimnym potem. Twoje sny były ciemne "
                    "i pełne twarzy, którym wyrządziłeś krzywdę.";
                break;
            case COR_STAGE_CURSED:
                sNightmare =
                    "Sen nie przyniósł ukojenia — widziałeś siebie jako cień, "
                    "bezgłośnie krzyczący w pustce. Coś obserwowało cię z ciemności.";
                break;
            case COR_STAGE_DAMNED:
                sNightmare =
                    "Obudziłeś się z krzykiem, który nie wydostał się z twoich ust. "
                    "Wokół ciebie przez chwilę wisiały sylwetki potępionych. "
                    "Ich twarze były twoją twarzą.";
                break;
        }
        if(sNightmare != "")
            SendMessageToPC(oPC, "[Korupcja] " + sNightmare);
    }
}
