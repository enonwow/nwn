#include "x3_inc_string"
#include "lib_app"

json GetHeadEntries(object oPC)
{
    json jEntries = JsonArray();

    string sGender = GetGender(oPC) == 0 ? "m" : "f";

    string ResAliasPrefix = "p" + sGender + GetRaceLetter(oPC)
        + IntToString(GetPhenoType(oPC)) + "_head";

    int i;
    for(i = 1; i <= 255; i++)
    {
        string sModel = ResAliasPrefix + IntToPaddedString(i, 3);
        if(ResManGetAliasFor(sModel, RESTYPE_MDL) != "")
        {
            jEntries = JsonArrayInsert(jEntries, NuiComboEntry(IntToString(i), i));
        }
    }

    return jEntries;
}

void FeedAppHeadWindow(object oPC, int nToken)
{
    int nHairColor = GetColor(oPC, COLOR_CHANNEL_HAIR);
    string sId = IntToString(nHairColor);

    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);

    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    int nHead = GetCreatureBodyPart(CREATURE_PART_HEAD, oPC);
    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nHead));
    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, GetHeadEntries(oPC));
}

void CreateAppHeadWindow(object oPC)
{
    json jSpacer = NuiSpacer();
    json jNextElements = JsonArray();
    jNextElements = JsonArrayInsert(jNextElements, CreateAppItemPicker(
        "Previous head",
        "Next head"));

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_HEAD_WINDOW,
        "Head",
        "cc_color_h_",
        JsonArray(),
        jNextElements,
        640.0,
        "lib_app_head_ev",
        65.0);

    FeedAppHeadWindow(oPC, nToken);

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
}

void AppHeadChangeEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nHead)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);
    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nHead));
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);

    SetCreatureBodyPart(CREATURE_PART_HEAD, nHead, oPCopy);
}

void AppHeadCopy(object oSource, object oTarget)
{
    int nHead = GetCreatureBodyPart(CREATURE_PART_HEAD, oSource);
    SetCreatureBodyPart(CREATURE_PART_HEAD, nHead, oTarget);

    int nHairColor = GetColor(oSource, COLOR_CHANNEL_HAIR);
    SetColor(oTarget, COLOR_CHANNEL_HAIR, nHairColor);
}

void AppHeadEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    object oArea = GetArea(oPC);
    object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(FindSubString(sEventElem, APP_BTN) >= 0)
        {
            int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));
            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_HAIR);
        }
        else if(sEventElem == APP_PREV_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor -= 1;

            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_HAIR);
        }
        else if(sEventElem == APP_NEXT_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor += 1;

            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_HAIR);
        }
        else if(sEventElem == APP_ITEM_PREVIOUS_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
            AppHeadChangeEvents(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            AppHeadChangeEvents(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            AppHeadCopy(oPCopy, oPC);
            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            AppHeadCopy(oPC, oPCopy);
            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_COLOR_TE)
        {
            string sColor = JsonGetString(NuiGetBind(oPC, nToken, APP_COLOR_TE));
            int nColor = StringToInt(sColor);

            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_HAIR);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            AppHeadChangeEvents(oPC, oPCopy, nToken, nModelId);
        }
    }
}
