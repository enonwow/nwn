#include "lib_por"

// ----------------------------------------------------------------
// Helper: handle a click on a gallery list row
// ----------------------------------------------------------------

void PorHandleRowClick(object oPC, int nToken, int nIdx)
{
    json jAll = PorGetAll();
    if(nIdx < 0 || nIdx >= JsonGetLength(jAll)) return;

    json jRow = JsonArrayGet(jAll, nIdx);
    int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));
    SetLocalInt(oPC, POR_LVAR_SEL_ID, nId);

    // Highlight selected row
    int nCount = JsonGetLength(jAll);
    json jEncs = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
        jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
    NuiSetBind(oPC, nToken, POR_BIND_ROW_ENC, jEncs);

    FeedPortraitDetail(oPC, nToken, nId);
}

// ----------------------------------------------------------------
// Helper: commission a new portrait for the PC
// ----------------------------------------------------------------

void PorHandleCommission(object oPC, int nToken)
{
    if(PorHasPortrait(oPC))
    {
        SendMessageToPC(oPC, "[Portret] Posiadasz juz portret w galerii.");
        SwapToGalleryView(oPC, nToken);
        return;
    }
    if(GetGold(oPC) < POR_COMMISSION_COST)
    {
        SendMessageToPC(oPC, "[Portret] Nie masz wystarczajaco zlota ("
            + IntToString(POR_COMMISSION_COST) + " sz. wymagane).");
        SwapToGalleryView(oPC, nToken);
        return;
    }

    string sMotto = JsonGetString(NuiGetBind(oPC, nToken, POR_BIND_COM_MOTTO));
    if(GetStringLength(sMotto) > 120) sMotto = GetStringLeft(sMotto, 120);

    string sCls   = PorGetClassName(GetClassByPosition(1, oPC));
    string sAlign = PorGetAlignStr(oPC);

    AssignCommand(oPC, TakeGoldFromCreature(POR_COMMISSION_COST, oPC, TRUE));
    PorCreatePortrait(oPC, sCls, sAlign, sMotto);

    FloatingTextStringOnCreature(
        "Twoj portret zostal umieszczony w galerii.", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Portret] Portret namalowany. Pieniadze zostaly przekazane malarzowi.");

    SwapToGalleryView(oPC, nToken);
}

// ----------------------------------------------------------------
// Helper: PC views their own portrait for a buff
// ----------------------------------------------------------------

void PorHandleViewSelf(object oPC, int nToken)
{
    json jPor = PorGetByOwner(oPC);
    if(JsonGetType(jPor) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Portret] Nie posiadasz portretu.");
        return;
    }

    int nState    = JsonGetInt(JsonObjectGet(jPor, "state"));
    int nLastBuff = JsonGetInt(JsonObjectGet(jPor, "last_buff_at"));
    int nId       = JsonGetInt(JsonObjectGet(jPor, "id"));

    if(nState == POR_STATE_DAMAGED)
    {
        SendMessageToPC(oPC, "[Portret] Portret jest zniszczony — nie mozesz czerpac z niego mocy.");
        return;
    }
    if(nState == POR_STATE_MEMORIAL)
    {
        SendMessageToPC(oPC, "[Portret] Portret jest epitafium po poleglym. Nie przynosi zycia.");
        return;
    }
    if(!PorBuffReady(nLastBuff))
    {
        SendMessageToPC(oPC, "[Portret] Musisz poczekac godzine, zanim ponownie skontemplujesz portret.");
        return;
    }

    PorApplyBuff(oPC);
    PorUpdateLastBuff(nId);

    int nScore = JsonGetInt(JsonObjectGet(jPor, "shadow_score"));
    if(nScore >= POR_SHADOW_DAMNED)
        FloatingTextStringOnCreature("Portret pulsuje mroczna, obezwladniajaca aura...", oPC, FALSE);
    else if(nScore >= POR_SHADOW_CORRUPTED)
        FloatingTextStringOnCreature("W oczach portretu tleje ciemnosc. Czerpiesz z niej sile.", oPC, FALSE);
    else if(nScore >= POR_SHADOW_TAINTED)
        FloatingTextStringOnCreature("Portret jest zmacony, lecz wciaz daje cie inspiracje.", oPC, FALSE);
    else
        FloatingTextStringOnCreature("Oblicze na plonie czystoscia. Serce napelnia cie spokojem.", oPC, FALSE);

    // Re-feed detail panel to update button state
    FeedPortraitDetail(oPC, nToken, nId);
}

// ----------------------------------------------------------------
// Helper: repair a damaged portrait
// ----------------------------------------------------------------

void PorHandleRepair(object oPC, int nToken)
{
    json jPor = PorGetByOwner(oPC);
    if(JsonGetType(jPor) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Portret] Nie posiadasz portretu.");
        return;
    }

    int nState = JsonGetInt(JsonObjectGet(jPor, "state"));
    int nId    = JsonGetInt(JsonObjectGet(jPor, "id"));

    if(nState != POR_STATE_DAMAGED)
    {
        SendMessageToPC(oPC, "[Portret] Portret nie jest uszkodzony.");
        return;
    }
    if(GetGold(oPC) < POR_REPAIR_COST)
    {
        SendMessageToPC(oPC, "[Portret] Potrzebujesz " + IntToString(POR_REPAIR_COST)
            + " sz. na renowacje portretu.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(POR_REPAIR_COST, oPC, TRUE));
    PorSetState(nId, POR_STATE_NORMAL);
    PorRemoveCurse(oPC);

    FloatingTextStringOnCreature("Portret zostal odnowiony. Klatwa opuszcza twoje cialo.", oPC, FALSE);
    SendMessageToPC(oPC, "[Portret] Portret naprawiony za " + IntToString(POR_REPAIR_COST) + " sz.");

    FeedGalleryList(oPC, nToken);
    FeedPortraitDetail(oPC, nToken, nId);
}

// ----------------------------------------------------------------
// Helper: DM marks selected portrait as memorial
// ----------------------------------------------------------------

void PorHandleMarkMemorial(object oPC, int nToken)
{
    if(!GetIsDM(oPC))
    {
        SendMessageToPC(oPC, "[Portret] Tylko MG moze oznaczyc portret jako epitafium.");
        return;
    }

    int nSelId = GetLocalInt(oPC, POR_LVAR_SEL_ID);
    if(nSelId <= 0)
    {
        SendMessageToPC(oPC, "[Portret] Nie wybrano zadnego portretu.");
        return;
    }

    json jPor  = PorGetById(nSelId);
    int  nState= JsonGetInt(JsonObjectGet(jPor, "state"));
    if(nState == POR_STATE_MEMORIAL)
    {
        SendMessageToPC(oPC, "[Portret] Ten portret jest juz epitafium.");
        return;
    }

    PorSetState(nSelId, POR_STATE_MEMORIAL);
    SendMessageToPC(oPC, "[Portret] Portret oznaczony jako epitafium.");

    FeedGalleryList(oPC, nToken);
    FeedPortraitDetail(oPC, nToken, nSelId);
}

// ----------------------------------------------------------------
// Helper: DM adds shadow to selected portrait
// ----------------------------------------------------------------

void PorHandleAddShadow(object oPC, int nToken)
{
    if(!GetIsDM(oPC))
    {
        SendMessageToPC(oPC, "[Portret] Tylko MG moze dodac mrok do portretu.");
        return;
    }

    int nSelId = GetLocalInt(oPC, POR_LVAR_SEL_ID);
    if(nSelId <= 0)
    {
        SendMessageToPC(oPC, "[Portret] Nie wybrano zadnego portretu.");
        return;
    }

    json jPor = PorGetById(nSelId);
    int  nState= JsonGetInt(JsonObjectGet(jPor, "state"));
    if(nState == POR_STATE_MEMORIAL)
    {
        SendMessageToPC(oPC, "[Portret] Epitafium nie gromadzi mroku.");
        return;
    }

    PorAddShadowById(nSelId, 10);

    // If the owner is online, check if they need a new curse
    string sOwnerUuid = JsonGetString(JsonObjectGet(jPor, "owner_uuid"));
    object oOwner = GetFirstPC();
    while(GetIsObjectValid(oOwner))
    {
        if(GetObjectUUID(oOwner) == sOwnerUuid)
        {
            json jUpdated = PorGetById(nSelId);
            int nScore = JsonGetInt(JsonObjectGet(jUpdated, "shadow_score"));
            if(nScore >= POR_SHADOW_DAMNED && !GetLocalInt(oOwner, POR_LVAR_CURSE))
                PorApplyCurse(oOwner);
            break;
        }
        oOwner = GetNextPC();
    }

    SendMessageToPC(oPC, "[Portret] Dodano 10 pkt. mroku do portretu.");
    FeedGalleryList(oPC, nToken);
    FeedPortraitDetail(oPC, nToken, nSelId);
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, POR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, POR_LVAR_SEL_ID);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == POR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_COMMISSION)
        {
            SwapToCommissionView(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_VIEW)
        {
            PorHandleViewSelf(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_REPAIR)
        {
            PorHandleRepair(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_MEMORIAL)
        {
            PorHandleMarkMemorial(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_ADD_SHADOW)
        {
            PorHandleAddShadow(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_COM_CONFIRM)
        {
            PorHandleCommission(oPC, nToken);
            return;
        }

        if(sElem == POR_BTN_COM_CANCEL)
        {
            SwapToGalleryView(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == POR_BTN_ROW)
        {
            PorHandleRowClick(oPC, nToken, nIdx);
            return;
        }
    }
}
