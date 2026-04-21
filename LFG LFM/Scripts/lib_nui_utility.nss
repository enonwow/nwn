// lib_nui_utility.nss
// NUI utility functions (demo module version)

#include "nw_inc_gff"

const string NUI_DATA_ENCOURAGED = "NUI_DATA_ENCOURAGED";
const string NUI_DATA_CELL       = "NUI_DATA_CELL";
const string NUI_DATA_ROW        = "NUI_DATA_ROW";

// Clears the currently encouraged row in a list
void NuiOffEncouragedData(object oPC, int nToken)
{
    json jRow = NuiGetBind(oPC, nToken, NUI_DATA_ROW);
    if(JsonGetType(jRow) != JSON_TYPE_NULL)
    {
        int nRow = JsonGetInt(jRow);
        json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);
        jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
        NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonNull());
    }
}

// Sets the encouraged row in a list
void NuiOnEncouragedData(object oPC, int nToken, int nRow)
{
    json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);
    jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
    NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonInt(nRow));
}
