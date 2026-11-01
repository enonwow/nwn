#include "sql_phy"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    int bActive  = JsonGetInt(JsonObjectGet(jRec, "is_active"));
    int nCharges = JsonGetInt(JsonObjectGet(jRec, "charges"));
    string sArea = JsonGetString(JsonObjectGet(jRec, "anchor_area_name"));

    if(!bActive)
    {
        SendMessageToPC(oPC,
            "[Filakteria] Twoje naczynie duszy jest rozbite. Odtwórz je, by uzyskać ochronę.");
        return;
    }

    if(sArea == "")
    {
        SendMessageToPC(oPC,
            "[Filakteria] Filakteria aktywna, ale niezakotwiczona. Zakotwicz ją, by korzystać ze zmartwychwstania.");
        return;
    }

    if(nCharges <= 1)
    {
        string sMsg = "[Filakteria] Ostrzeżenie — pozostał tylko " + IntToString(nCharges)
                      + " ładunek. Zakotwiczenie: " + sArea + ".";
        SendMessageToPC(oPC, sMsg);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    }
    else
    {
        SendMessageToPC(oPC,
            "[Filakteria] Aktywna (" + IntToString(nCharges) + " ładunków). Zakotwiczenie: " + sArea + ".");
    }
}
