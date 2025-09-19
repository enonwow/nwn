
#include "nw_inc_gff"

const string NUI_DATA_ENCOURAGED = "NUI_DATA_ENCOURAGED";
const string NUI_DATA_CELL = "NUI_DATA_CELL";
const string NUI_DATA_ROW = "NUI_DATA_ROW";

const string OBSERVABLE = "OBSERVABLE";
const string OBSERVABLE_ID = "OBSERVABLE_ID";

const string NW_THRASHBIN = "NW_THRASHBIN";

string GetIconResref(object oItem, json jItem, int nBaseItem)
{
    if (nBaseItem == BASE_ITEM_CLOAK) // Cloaks use PLTs so their default icon doesn't really work
        return "iit_cloak";
    else if (nBaseItem == BASE_ITEM_SPELLSCROLL || nBaseItem == BASE_ITEM_ENCHANTED_SCROLL)
    {// Scrolls get their icon from the cast spell property
        if (GetItemHasItemProperty(oItem, ITEM_PROPERTY_CAST_SPELL))
        {
            itemproperty ip = GetFirstItemProperty(oItem);
            while (GetIsItemPropertyValid(ip))
            {
                if (GetItemPropertyType(ip) == ITEM_PROPERTY_CAST_SPELL)
                    return Get2DAString("iprp_spells", "Icon", GetItemPropertySubType(ip));

                ip = GetNextItemProperty(oItem);
            }
        }
    }
    else if (Get2DAString("baseitems", "ModelType", nBaseItem) == "0")
    {// Create the icon resref for simple modeltype items
        json jSimpleModel = GffGetByte(jItem, "ModelPart1");
        if (JsonGetType(jSimpleModel) == JSON_TYPE_INTEGER)
        {
            string sSimpleModelId = IntToString(JsonGetInt(jSimpleModel));
            while (GetStringLength(sSimpleModelId) < 3)// Padding...
            {
                sSimpleModelId = "0" + sSimpleModelId;
            }

            string sDefaultIcon = Get2DAString("baseitems", "DefaultIcon", nBaseItem);
            switch (nBaseItem)
            {
                case BASE_ITEM_MISCSMALL:
                case BASE_ITEM_CRAFTMATERIALSML:
                    sDefaultIcon = "iit_smlmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCMEDIUM:
                case BASE_ITEM_CRAFTMATERIALMED:
                case 112:/* Crafting Base Material */
                    sDefaultIcon = "iit_midmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCLARGE:
                    sDefaultIcon = "iit_talmisc_" + sSimpleModelId;
                    break;
                case BASE_ITEM_MISCTHIN:
                    sDefaultIcon = "iit_thnmisc_" + sSimpleModelId;
                    break;
                case 307:
                case 392:
                    sDefaultIcon = "iit_misc_" + sSimpleModelId;
                    break;
            }

            int nLength = GetStringLength(sDefaultIcon);
            if (GetSubString(sDefaultIcon, nLength - 4, 1) == "_")// Some items have a default icon of xx_yyy_001, we strip the last 4 symbols if that is the case
                sDefaultIcon = GetStringLeft(sDefaultIcon, nLength - 4);
            string sIcon = sDefaultIcon + "_" + sSimpleModelId;
            if (ResManGetAliasFor(sIcon, RESTYPE_TGA) != "")// Check if the icon actually exists, if not, we'll fall through and return the default icon
                return sIcon;
        }
    }

    // For everything else use the item's default icon
    return Get2DAString("baseitems", "DefaultIcon", nBaseItem);
}

string GetItemPropertyDescription(itemproperty ip){

    string propName;
    string subType;
    string costValue;
    string paramValue;

    int propId = GetItemPropertyType(ip);
    propName = GetStringByStrRef(StringToInt(Get2DAString("itempropdef", "GameStrRef", propId)));

    string subTypeTable = Get2DAString("itempropdef", "SubTypeResRef", propId);
    if(subTypeTable != ""){
        int subTypeId = GetItemPropertySubType(ip);
        int nStrref = StringToInt(Get2DAString(subTypeTable, "Name", subTypeId));
        if(nStrref > 0)
            subType = GetStringByStrRef(nStrref);
    }
    string costValueTableId = Get2DAString("itempropdef", "CostTableResRef", propId);
    if(costValueTableId != ""){
        string costValueTable = Get2DAString("iprp_costtable", "Name", StringToInt(costValueTableId));
        int costId = GetItemPropertyCostTableValue(ip);
        int nStrref = StringToInt(Get2DAString(costValueTable, "Name", costId));
        if(nStrref > 0)
            costValue = GetStringByStrRef(nStrref);
    }

    string paramTableId = Get2DAString("itempropdef", "Param1ResRef", propId);
    if(paramTableId != ""){
        string paramTable = Get2DAString("iprp_paramtable", "TableResRef", StringToInt(paramTableId));
        int paramId = GetItemPropertyParam1Value(ip);
        int nStrref = StringToInt(Get2DAString(paramTable, "Name", paramId));
        if(nStrref > 0)
            paramValue = GetStringByStrRef(nStrref);
    }
    return propName
        + (subType != ""? " " + subType : "")
        + (costValue != ""? " " + costValue : "")
        + (paramValue != ""? " " + paramValue : "");
}

struct ClassesPC
{
    string FirstClassName;
    string SecondClassName;
    string ThirdClassName;
};

string GetClassFromJson(json jClasses, int nId)
{
    json jClass = JsonArrayGet(jClasses, nId);

    if (JsonGetType(jClass) == JSON_TYPE_NULL)
    {
        return "";
    }

    int iClassIdx = JsonGetInt(GffGetInt(jClass, "Class"));
    return GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", iClassIdx)));
}

struct ClassesPC GetClassesPC(object oPC)
{
    json jPC = ObjectToJson(oPC);

    json jClasses = GffGetList(jPC, "ClassList");

    struct ClassesPC ClassesPC;
    ClassesPC.FirstClassName = GetStringLowerCase(GetClassFromJson(jClasses, 0));
    ClassesPC.SecondClassName = GetStringLowerCase(GetClassFromJson(jClasses, 1));
    ClassesPC.ThirdClassName = GetStringLowerCase(GetClassFromJson(jClasses, 2));

    return ClassesPC;
}

void SetAntyExploitStatus(object oPC)
{
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectCutsceneParalyze(), oPC);
}

void RemoveAntyExploitStatus(object oPC)
{
    effect eLoop = GetFirstEffect(oPC);
    while (GetIsEffectValid(eLoop))
    {
        if (GetEffectType(eLoop) == EFFECT_TYPE_CUTSCENE_PARALYZE)
        {
            RemoveEffect(oPC, eLoop);
        }

        eLoop = GetNextEffect(oPC);
    }
}

void NuiOffEncouragedData(object oPC, int nToken)
{
    json jRow = NuiGetBind(oPC, nToken, NUI_DATA_ROW);
    if (JsonGetType(jRow) != JSON_TYPE_NULL)
    {
        int nRow = JsonGetInt(jRow);

        json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);

        jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(FALSE));

        NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
        NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonArray());
    }
}

void NuiOnEncouragedData(object oPC, int nToken, int nRow)
{
    json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);

    jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(TRUE));

    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
    NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonInt(nRow));
}

void CreateItemOnObjectJson(json jObject, object oTarget, int nStackSize)
{
    int i;
    for (i=0; i<nStackSize; i++)
    {
        JsonToObject(jObject, GetLocation(oTarget), oTarget);        
    }    
}

void CreateItemonObjectLoop(string sItemTemplate, object oTarget, int nStackSize)
{
    int i;
    for (i=0; i<nStackSize; i++)
    {
        CreateItemOnObject(sItemTemplate, oTarget, 1);
    }
}

string NuiGetValueFromCombo(object oPC, int nToken, string sBindName, int nIdx)
{
    json jCombo = NuiGetBind(oPC, nToken, sBindName);
    json jComboObject = JsonArrayGet(jCombo, nIdx);
    json jComboObjectValue = JsonArrayGet(jComboObject, 0);

    return JsonGetString(jComboObjectValue);
}

string IntToPaddedString(int nX, int nLength = 4, int nSigned = FALSE)
{
    if(nSigned)
        nLength--; // To allow for sign
    string sResult = IntToString(nX);
    // Trunctate to nLength rightmost characters
    if(GetStringLength(sResult) > nLength)
        sResult = GetStringRight(sResult, nLength);
    // Pad the left side with zero
    while(GetStringLength(sResult) < nLength)
    {
        sResult = "0" + sResult;
    }
    if(nSigned)
    {
        if(nX >= 0)
            sResult = "+" + sResult;
        else
            sResult = "-" + sResult;
    }
    return sResult;
}

void GetNextPreviousValueFromCombo(
    object oPC, 
    int nToken, 
    string sBindId, 
    string sBindEntries,
    int nMax, 
    int nPlus)
{
    int nId = JsonGetInt(NuiGetBind(oPC, nToken, sBindId)) + nPlus;
    int nLnegth = JsonGetLength(NuiGetBind(oPC, nToken, sBindEntries));

    if(nMax > nLnegth)
    {
        nMax = nLnegth-1;
    }

    if(nId < 0)
    {
        nId = nMax;
    }
    else if(nId > nMax)
    {
        nId = 0;
    }    

    NuiSetBind(oPC, nToken, sBindId, JsonInt(nId));
}

int GetHeight(object oPC)
{
    string s2DA = Get2DAString("appearance", "HEIGHT", GetAppearanceType(oPC));
    float fMod = 0.9;
    float fGender = 1.0;
    float fTransform = GetObjectVisualTransform(oPC, OBJECT_VISUAL_TRANSFORM_SCALE);
    float fHeight;

    if (GetGender(oPC) == GENDER_FEMALE)
        fGender = 0.93;

    fHeight = StringToFloat(s2DA) * fMod * fGender * fTransform;

    return FloatToInt(fHeight * 100);
}

//Daz
json Util_GetModelPart(string sDefaultIcon, string sType, json jPart)
{
    if (JsonGetType(jPart) == JSON_TYPE_INTEGER)
    {
        string sModelPart = IntToString(JsonGetInt(jPart));
        while (GetStringLength(sModelPart) < 3)
        {
            sModelPart = "0" + sModelPart;
        }

        string sIcon = sDefaultIcon + sType + sModelPart;
        if (ResManGetAliasFor(sIcon, RESTYPE_TGA) != "")
            return JsonString(sIcon);
    }

    return JsonString("");
}

json Util_GetComplexIconData(json jItem, int nBaseItem);
json Util_GetComplexIconData(json jItem, int nBaseItem)
{
    if (Get2DAString("baseitems", "ModelType", nBaseItem) == "2")
    {
        string sDefaultIcon = Get2DAString("baseitems", "DefaultIcon", nBaseItem);
        json jComplexIcon = JsonObject();
             jComplexIcon = JsonObjectSet(jComplexIcon, "top", Util_GetModelPart(sDefaultIcon, "_t_", GffGetByte(jItem, "ModelPart3")));
             jComplexIcon = JsonObjectSet(jComplexIcon, "middle", Util_GetModelPart(sDefaultIcon, "_m_", GffGetByte(jItem, "ModelPart2")));
             jComplexIcon = JsonObjectSet(jComplexIcon, "bottom", Util_GetModelPart(sDefaultIcon, "_b_", GffGetByte(jItem, "ModelPart1")));

        return jComplexIcon;
    }

    return JsonNull();
}

string Util_Get2DAStringByStrRef(string s2DA, string sColumn, int nRow);
string Util_Get2DAStringByStrRef(string s2DA, string sColumn, int nRow)
{
    return GetStringByStrRef(StringToInt(Get2DAString(s2DA, sColumn, nRow)));
}

string Util_GetItemName(object oItem, int bIdentified);
string Util_GetItemName(object oItem, int bIdentified)
{
    return bIdentified ? GetName(oItem) : Util_Get2DAStringByStrRef("baseitems", "Name", GetBaseItemType(oItem)) + " (Unidentified)";
}

void Util_SendDebugMessage(string sMessage);
void Util_SendDebugMessage(string sMessage)
{
    object oPlayer = GetFirstPC();
    while (oPlayer != OBJECT_INVALID)
    {
        SendMessageToPC(oPlayer, sMessage);
        oPlayer = GetNextPC();
    }
}