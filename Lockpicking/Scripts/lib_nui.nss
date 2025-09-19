#include "nw_inc_nui"
#include "lib_nui_utility"

const string LABEL_WINDOW = "LABEL_WINDOW";

const string STATMENT = "STATMENT";

const string GEOMETRY = "GEOMETRY";

const string CLOSE = "CLOSE";
const string ENABLED = "ENABLED";

//Progressbar
const string PROGRESS = "PROGRESS";
const string COLORBAR = "COLORBAR";
const string TOOLTIP = "TOOLTIP";

//Timer
const string TIMER_WINDOW = "TIMER_WINDOW";

const string STARTING_MINUTES = "STARTING MINUTES";
const string MINUTES = "MINUTES";
const string SECONDS = "SECONDS";

//NuiGetEventType - https://nwnlexicon.com/index.php/NuiGetEventType
const string EVENT_TYPE_WATCH = "watch";
const string EVENT_TYPE_OPEN = "open";
const string EVENT_TYPE_CLOSE = "close";
const string EVENT_TYPE_CLICK = "click";
const string EVENT_TYPE_MOUSEUP = "mouseup";
const string EVENT_TYPE_MOUSEDOWN = "mousedown";
const string EVENT_TYPE_MOUSESCROLL = "mousescroll";
const string EVENT_TYPE_RANGE = "range";
const string EVENT_TYPE_FOCUS = "focus";
const string EVENT_TYPE_BLUR = "blur";

const string WINDOW_TITLE = "title";
const string WINDOW_GEOMETRY = "geometry";
const string WINDOW_RESIZABLE = "resizable";
const string WINDOW_COLLAPSED = "collapsed";
const string WINDOW_CLOSABLE = "closable";
const string WINDOW_TRANSPARENT = "transparent";
const string WINDOW_BORDER = "border";

const int EVENT_BUTTON_LEFT = 0;
const int EVENT_BUTTON_MIDDLE = 1;
const int EVENT_BUTTON_RIGHT = 2;

void CreateLabelInfo(object oPlayer, string sStatment, float fTimeToDestroy = 6.0)
{
    float fWindowW = GetStringLength(sStatment) * 8 + 30.0;
    float fWindowH = 50.0;

    float fWindowX = (GetPlayerDeviceProperty(oPlayer, PLAYER_DEVICE_PROPERTY_GUI_WIDTH) / 2.0) - (fWindowW / 2.0);
    float fWindowY = -1.0;

    json jCol = JsonArray();

    json jRow = JsonArray();
    json jLabel = NuiLabel(NuiBind(STATMENT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jRow = JsonArrayInsert(jRow, jLabel);

    jCol = JsonArrayInsert(jCol, NuiRow(jRow));

    json jRoot = NuiCol(jCol);

    json jGeometry = NuiRect(fWindowX ,fWindowY, fWindowW, fWindowH);

    json jWindow = NuiWindow(jRoot, JsonBool(FALSE), jGeometry, JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE), JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPlayer, jWindow, LABEL_WINDOW);

    NuiSetBind(oPlayer, nToken, STATMENT, JsonString(sStatment));

    AssignCommand(oPlayer, DelayCommand(fTimeToDestroy, NuiDestroy(oPlayer, nToken)));
}

//-------------------------------------//
//-------------------------------------//
//------------ Progressbar ------------//
//-------------------------------------//
//-------------------------------------//

/// @brief Stworzenie nui progress baru
///
/// @param oPlayer - Dla kogo tworzymy progressbar
/// @param sWindowId - unikatowa nazwa dla interfejsu. Ka�de okno musi mie� swoj� w�asn� inaczej dojdzie do konflikt�w
/// @param sTitle - tytu�
/// @param nResizable - zmiana rozmiaru okienka - warto�� 0 (FALSE) lub 1 (TRUE)
/// @param nCollapsed - zwini�cia okienka - warto�� 0 (FALSE) lub 1 (TRUE)
/// @param nTransparent - prze�roczysto�� okienka - warto�� 0 (FALSE) lub 1 (TRUE)
/// @param nBorder - obramowanie okienka - warto�� 0 (FALSE) lub 1 (TRUE)
/// @param nAcceptsInput - wy��czenie wszystkich input�w i ich event�w tj. click
///
/// @note po stworzeniu tzeba dostarczy� dane do interfejsu. Nele�y u�y� FeedProgressbarData
int CreateProgrssBar(object oPlayer, string sWindowId, string sTitle, int nResizable, int nCollapsed, int nClosable, int nTransparent, int nBorder, int nAcceptsInput = FALSE);

/// @brief funkcja do zasilenia danych w interfejsie
///
/// @param oPlayer - gracz kt�ry ma aktywne okienko z unikatowym id (sWindowId)
/// @param sWindowId - unikatowa nazwa dla interfejsu. Ka�de okno musi mie� swoj� w�asn� inaczej dojdzie do konflikt�w
/// @param fValue - warto�� pocz�tkowa musi by� z zakresu 0.0 - 1.0
/// @param nRed - nasycenie barw� czerwon�
/// @param nGreen - nasycenie barw� zielon�
/// @param nBlue - nasycenie barw� niebiesk�
/// @param sTooltip - informacja pojawiaj�ca si� po najechaniu myszk� na obiekt
void FeedProgressbarData(object oPlayer, string sWindowId, float fValue, int nRed, int nGreen, int nBlue, string sTooltip);

/// @brief funkcja do zasilenia danych w interfejsie
///
/// @param oPlayer - gracz kt�ry ma aktywne okienko z unikatowym id (sWindowId)
/// @param sWindowId - unikatowa nazwa dla interfejsu. Ka�de okno musi mie� swoj� w�asn� inaczej dojdzie do konflikt�w
/// @param fValue - warto�� pocz�tkowa musi by� z zakresu 0.0 - 1.0
/// @param nRed - nasycenie barw� czerwon�
/// @param nGreen - nasycenie barw� zielon�
/// @param nBlue - nasycenie barw� niebiesk�
void FeedProgressbarValueColor(object oPlayer, string sWindowId, float fValue, int nRed, int nGreen, int nBlue);

/// @brief funkcja do uzupe�nienia warto�ci progress baru
///
/// @param oPlayer - gracz kt�ry ma aktywne okienko z unikatowym id (sWindowId)
/// @param sWindowId - unikatowa nazwa dla interfejsu. Ka�de okno musi mie� swoj� w�asn� inaczej dojdzie do konflikt�w
/// @param fValue - warto�� pocz�tkowa musi by� z zakresu 0.0 - 1.0
void FeedProgressbarValue(object oPlayer, string sWindowId, float fValue);

/// @brief funkcja do zmiany koloru
///
/// @param oPlayer - gracz kt�ry ma aktywne okienko z unikatowym id (sWindowId)
/// @param sWindowId - unikatowa nazwa dla interfejsu. Ka�de okno musi mie� swoj� w�asn� inaczej dojdzie do konflikt�w
/// @param nRed - nasycenie barw� czerwon�
/// @param nGreen - nasycenie barw� zielon�
/// @param nBlue - nasycenie barw� niebiesk�
void FeedProgressbarColor(object oPlayer, string sWindowId, int nRed, int nGreen, int nBlue);

int CreateProgrssBar(
object oPlayer,
string sWindowId,
string sTitle,
int nResizable,
int nCollapsed,
int nClosable,
int nTransparent,
int nBorder,
int nAcceptsInput = FALSE)
{
    //Pozycja progress baru
    float fWindowX = -1.0;
    float fWindowY = -1.0;

    //szeroko�� i wysoko�� ca�ego komponentu
    float iBarHeight = 40.0;
    float iBarWidth  = 140.0;

    //szeroko�� i wysoko�� paska
    float fWindowW = 30 + iBarWidth;
    float fWindowH = 41.0 + iBarHeight;

    //utworzenie elementu progress baru oraz dodanie styli i tooltipa
    json jRow = JsonArray();
    {
        json jProgress = NuiProgress(NuiBind(PROGRESS));
        jProgress = NuiHeight(jProgress, iBarHeight);
        jProgress = NuiWidth(jProgress, iBarWidth);
        jProgress = NuiStyleForegroundColor(jProgress,NuiBind(COLORBAR));
        jProgress = NuiTooltip(jProgress,NuiBind(TOOLTIP));

        //wrapowanie do wiersza (dodanie)
        jRow = JsonArrayInsert(jRow, jProgress);
    }

    //dodanie wszystkich element�w do kolumny
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jRow));

    //koncowy wynik nui
    json jRoot = NuiCol(jCol);

    //Gometria dla ca�ego okienka
    json jGeometry = NuiRect(fWindowX ,fWindowY, fWindowW, fWindowH);

    //stworzenie g��wnego okienka
    //https://nwnlexicon.com/index.php/NuiWindow
    json jWindow;

    if (sTitle == "")
    {
        jWindow = NuiWindow(jRoot, JsonBool(FALSE), NuiBind(GEOMETRY), JsonBool(nResizable), JsonBool(nCollapsed), JsonBool(nClosable), JsonBool(nTransparent), JsonBool(nBorder));
    }
    else
    {
        jWindow = NuiWindow(jRoot, JsonString(sTitle), NuiBind(GEOMETRY), JsonBool(nResizable), JsonBool(nCollapsed), JsonBool(nClosable), JsonBool(nTransparent), JsonBool(nBorder));
    }

    //Stworzenie ca�ego obiektu
    int nToken = NuiCreate(oPlayer, jWindow, sWindowId);

    NuiSetBind(oPlayer, nToken, GEOMETRY, jGeometry);

    return nToken;
}

void FeedProgressbarData(
object oPlayer,
string sWindowId,
float fValue,
int nRed,
int nGreen,
int nBlue,
string sTooltip)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);

    NuiSetBind(oPlayer, nToken, PROGRESS, JsonFloat(fValue));
    NuiSetBind(oPlayer, nToken, COLORBAR, NuiColor(nRed, nGreen, nBlue));
    NuiSetBind(oPlayer, nToken, TOOLTIP, JsonString(sTooltip));
}

void FeedProgressbarValueColor(
object oPlayer,
string sWindowId,
float fValue,
int nRed,
int nGreen,
int nBlue)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);

    NuiSetBind(oPlayer, nToken, PROGRESS, JsonFloat(fValue));
    NuiSetBind(oPlayer, nToken, COLORBAR, NuiColor(nRed, nGreen, nBlue));
}

void FeedProgressbarValue(object oPlayer, string sWindowId, float fValue)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);

    NuiSetBind(oPlayer, nToken, PROGRESS, JsonFloat(fValue));
}

void FeedProgressbarColor(
object oPlayer,
string sWindowId,
int nRed,
int nGreen,
int nBlue)
{
    int nToken = NuiFindWindow(oPlayer, sWindowId);

    NuiSetBind(oPlayer, nToken, COLORBAR, NuiColor(nRed, nGreen, nBlue));
}


//-------------------------------------//
//-------------------------------------//
//--------------- Timer ---------------//
//-------------------------------------//
//-------------------------------------//
void CreateTimer(object oPC)
{
    float fWindowX = -1.0;
    float fWindowY = -1.0;

    float fWindowW = 130.0;
    float fWindowH = 75.0;

    json jCol = JsonArray();

    json jRow = JsonArray();
    {
        json jLabelMinutes = NuiLabel(
            NuiBind(MINUTES),
            JsonInt(NUI_HALIGN_CENTER),
            JsonInt(NUI_VALIGN_TOP));
        jLabelMinutes = NuiWidth(jLabelMinutes, 40.0);
        jLabelMinutes = NuiHeight(jLabelMinutes, 25.0);

        json jLabelTimer = NuiLabel(
            JsonString(":"),
            JsonInt(NUI_HALIGN_CENTER),
            JsonInt(NUI_VALIGN_TOP));
        jLabelTimer = NuiWidth(jLabelTimer, 5.0);

        json jLabelSeconds = NuiLabel(
            NuiBind(SECONDS),
            JsonInt(NUI_HALIGN_CENTER),
            JsonInt(NUI_VALIGN_TOP));
        jLabelSeconds = NuiWidth(jLabelSeconds, 40.0);

        json jSpacer = NuiSpacer();
        jSpacer = NuiWidth(jSpacer, 10.0);

        jRow = JsonArrayInsert(jRow, jSpacer);
        jRow = JsonArrayInsert(jRow, jLabelMinutes);
        jRow = JsonArrayInsert(jRow, jLabelTimer);
        jRow = JsonArrayInsert(jRow, jLabelSeconds);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(
        jRoot,
        JsonString("Czas"),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, TIMER_WINDOW);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(fWindowX, fWindowY, fWindowW, fWindowH));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_COLLAPSED, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(TRUE));

    NuiSetBind(oPC, nToken, MINUTES, JsonString("00"));
    NuiSetBind(oPC, nToken, SECONDS, JsonString("00"));
}

void DecreaseTimer(
    object oPlayer,
    int nToken,
    int nMinutes,
    int nSeconds,
    int nTick = 0)
{
    if (nTick == 6)
    {
        return;
    }

    if (nSeconds == -1)
    {
        --nMinutes;
        nSeconds = 59;
    }

    NuiSetBind(oPlayer, nToken, MINUTES, JsonString(IntToString(nMinutes)));
    NuiSetBind(oPlayer, nToken, SECONDS, JsonString(IntToString(nSeconds)));

    DelayCommand(1.0, DecreaseTimer(oPlayer, nToken, nMinutes, --nSeconds, ++nTick));
}

void FeedTimerWindow(object oPC, int nMinutes, int nSeconds)
{
    int nToken = NuiFindWindow(oPC, TIMER_WINDOW);

    DecreaseTimer(oPC, nToken, nMinutes, nSeconds);
}

void SendMessageToAllInAreaPCLabelInfo(object oArea, string sStatment, int bInfoLabel)
{
    object oPC = GetFirstPC();
    string sAreaResRef = GetResRef(oArea);

    while (GetIsObjectValid(oPC))
    {
        if (GetResRef(GetArea(oPC)) == sAreaResRef)
        {
            if(bInfoLabel)
            {
                CreateLabelInfo(oPC, sStatment, 3.0);
            }

            SendMessageToPC(oPC, sStatment);
        }

        oPC = GetNextPC();
    }
}

json GetNuiColorNwnGold()
{
    return NuiColor(185, 150, 100);
}

//-------------------------------------//
//-------------------------------------//
//--------------- INFO ----------------//
//-------------------------------------//
//-------------------------------------//
const string NUI_INFO_BUTTON_ID = "NUI_INFO_BUTTON_ID";

const string NUI_INFO_IMAGE = "information64";
const float NUI_INFO_IMAGE_WIDTH = 64.0;
const float NUI_INFO_IMAGE_HEIGHT = 64.0;

json NuiAddInfoRow()
{
    float fButtonWidth = NUI_INFO_IMAGE_WIDTH - 30.0;
    float fButtonHeight = NUI_INFO_IMAGE_HEIGHT - 15.0;

    json jRow = JsonArray();

    json jButton = NuiId(NuiButton(JsonString("")), NUI_INFO_BUTTON_ID);
    jButton = NuiWidth(jButton, fButtonWidth);
    jButton = NuiHeight(jButton, fButtonHeight);
    jButton = NuiTooltip(jButton, JsonString("Naciśnij by otrzymać wiecej informacji."));

    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fButtonWidth));
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 15.0));

    return NuiRow(jRow);
}

json NuiAddInfoImage(
    float fWindowWidth,
    json jImageList,
    float nImageWidthOffset)
{
    json jImageInfo = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(NUI_INFO_IMAGE),
        NuiRect(
            fWindowWidth - (NUI_INFO_IMAGE_WIDTH + nImageWidthOffset),
            0.0,
            NUI_INFO_IMAGE_WIDTH,
            NUI_INFO_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImageInfo);

    return jImageList;
}

const string NUI_INFO_WINDOW = "NUI_INFO_WINDOW";
const string NUI_INFO_NUI_EVENT_SCRIPT = "lib_nui_ev";

void CreateWindowInfo(object oPC, string sStatment)
{
    float fWindowX = -1.0;
    float fWindowY = -1.0;

    float fWindowW = 500.0;
    float fWindowH = 400.0;

    json jCol = JsonArray();
    json jRow = JsonArray();
    {
        json jText = NuiText(JsonString(sStatment));
        jText = NuiWidth(jText, fWindowW - 25);
        jText = NuiHeight(jText, fWindowH - 110);

        jRow = JsonArrayInsert(jRow, jText);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jRow = JsonArray();
    {
        json jSpacer = NuiSpacer();
        json jButton = NuiId(NuiButton(JsonString("Zamknij")), CLOSE);

        jRow = JsonArrayInsert(jRow, jSpacer);
        jRow = JsonArrayInsert(jRow, jButton);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(
        jRoot,
        JsonString("Informacje"),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, NUI_INFO_WINDOW, NUI_INFO_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(fWindowX, fWindowY, fWindowW, fWindowH));
}

const string NUI_INFO_MODAL_WINDOW = "NUI_INFO_MODAL_WINDOW";
const string NUI_INFO_MODAL_OBJECT_UUID = "NUI_INFO_MODAL_OBJECT_UUID";
const string NUI_INFO_MODAL_INT = "NUI_INFO_MODAL_INT";
const string NUI_INFO_MODAL_OBJECTS = "NUI_INFO_MODAL_OBJECTS";

void CreateModalWindowInfo(
    object oPC,
    string sStatment,
    string sBtnId)
{
    float fWindowX = -1.0;
    float fWindowY = -1.0;

    float fWindowW = 500.0;
    float fWindowH = 400.0;

    json jCol = JsonArray();
    json jRow = JsonArray();
    {
        json jText = NuiText(JsonString(sStatment));
        jText = NuiWidth(jText, fWindowW - 25);
        jText = NuiHeight(jText, fWindowH - 110);

        jRow = JsonArrayInsert(jRow, jText);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jRow = JsonArray();
    {
        json jSpacer = NuiSpacer();
        json jButton = NuiId(NuiButton(JsonString("Akceptuj")), sBtnId);
        json jButtonClose = NuiId(NuiButton(JsonString("Zamknij")), CLOSE);

        jRow = JsonArrayInsert(jRow, jSpacer);
        jRow = JsonArrayInsert(jRow, jButton);
        jRow = JsonArrayInsert(jRow, jSpacer);
        jRow = JsonArrayInsert(jRow, jButtonClose);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(
        jRoot,
        JsonString("Informacje"),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, NUI_INFO_MODAL_WINDOW, NUI_INFO_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(fWindowX, fWindowY, fWindowW, fWindowH));
}

void ModalWindowInfoSaveObjectUUID(object oPC, string sUuid)
{
    int nToken = NuiFindWindow(oPC, NUI_INFO_MODAL_WINDOW);
    if (nToken == -1)
    {
        return;
    }

    NuiSetBind(oPC, nToken, NUI_INFO_MODAL_OBJECT_UUID, JsonString(sUuid));
}

void ModalWindowInfoSaveInt(object oPC, int nInt)
{
    int nToken = NuiFindWindow(oPC, NUI_INFO_MODAL_WINDOW);
    if (nToken == -1)
    {
        return;
    }

    NuiSetBind(oPC, nToken, NUI_INFO_MODAL_INT, JsonInt(nInt));
}

void ModalWindowInfoSaveObjects(object oPC, json jObjects)
{
    int nToken = NuiFindWindow(oPC, NUI_INFO_MODAL_WINDOW);
    if (nToken == -1)
    {
        return;
    }

    NuiSetBind(oPC, nToken, NUI_INFO_MODAL_OBJECTS, jObjects);
}
