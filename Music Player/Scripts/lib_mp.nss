#include "lib_nui"
#include "nwnx_player"

const int MP_MUSIC_MAX = 5;

const string MP_MUSIC_NAME = "MP_MUSIC_NAME";
const string MP_MUSIC_DURATION = "MP_MUSIC_DURATION";

const string MP_MOUSEDOWN = "MP_MOUSEDOWN";
const string MP_LENGTH = "MP_LENGTH";

const float MP_CELL_HEIGHT = 50.0;

const string MP_BUTTON_PLAY = "MP_BUTTON_PLAY";
const string MP_BUTTON_PLAY_ENABLED = "MP_BUTTON_PLAY_ENABLED";

const string MP_BUTTON_CLOSE = "MP_BUTTON_CLOSE";

const string MP_WINDOW = "MP_WINDOW";
const string MP_NUI_EVENT_SCRIPT = "lib_mp_event";

const float MP_WINDOW_WIDTH = 500.0;
const float MP_WINDOW_HEIGHT = 500.0;

const string MP_LOCATION_MOUSEDOWN = "MP_LOCATION_MOUSEDOWN";

const string MP_NWNX_PLAY_MUSIC = "MP_NWNX_PLAY_MUSIC";

const string MP_IS_PLAYING = "MP_IS_PLAYING";
const string MP_MUSIC_SOURCE = "MP_MUSIC_SOURCE";
const string MP_LIST = "MP_LIST";

json MPCreateList()
{
    return JsonObject();
}

json MPCreateEntry(
    json jMusicList,
    string sMusicName,
    int nDuration)
{
    jMusicList = JsonObjectSet(jMusicList, sMusicName, JsonInt(nDuration));

    return jMusicList;
}

void SetIsPlaying(
    object oPC,
    int nToken,
    string sMusicName)
{
    string sMusicSource = JsonGetString(NuiGetBind(oPC, nToken, MP_MUSIC_SOURCE));
    object oMusicSource = GetObjectByUUID(sMusicSource);

    json jMusicList = NuiGetBind(oPC, nToken, MP_LIST);

    json jDuration = JsonObjectGet(jMusicList, sMusicName);
    int nDuration = JsonGetInt(jDuration);

    SendMessageToPC(oPC, "Playing music: " + sMusicName + " for " + IntToString(nDuration) + " seconds");

    SetLocalInt(oMusicSource, MP_IS_PLAYING, TRUE);
    DelayCommand(IntToFloat(nDuration), SetLocalInt(oMusicSource, MP_IS_PLAYING, FALSE));
}

string GuardMusicName(string sMusicName)
{
    if(GetStringLength(sMusicName) > 16)
    {
        sMusicName = GetStringLeft(sMusicName, 16);
    }

    return sMusicName;
}

string GetMusicName(object oPC, int nToken)
{
    int nRow = JsonGetInt(NuiGetBind(oPC, nToken, NUI_DATA_ROW));

    return JsonGetString(
        JsonArrayGet(NuiGetBind(oPC, nToken, MP_MUSIC_NAME), nRow));;
}

string HandleMusic(object oPC, int nToken)
{
    string sMusicName = GetMusicName(oPC, nToken);

    SetIsPlaying(oPC, nToken, sMusicName);

    sMusicName = GuardMusicName(sMusicName);

    return sMusicName;
}

void MPPlaySoundOnlyForPlayer(object oPC, int nToken)
{
    int bNWNX = JsonGetInt(NuiGetBind(oPC, nToken, MP_NWNX_PLAY_MUSIC));

    string sMusicName = HandleMusic(oPC, nToken);

    if(bNWNX)
    {
        NWNX_Player_PlaySound(oPC, sMusicName, oPC);
    }
    else
    {
        //Allways play sound for all players
        AssignCommand(oPC, PlaySound(sMusicName));
    }

    NuiDestroy(oPC, nToken);
}

void MPPlay(object oPC, int nToken)
{
    int bNWNX = JsonGetInt(NuiGetBind(oPC, nToken, MP_NWNX_PLAY_MUSIC));

    string sMusicName = HandleMusic(oPC, nToken);

    if(bNWNX)
    {
        NWNX_Player_PlaySound(oPC, sMusicName);
    }
    else
    {
        //Allways play sound for all players
        AssignCommand(oPC, PlaySound(sMusicName));
    }

    NuiDestroy(oPC, nToken);
}

//--------------------------------//
//--------------------------------//
//------------- NUI --------------//
//--------------------------------//
//--------------------------------//
json CreateMPSpace(float fWidth = 0.0)
{
    json jSpacer = NuiSpacer();

    if(fWidth > 0.0)
    {
        jSpacer = NuiHeight(jSpacer, fWidth);
    }

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateMPLabelsForList()
{
    float fLabelWidth = 60.0;

    json jLocationName = NuiLabel(
        JsonString("Name"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLocationName = NuiWidth(jLocationName, fLabelWidth);

    json jLocationCooldown = NuiLabel(
        JsonString("Duration"),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLocationCooldown = NuiWidth(jLocationCooldown, fLabelWidth);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLocationName);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLocationCooldown);
    jRow = JsonArrayInsert(jRow, jSpacer);

    jRow = NuiRow(jRow);
    jRow = NuiHeight(jRow, 30.0);

    return jRow;
}

json CreateMPList()
{
    json jSpacer = NuiSpacer();

    json jLocationName = NuiLabel(
        NuiBind(MP_MUSIC_NAME),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLocationName = NuiTooltip(jLocationName, NuiBind(MP_MUSIC_NAME));

    json jLocationCooldown = NuiLabel(
        NuiBind(MP_MUSIC_DURATION),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLocationCooldown = NuiWidth(jLocationCooldown, 60.0);

    json jElements = JsonArray();
    jElements = JsonArrayInsert(jElements, jLocationName);
    jElements = JsonArrayInsert(jElements, jLocationCooldown);

    json jGroupCell = NuiGroup(NuiRow(jElements), TRUE, NUI_SCROLLBARS_NONE);
    jGroupCell = NuiEncouraged(jGroupCell, NuiBind(NUI_DATA_ENCOURAGED));
    jGroupCell = NuiId(jGroupCell, MP_MOUSEDOWN);

    json jCell = NuiListTemplateCell(jGroupCell, 0.0, TRUE);

    json jTamplate = JsonArray();
    jTamplate = JsonArrayInsert(jTamplate, jCell);

    json jList = NuiList(jTamplate, NuiBind(MP_LENGTH), MP_CELL_HEIGHT, FALSE, NUI_SCROLLBARS_AUTO);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 20.0));
    jRow = JsonArrayInsert(jRow, jList);
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 20.0));

    jRow = NuiRow(jRow);
    jRow = NuiHeight(jRow, (MP_CELL_HEIGHT + 5.0) * MP_MUSIC_MAX);

    return jRow;
}

json CreateMPButtons()
{
    float fButtonWidth = 50.0;
    float fButtonHeight = 50.0;

    json jButtonPlay = NuiButtonImage(JsonString("mp_play"));
    jButtonPlay = NuiId(jButtonPlay, MP_BUTTON_PLAY);
    jButtonPlay = NuiEnabled(jButtonPlay, NuiBind(MP_BUTTON_PLAY_ENABLED));
    jButtonPlay = NuiWidth(jButtonPlay, fButtonWidth);
    jButtonPlay = NuiHeight(jButtonPlay, fButtonHeight);
    jButtonPlay = NuiTooltip(jButtonPlay, JsonString("Play"));

    json jButtonClose = NuiButtonImage(JsonString("custom_close_nui"));
    jButtonClose = NuiId(jButtonClose, MP_BUTTON_CLOSE);
    jButtonClose = NuiWidth(jButtonClose, fButtonWidth);
    jButtonClose = NuiHeight(jButtonClose, fButtonHeight);
    jButtonClose = NuiTooltip(jButtonClose, JsonString("Close"));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonPlay);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonClose);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json AddBackgroundImage(
    json jImageList,
    string sImage,
    float fWindowWidth,
    float fWindowHeight)
{
    json jBackground = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(sImage),
        NuiRect(0.0, 0.0, fWindowWidth, fWindowHeight),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jBackground);

    return jImageList;
}

string TimeToMMSS(int nDuration)
{
    int nMinutes = nDuration / 60;
    int nSeconds = nDuration % 60;
    return IntToString(nMinutes) + ":" + IntToString(nSeconds);
}

void FeedMPWindow(
    object oPC,
    int nToken,
    json jMusicList)
{
    json jKeys =  JsonObjectKeys(jMusicList);
    int nKeysCount = JsonGetLength(jKeys);

    json jNames = JsonArray();
    json jDurations = JsonArray();
    json jEncouraged = JsonArray();

    if(nKeysCount > 0)
    {
        int i;
        for(i = 0; i <= nKeysCount; i++)
        {
            string sMusicName = JsonGetString(JsonArrayGet(jKeys, i));

            json jMusicDuration = JsonObjectGet(jMusicList, sMusicName);
            int nDuration = JsonGetInt(jMusicDuration);

            string sDuration = TimeToMMSS(nDuration);

            jNames = JsonArrayInsert(jNames, JsonString(sMusicName));
            jDurations = JsonArrayInsert(jDurations, JsonString(sDuration));
            jEncouraged = JsonArrayInsert(jEncouraged, JsonBool(FALSE));
        }
    }

    NuiSetBind(oPC, nToken, MP_LENGTH, JsonInt(nKeysCount));

    NuiSetBind(oPC, nToken, MP_MUSIC_NAME, jNames);
    NuiSetBind(oPC, nToken, MP_MUSIC_DURATION, jDurations);
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
}

void CreateMPWindow(
    object oPC,
    object oMusicSource,
    json jMusicList,
    int bNWNX = FALSE)
{
    if(GetLocalInt(oMusicSource, MP_IS_PLAYING))
    {
        SendMessageToPC(oPC, "Music is already playing");
        return;
    }

    int nToken = NuiFindWindow(oPC, MP_WINDOW);
    if(nToken != 0)
    {
        return;
    }

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateMPSpace(30.0));
    jCol = JsonArrayInsert(jCol, CreateMPLabelsForList());
    jCol = JsonArrayInsert(jCol, CreateMPList());
    jCol = JsonArrayInsert(jCol, CreateMPSpace());
    jCol = JsonArrayInsert(jCol, CreateMPButtons());
    jCol = JsonArrayInsert(jCol, CreateMPSpace(30.0));

    json jImageList = JsonArray();
    jImageList = AddBackgroundImage(jImageList, "mp_background", MP_WINDOW_WIDTH, MP_WINDOW_HEIGHT);

    json jRoot = NuiDrawList(NuiCol(jCol), JsonBool(FALSE), jImageList);

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(FALSE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, MP_WINDOW, MP_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, MP_WINDOW_WIDTH, MP_WINDOW_HEIGHT));
    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    NuiSetBind(oPC, nToken, MP_NWNX_PLAY_MUSIC, JsonBool(bNWNX));
    NuiSetBind(oPC, nToken, MP_LIST, jMusicList);
    NuiSetBind(oPC, nToken, MP_MUSIC_SOURCE, JsonString(GetObjectUUID(oMusicSource)));

    FeedMPWindow(oPC, nToken, jMusicList);
}
