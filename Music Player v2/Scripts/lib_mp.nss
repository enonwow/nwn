#include "lib_nui"
#include "nwnx_player"

const int MP_MUSIC_MAX = 5;

const string MP_MUSIC_NAME = "MP_MUSIC_NAME";
const string MP_MUSIC_DURATION = "MP_MUSIC_DURATION";

const string MP_MOUSEDOWN = "MP_MOUSEDOWN";
const string MP_LENGTH = "MP_LENGTH";

const float MP_CELL_HEIGHT = 50.0;

const string MP_TIME = "MP_TIME";
const string MP_TIME_VALUE = "MP_TIME_VALUE";
const string MP_TIME_TOOLTIP = "MP_TIME_TOOLTIP";

const float BUTTON_WIDTH = 50.0;
const float BUTTON_HEIGHT = 50.0;

const string MP_BUTTON = "MP_BUTTON";

const string MP_BUTTON_PREV = "MP_BUTTON_PREV";

const string MP_BUTTON_IMAGE = "MP_BUTTON_IMAGE";
const string MP_BUTTON_TOOLTIP = "MP_BUTTON_TOOLTIP";

const string MP_BUTTON_NEXT = "MP_BUTTON_NEXT";

const string MP_BUTTON_LOOP = "MP_BUTTON_LOOP";
const string MP_LOOP_VALUE = "MP_LOOP_VALUE";

const string MP_VOLUME = "MP_VOLUME";

const string MP_BUTTON_CLOSE = "MP_BUTTON_CLOSE";

const string MP_WINDOW = "MP_WINDOW";
const string MP_NUI_EVENT_SCRIPT = "lib_mp_event";

const float MP_WINDOW_WIDTH = 600.0;
const float MP_WINDOW_HEIGHT = 600.0;

const string MP_LOCATION_MOUSEDOWN = "MP_LOCATION_MOUSEDOWN";

const string MP_IS_PLAYING = "MP_IS_PLAYING";
const string MP_LIST = "MP_LIST";

string TimeToMMSS(int nDuration);

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

void SetButton(
    object oPC,
    int nToken,
    int bIsPlaying)
{
    if(!bIsPlaying)
    {
        NuiSetBind(oPC, nToken, MP_BUTTON_IMAGE, JsonString("mp_play"));
        NuiSetBind(oPC, nToken, MP_BUTTON_TOOLTIP, JsonString("Play"));
    }
    else
    {
        NuiSetBind(oPC, nToken, MP_BUTTON_IMAGE, JsonString("mp_stop"));
        NuiSetBind(oPC, nToken, MP_BUTTON_TOOLTIP, JsonString("Stop"));
    }

    NuiSetBind(oPC, nToken, MP_IS_PLAYING, JsonBool(bIsPlaying));
}

void SetIsPlaying(
    object oPC,
    int nToken,
    string sMusicName,
    int nLoopValue)
{
    json jMusicList = NuiGetBind(oPC, nToken, MP_LIST);

    json jDuration = JsonObjectGet(jMusicList, sMusicName);
    int nDuration = JsonGetInt(jDuration);

    NuiSetBind(oPC, nToken, MP_TIME_VALUE, JsonInt(nDuration));
    NuiSetBind(oPC, nToken, MP_TIME, JsonInt(0));

    SetButton(oPC, nToken, TRUE);

    if(!nLoopValue)
    {
        DelayCommand(IntToFloat(nDuration), 
            NuiSetBind(oPC, nToken, MP_IS_PLAYING, JsonBool(FALSE)));
    }
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

string HandleMusic(object oPC, int nToken, int nLoopValue)
{
    string sMusicName = GetMusicName(oPC, nToken);

    SetIsPlaying(oPC, nToken, sMusicName, nLoopValue);

    sMusicName = GuardMusicName(sMusicName);

    return sMusicName;
}

void MPWatchTimeForMusic(object oPC, int nToken)
{
    if(!JsonGetInt(NuiGetBind(oPC, nToken, MP_IS_PLAYING)))
    {
        return;
    }

    int nCurrentDuration = JsonGetInt(NuiGetBind(oPC, nToken, MP_TIME));
    nCurrentDuration++;

    int nMaxDuration = JsonGetInt(NuiGetBind(oPC, nToken, MP_TIME_VALUE));

    if(nCurrentDuration > nMaxDuration)
    {
        int bLoopValue = JsonGetInt(NuiGetBind(oPC, nToken, MP_LOOP_VALUE));
        if(bLoopValue)
        {
            nCurrentDuration = 0;
        }
        else
        {
            return;
        }
    }

    NuiSetBind(oPC, nToken, MP_TIME, JsonInt(nCurrentDuration));
    NuiSetBind(oPC, nToken, MP_TIME_TOOLTIP, JsonString(TimeToMMSS(nCurrentDuration)));

    DelayCommand(1.0, MPWatchTimeForMusic(oPC, nToken));
}

void MPPlaySoundOnlyForPlayer(object oPC, int nToken)
{
    int nLoopValue = JsonGetInt(NuiGetBind(oPC, nToken, MP_LOOP_VALUE));
    
    string sMusicName = HandleMusic(oPC, nToken, nLoopValue);

    int nVolume = JsonGetInt(NuiGetBind(oPC, nToken, MP_VOLUME));
    float fVolume = nVolume / 100.0;

    StartAudioStream(
        oPC,
        AUDIOSTREAM_IDENTIFIER_0,
        sMusicName,
        nLoopValue,
        0.0,
        -1.0,
        fVolume);

    MPWatchTimeForMusic(oPC, nToken);
}

void MPStopSoundOnlyForPlayer(object oPC, int nToken)
{
    StopAudioStream(oPC, AUDIOSTREAM_IDENTIFIER_0);

    SetButton(oPC, nToken, FALSE);
}

//prev -1, next 1
void MPChangeMusicForPlayer(object oPC, int nToken, int nMusicIndex)
{
    int nEnventIdx = JsonGetInt(NuiGetBind(oPC, nToken, NUI_DATA_ROW));
    nEnventIdx += nMusicIndex;

    json jMusicList = NuiGetBind(oPC, nToken, MP_LIST);
    int nLength = JsonGetLength(jMusicList);

    if(nEnventIdx < 0)
    {
        nEnventIdx = nLength - 1;
    }
    else if(nEnventIdx >= nLength)
    {
        nEnventIdx = 0;
    }

    NuiOffEncouragedData(oPC, nToken);
    NuiOnEncouragedData(oPC, nToken, nEnventIdx);

    StopAudioStream(oPC, AUDIOSTREAM_IDENTIFIER_0);
    MPPlaySoundOnlyForPlayer(oPC, nToken);

    SetButton(oPC, nToken, TRUE);
}

void MPSetVolumeForPlayer(object oPC, int nToken)
{
    int nVolume = JsonGetInt(NuiGetBind(oPC, nToken, MP_VOLUME));
    float fVolume = nVolume / 100.0;

    SetAudioStreamVolume(oPC, AUDIOSTREAM_IDENTIFIER_0, fVolume);
}

void MPChangeLoopForPlayer(object oPC, int nToken)
{
    int nLoopValue = JsonGetInt(NuiGetBind(oPC, nToken, MP_LOOP_VALUE));
    nLoopValue = !nLoopValue;
    NuiSetBind(oPC, nToken, MP_LOOP_VALUE, JsonInt(nLoopValue));

    int bIsPlaying = JsonGetInt(NuiGetBind(oPC, nToken, MP_IS_PLAYING));
    if(bIsPlaying)
    {
        MPStopSoundOnlyForPlayer(oPC, nToken);
    }
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

json CreateMPTimeSlider()
{
    json jTimeSlider = NuiSlider(
        NuiBind(MP_TIME),
        JsonInt(0),
        NuiBind(MP_TIME_VALUE),
        JsonInt(1));
    jTimeSlider = NuiWidth(jTimeSlider, 500.0);
    jTimeSlider = NuiHeight(jTimeSlider, 40.0);
    jTimeSlider = NuiTooltip(jTimeSlider, NuiBind(MP_TIME_TOOLTIP));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jTimeSlider);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateMPButtons()
{
    json jShuffleButton = NuiButtonImage(JsonString("mp_shuffle"));
    jShuffleButton = NuiWidth(jShuffleButton, BUTTON_WIDTH);
    jShuffleButton = NuiHeight(jShuffleButton, BUTTON_HEIGHT);
    jShuffleButton = NuiEnabled(jShuffleButton, JsonBool(FALSE));

    json jButtonPrev = NuiButtonImage(JsonString("mp_prev"));
    jButtonPrev = NuiId(jButtonPrev, MP_BUTTON_PREV);
    jButtonPrev = NuiWidth(jButtonPrev, BUTTON_WIDTH);
    jButtonPrev = NuiHeight(jButtonPrev, BUTTON_HEIGHT);
    jButtonPrev = NuiTooltip(jButtonPrev, JsonString("Previous"));

    json jButtonPlay = NuiButtonImage(NuiBind(MP_BUTTON_IMAGE));
    jButtonPlay = NuiId(jButtonPlay, MP_BUTTON);
    jButtonPlay = NuiWidth(jButtonPlay, BUTTON_WIDTH);
    jButtonPlay = NuiHeight(jButtonPlay, BUTTON_HEIGHT);
    jButtonPlay = NuiTooltip(jButtonPlay, NuiBind(MP_BUTTON_TOOLTIP));

    json jButtonNext = NuiButtonImage(JsonString("mp_next"));
    jButtonNext = NuiId(jButtonNext, MP_BUTTON_NEXT);
    jButtonNext = NuiWidth(jButtonNext, BUTTON_WIDTH);
    jButtonNext = NuiHeight(jButtonNext, BUTTON_HEIGHT);
    jButtonNext = NuiTooltip(jButtonNext, JsonString("Next"));

    json jButtonLoop = NuiButtonImage(JsonString("mp_loop"));
    jButtonLoop = NuiId(jButtonLoop, MP_BUTTON_LOOP);
    jButtonLoop = NuiWidth(jButtonLoop, BUTTON_WIDTH);
    jButtonLoop = NuiHeight(jButtonLoop, BUTTON_HEIGHT);
    jButtonLoop = NuiEncouraged(jButtonLoop, NuiBind(MP_LOOP_VALUE));
    jButtonLoop = NuiTooltip(jButtonLoop, JsonString("Loop"));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jShuffleButton);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonPrev);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonPlay);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonNext);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonLoop);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateVolumeSlider()
{
    json jLabel = NuiLabel(JsonString("Volume:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = NuiWidth(jLabel, 100.0);
    jLabel = NuiHeight(jLabel, 40.0);

    json jVolumeSlider = NuiSlider(
        NuiBind(MP_VOLUME),
        JsonInt(0),
        JsonInt(100),
        JsonInt(1));
    jVolumeSlider = NuiWidth(jVolumeSlider, 150.0);
    jVolumeSlider = NuiHeight(jVolumeSlider, 40.0);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLabel);
    jRow = JsonArrayInsert(jRow, jVolumeSlider);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateMPCloseButton()
{
    json jButtonClose = NuiButtonImage(JsonString("custom_close_nui"));
    jButtonClose = NuiId(jButtonClose, MP_BUTTON_CLOSE);
    jButtonClose = NuiWidth(jButtonClose, BUTTON_WIDTH);
    jButtonClose = NuiHeight(jButtonClose, BUTTON_HEIGHT);
    jButtonClose = NuiTooltip(jButtonClose, JsonString("Close"));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
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

void CreateMPWindow(object oPC, json jMusicList)
{
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
    jCol = JsonArrayInsert(jCol, CreateMPTimeSlider());
    jCol = JsonArrayInsert(jCol, CreateMPButtons());
    jCol = JsonArrayInsert(jCol, CreateVolumeSlider());
    jCol = JsonArrayInsert(jCol, CreateMPCloseButton());
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

    NuiSetBind(oPC, nToken, MP_LIST, jMusicList);

    NuiSetBind(oPC, nToken, MP_BUTTON_IMAGE, JsonString("mp_play"));
    NuiSetBind(oPC, nToken, MP_BUTTON_TOOLTIP, JsonString("Play"));

    NuiSetBind(oPC, nToken, MP_VOLUME, JsonInt(100));
    NuiSetBindWatch(oPC, nToken, MP_VOLUME, TRUE);

    FeedMPWindow(oPC, nToken, jMusicList);
}
