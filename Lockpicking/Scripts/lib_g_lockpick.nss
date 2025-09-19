#include "nwnx_player"
#include "lib_nui"

const float GOTHIC_LOCKPICK_WINDOW_WIDTH = 1024.0;
const float GOTHIC_LOCKPICK_WINDOW_HEIGHT = 1024.0;

const string GOTHIC_LOCKPICK_WINDOW = "GOTHIC_LOCKPICK_WINDOW";
const string GOTHIC_LOCKPICK_NUI_EVENT_SCRIPT = "lib_g_lockpick_ev";

const string GOTHIC_LOCKPICK_GROUP = "GOTHIC_LOCKPICK_GROUP";

const string GOTHIC_LOCKPICK_IMAGE = "GOTHIC_LOCKPICK_IMAGE";

const string GOTHIC_LOCKPICK_EMPTY_IMAGE = "lockpicke";
const string GOTHIC_LOCKPICK_DEFAULT_IMAGE = "lockpick";
const string GOTHIC_LOCKPICK_IMAGE_R = "lockpickr";
const string GOTHIC_LOCKPICK_IMAGE_L = "lockpickl";

const string GOTHIC_LOCKPICK_FRAME_IMAGE = "GOTHIC_LOCKPICK_FRAME_IMAGE";

const string GOTHIC_LOCKPICK_EMPTY_FRAME_IMAGE = "empty_lc";
const string GOTHIC_LOCKPICK_CORRECT_FRAME_IMAGE = "correct_lc";
const string GOTHIC_LOCKPICK_INCORRECT_FRAME_IMAGE = "incorrect_lc";

const float GOTHIC_LOCKPICK_FRAME_IMAGE_WIDTH = 64.0;
const float GOTHIC_LOCKPICK_FRAME_IMAGE_HEIGHT = 64.0;

const string GOTHIC_LOCKPICK_LOCKED_OBJECT_UUID = "GOTHIC_LOCKPICK_LOCKED_OBJECT_UUID";

const string GOTHIC_LOCKPICK_SEQUENCE = "GOTHIC_LOCKPICK_SEQUENCE";
const string GOTHIC_LOCKPICK_CURRENT_SEQUENCE = "GOTHIC_LOCKPICK_CURRENT_SEQUENCE";

const string GOTHIC_LOCKPICK_DIFFICULTY = "GOTHIC_LOCKPICK_DIFFICULTY";

const string GOTHIC_LOCKPICK_GUARD = "GOTHIC_LOCKPICK_GUARD";

void GothicLockpickObserveLockedObject(object oPC, object oLockedObject)
{
    int nToken = NuiFindWindow(oPC, GOTHIC_LOCKPICK_WINDOW);
    if(nToken <= 0)
    {
        return;
    }

    if(GetDistanceBetween(oPC, oLockedObject) >= 3.0)
    {
        SendMessageToPC(oPC, "You are too far away from the unlocked object.");
        NuiDestroy(oPC, nToken);
        return;
    }

    DelayCommand(1.0, GothicLockpickObserveLockedObject(oPC, oLockedObject));
}

json GothicLockpickBackground(json jImageList)
{
    json jBackground = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("bg2_lc"),
        NuiRect(
            0.0,
            0.0,
            GOTHIC_LOCKPICK_WINDOW_WIDTH,
            GOTHIC_LOCKPICK_WINDOW_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jBackground);

    return jImageList;
}

json GothicLockpickLockImages(json jImageList)
{
    json jBackground = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(GOTHIC_LOCKPICK_IMAGE),
        NuiRect(
            0.0,
            0.0,
            GOTHIC_LOCKPICK_WINDOW_WIDTH,
            GOTHIC_LOCKPICK_WINDOW_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jBackground);

    return jImageList;
}

json GothicLockpickFramesImages(json jImageList, int nDifficulty)
{
    float fSpaceWidth = 20.0;
    float fWidth = nDifficulty * (GOTHIC_LOCKPICK_FRAME_IMAGE_WIDTH + fSpaceWidth);
    float fXPosition = (GOTHIC_LOCKPICK_WINDOW_WIDTH - fWidth) / 2.0;
    float fYPosition = GOTHIC_LOCKPICK_WINDOW_HEIGHT * 0.9;

    int i;
    for(i = 0; i < nDifficulty; i++)
    {
        json jFrame = NuiDrawListImage(
            JsonBool(TRUE),
            NuiBind(GOTHIC_LOCKPICK_FRAME_IMAGE + IntToString(i)),
            NuiRect(
                fXPosition + (fSpaceWidth + GOTHIC_LOCKPICK_FRAME_IMAGE_WIDTH) * i,
                fYPosition,
                GOTHIC_LOCKPICK_FRAME_IMAGE_WIDTH,
                GOTHIC_LOCKPICK_FRAME_IMAGE_HEIGHT),
            JsonInt(NUI_ASPECT_STRETCH),
            JsonInt(NUI_HALIGN_CENTER),
            JsonInt(NUI_VALIGN_MIDDLE),
            NUI_DRAW_LIST_ITEM_ORDER_AFTER,
            NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

        jImageList = JsonArrayInsert(jImageList, jFrame);
    }

    return jImageList;
}

void GothiLockpickRandomSequence(
    object oPC,
    int nToken,
    int nDifficulty)
{
    json jSequence = JsonArray();
    int i;
    for(i = 0; i < nDifficulty; i++)
    {
        jSequence = JsonArrayInsert(jSequence, JsonInt(Random(2)));

        NuiSetBind(oPC, nToken,
            GOTHIC_LOCKPICK_FRAME_IMAGE + IntToString(i), JsonString(GOTHIC_LOCKPICK_EMPTY_FRAME_IMAGE));
    }

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_SEQUENCE, jSequence);
    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_CURRENT_SEQUENCE, JsonInt(0));
}

void GothicLockpickWindowCreate(
    object oPC,
    int nDifficulty,
    object oLockedObject)
{
    float fWindowX = -1.0;
    float fWindowY = -1.0;

    int nToken = NuiFindWindow(oPC, GOTHIC_LOCKPICK_WINDOW);

    if(nToken > 0)
    {
        return;
    }

    json jCol = JsonArray();

    json jImageList = JsonArray();
    jImageList = NuiAddInfoImage(GOTHIC_LOCKPICK_WINDOW_WIDTH, jImageList, 21.0);
    jImageList = GothicLockpickBackground(jImageList);
    jImageList = GothicLockpickLockImages(jImageList);
    jImageList = GothicLockpickFramesImages(jImageList, nDifficulty);

    json jRoot = NuiDrawList(NuiCol(jCol), JsonBool(FALSE), jImageList);
    jRoot = NuiId(jRoot, GOTHIC_LOCKPICK_GROUP);
    jRoot = NuiWidth(jRoot, GOTHIC_LOCKPICK_WINDOW_WIDTH);
    jRoot = NuiHeight(jRoot, GOTHIC_LOCKPICK_WINDOW_HEIGHT);

    json jNui = NuiWindow(
        jRoot,
        JsonNull(),
        NuiRect(
            fWindowX,
            fWindowY,
            GOTHIC_LOCKPICK_WINDOW_WIDTH,
            GOTHIC_LOCKPICK_WINDOW_HEIGHT),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jNui, GOTHIC_LOCKPICK_WINDOW, GOTHIC_LOCKPICK_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_IMAGE, JsonString(GOTHIC_LOCKPICK_EMPTY_IMAGE));

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_DIFFICULTY, JsonInt(nDifficulty));

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_LOCKED_OBJECT_UUID, JsonString(GetObjectUUID(oLockedObject)));

    GothiLockpickRandomSequence(oPC, nToken, nDifficulty);
}

void GothicLockpickClearSequence(
    object oPC,
    int nToken,
    int nDifficulty)
{
    int i;
    for(i = 0; i < nDifficulty; i++)
    {
        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_FRAME_IMAGE + IntToString(i),
            JsonString(GOTHIC_LOCKPICK_EMPTY_FRAME_IMAGE));
    }

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_CURRENT_SEQUENCE, JsonInt(0));
}

void GothicLockpickCheckSequence(
    object oPC,
    int nToken,
    string sSide)
{
    int nDifficulty = JsonGetInt(NuiGetBind(oPC, nToken, GOTHIC_LOCKPICK_DIFFICULTY));
    int nCurrentSequence = JsonGetInt(NuiGetBind(oPC, nToken, GOTHIC_LOCKPICK_CURRENT_SEQUENCE));

    json jSequence = NuiGetBind(oPC, nToken, GOTHIC_LOCKPICK_SEQUENCE);
    int nSequence = JsonGetInt(JsonArrayGet(jSequence, nCurrentSequence));

    if(sSide == "l" && nSequence == 0
        || sSide == "r" && nSequence == 1)
    {
        SendMessageToPC(oPC, "Correct: " + (nSequence ? "Left!" : "Right!"));

        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_FRAME_IMAGE + IntToString(nCurrentSequence),
            JsonString(GOTHIC_LOCKPICK_CORRECT_FRAME_IMAGE));

        nCurrentSequence++;
        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_CURRENT_SEQUENCE, JsonInt(nCurrentSequence));

        NWNX_Player_PlaySound(oPC, "correct_s_lc");
    }
    else
    {
        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_FRAME_IMAGE + IntToString(nCurrentSequence),
            JsonString(GOTHIC_LOCKPICK_INCORRECT_FRAME_IMAGE));

        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_CURRENT_SEQUENCE, JsonInt(0));

        DelayCommand(1.5, GothicLockpickClearSequence(oPC, nToken, nDifficulty));

        SendMessageToPC(oPC, "Wrong!");
        return;
    }

    if(nCurrentSequence == nDifficulty)
    {
        string sObjectUUID = JsonGetString(NuiGetBind(oPC, nToken, GOTHIC_LOCKPICK_LOCKED_OBJECT_UUID));
        object oLockedObject = GetObjectByUUID(sObjectUUID);
        SetLocked(oLockedObject, FALSE);

        SendMessageToPC(oPC, "You have opened the locked object.");
        NuiDestroy(oPC, nToken);
        return;
    }
}

void GothicLockpickChangeImage(object oPC, string sKey)
{
    string sSide = "";

    if(sKey == "A")
    {
        sSide = "r";
    }
    else if(sKey == "D")
    {
        sSide = "l";
    }
    else
    {
        return;
    }

    int nToken = NuiFindWindow(oPC, GOTHIC_LOCKPICK_WINDOW);
    if(nToken <= 0)
    {
        return;
    }

    if(JsonGetInt(NuiGetBind(oPC, nToken, GOTHIC_LOCKPICK_GUARD)))
    {
        SendMessageToPC(oPC, "Slow down!");
        return;
    }

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_IMAGE, JsonString(GOTHIC_LOCKPICK_DEFAULT_IMAGE));

    string sImage = GOTHIC_LOCKPICK_DEFAULT_IMAGE + sSide;
    float fDelay = 0.2;
    int i;
    for(i = 0; i < 6; i++)
    {
        DelayCommand(fDelay,
            NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_IMAGE, JsonString(sImage + IntToString(i))));

        fDelay += 0.2;
    }

    DelayCommand(fDelay,
        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_IMAGE, JsonString(GOTHIC_LOCKPICK_EMPTY_IMAGE)));

    NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_GUARD, JsonBool(TRUE));
    DelayCommand(fDelay,
        NuiSetBind(oPC, nToken, GOTHIC_LOCKPICK_GUARD, JsonBool(FALSE)));

    GothicLockpickCheckSequence(oPC, nToken, sSide);
}
