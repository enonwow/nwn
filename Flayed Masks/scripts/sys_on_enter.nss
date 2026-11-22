#include "lib_fmask"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Restore worn mask state after relog
    json jWorn = FmaskGetWornEntry(oPC);
    if(JsonGetType(jWorn) == JSON_TYPE_NULL) return;

    int nMaskId = JsonGetInt(JsonObjectGet(jWorn, "mask_id"));
    string sOrigJson = JsonGetString(JsonObjectGet(jWorn, "original_json"));

    json jMask = FmaskGetMask(nMaskId);
    if(JsonGetType(jMask) == JSON_TYPE_NULL)
    {
        // Mask was consumed while offline — clear state and restore original appearance
        if(sOrigJson != "")
        {
            json jOrig = JsonParse(sOrigJson);
            if(JsonGetType(jOrig) == JSON_TYPE_OBJECT)
                FmaskApplyAppearance(oPC, jOrig);
        }
        FmaskClearWorn(oPC);
        return;
    }

    // Re-apply appearance and bonus
    int nApp   = JsonGetInt(JsonObjectGet(jMask, "appearance"));
    int nPhen  = JsonGetInt(JsonObjectGet(jMask, "phenotype"));
    int nCSkin = JsonGetInt(JsonObjectGet(jMask, "color_skin"));
    int nCHair = JsonGetInt(JsonObjectGet(jMask, "color_hair"));
    int nCTat1 = JsonGetInt(JsonObjectGet(jMask, "color_tattoo1"));
    int nCTat2 = JsonGetInt(JsonObjectGet(jMask, "color_tattoo2"));

    string sPartsJson = JsonGetString(JsonObjectGet(jMask, "parts_json"));
    json jParts = JsonParse(sPartsJson);

    SetAppearanceType(oPC, nApp);
    SetPhenoType(nPhen, oPC);
    SetColor(oPC, COLOR_CHANNEL_SKIN,    nCSkin);
    SetColor(oPC, COLOR_CHANNEL_HAIR,    nCHair);
    SetColor(oPC, COLOR_CHANNEL_TATTOO1, nCTat1);
    SetColor(oPC, COLOR_CHANNEL_TATTOO2, nCTat2);

    if(JsonGetType(jParts) == JSON_TYPE_OBJECT)
        FmaskApplyAppearance(oPC, jParts);

    int nRace = JsonGetInt(JsonObjectGet(jMask, "racial_type"));
    FmaskApplyBonus(oPC, nRace);

    SetLocalInt   (oPC, FMASK_LVAR_WORN_ID,   nMaskId);
    SetLocalString(oPC, FMASK_LVAR_ORIG_JSON,  sOrigJson);

    int bCursed = JsonGetInt(JsonObjectGet(jMask, "is_cursed"));
    string sName = JsonGetString(JsonObjectGet(jMask, "creature_name"));

    SendMessageToPC(oPC, "[Zdarty Oblicze] Nadal nosisz maskę: " + sName + ".");

    if(bCursed)
        DelayCommand(30.0, FmaskScheduleWhisper(oPC));
}
