// lib_nui_utility.nss

const string NUI_DATA_ENCOURAGED = "NUI_DATA_ENCOURAGED";
const string NUI_DATA_CELL       = "NUI_DATA_CELL";
const string NUI_DATA_ROW        = "NUI_DATA_ROW";

void NuiOffEncouragedData(object oPC, int nToken)
{
    int nRow = GetLocalInt(oPC, NUI_DATA_ROW + IntToString(nToken));
    if(nRow < 0) return;
    json jEnc = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);
    if(JsonGetType(jEnc) != JSON_TYPE_ARRAY) return;
    jEnc = JsonArraySet(jEnc, nRow, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEnc);
}

void NuiOnEncouragedData(object oPC, int nToken, int nRow)
{
    SetLocalInt(oPC, NUI_DATA_ROW + IntToString(nToken), nRow);
    json jEnc = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);
    if(JsonGetType(jEnc) != JSON_TYPE_ARRAY) return;
    jEnc = JsonArraySet(jEnc, nRow, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEnc);
}

string GetIconResref(object oItem, json jItem, int nBaseItem)
{
    string sIcon = Get2DAString("baseitems", "DefaultIcon", nBaseItem);
    return sIcon;
}

string GetItemPropertyDescription(itemproperty ip)
{
    int nType = GetItemPropertyType(ip);
    return Get2DAString("itempropdef", "Name", nType);
}

struct ClassesPC
{
    string FirstClassName;
    string SecondClassName;
    string ThirdClassName;
};

struct ClassesPC GetClassesPC(object oPC)
{
    struct ClassesPC s;
    int nClass1 = GetClassByPosition(1, oPC);
    int nClass2 = GetClassByPosition(2, oPC);
    int nClass3 = GetClassByPosition(3, oPC);
    if(nClass1 != CLASS_TYPE_INVALID)
        s.FirstClassName  = GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", nClass1)));
    if(nClass2 != CLASS_TYPE_INVALID)
        s.SecondClassName = GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", nClass2)));
    if(nClass3 != CLASS_TYPE_INVALID)
        s.ThirdClassName  = GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", nClass3)));
    return s;
}

string IntToPaddedString(int nX, int nLength = 4, int nSigned = FALSE)
{
    string s = IntToString(nX);
    if(nSigned && nX >= 0) s = "+" + s;
    while(GetStringLength(s) < nLength)
        s = "0" + s;
    return s;
}

void GetNextPreviousValueFromCombo(object oPC, int nToken, string sBindId, string sBindEntries, int nMax, int nPlus)
{
    int nCurrent = JsonGetInt(NuiGetBind(oPC, nToken, sBindId));
    nCurrent += nPlus;
    if(nCurrent < 0)    nCurrent = nMax - 1;
    if(nCurrent >= nMax) nCurrent = 0;
    NuiSetBind(oPC, nToken, sBindId, JsonInt(nCurrent));
}

string Util_Get2DAStringByStrRef(string s2DA, string sColumn, int nRow)
{
    return GetStringByStrRef(StringToInt(Get2DAString(s2DA, sColumn, nRow)));
}

string Util_GetItemName(object oItem, int bIdentified)
{
    if(bIdentified)
        return GetName(oItem);
    return GetStringByStrRef(StringToInt(Get2DAString("baseitems", "Name", GetBaseItemType(oItem))));
}

void Util_SendDebugMessage(string sMessage)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sMessage);
        oPC = GetNextPC();
    }
}
