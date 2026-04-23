#include "lib_sm"

const string SM_WIN_BAR     = "sm_bar";
const string SM_BAR_BTN_PFX = "sm_bar_b_"; // 9 chars

void CreateSmBarWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, SM_WIN_BAR);
    if(nExisting > 0) { NuiDestroy(oPC, nExisting); return; }

    json jAll  = SmLoadAll(oPC);
    int  nCount = JsonGetLength(jAll);
    float fBtn  = SmScale(oPC, 40.0);

    json jRow = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jEntry  = JsonArrayGet(jAll, i);
        string sIcon   = JsonGetString(JsonObjectGet(jEntry, "icon"));
        string sName   = JsonGetString(JsonObjectGet(jEntry, "name"));
        int    nSeqIdx = JsonGetInt(JsonObjectGet(jEntry, "idx"));
        if(sIcon == "") sIcon = SM_ICO_DEFAULT;

        json jBtn = NuiButtonImage(JsonString(sIcon));
        jBtn = NuiWidth(jBtn,   fBtn);
        jBtn = NuiHeight(jBtn,  fBtn);
        jBtn = NuiId(jBtn,      SM_BAR_BTN_PFX + IntToString(nSeqIdx));
        jBtn = NuiTooltip(jBtn, JsonString(sName));

        jRow = JsonArrayInsert(jRow, jBtn);
    }

    float fW = SmScale(oPC, 500.0);
    float fH = SmScale(oPC, 114.0);

    json jGroup = NuiGroup(NuiRow(jRow), FALSE, NUI_SCROLLBARS_X);
    jGroup = NuiHeight(jGroup, SmScale(oPC, 62.0));

    json jWrap = JsonArray();
    jWrap = JsonArrayInsert(jWrap, jGroup);

    json jWin = NuiWindow(NuiCol(jWrap), JsonString("Spell Bar"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, SM_WIN_BAR, "lib_sm_bar_ev");
}
