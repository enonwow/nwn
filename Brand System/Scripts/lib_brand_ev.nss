// lib_brand_ev.nss -- NUI event handler for Brand System
#include "lib_brand"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Remove confirmation popup ----
    if(nToken == NuiFindWindow(oPC, BRAND_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == BRAND_BTN_CONFIRM_YES)
            {
                int nLoc = GetLocalInt(oPC, BRAND_LVAR_PENDING);
                NuiDestroy(oPC, nToken);
                BrandRemoveAtLocation(oPC, nLoc);
                int nMainToken = NuiFindWindow(oPC, BRAND_WINDOW);
                if(nMainToken != 0)
                {
                    SetLocalInt(oPC, BRAND_LVAR_SEL_LOC, -1);
                    FeedBrandLocations(oPC, nMainToken);
                    NuiSetGroupLayout(oPC, nMainToken, BRAND_GRP_DETAIL, BuildBrandDetailEmpty(oPC));
                }
            }
            else if(sElem == BRAND_BTN_CONFIRM_NO)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, BRAND_WINDOW)) return;

    // ---- Main window close ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, BRAND_LVAR_SEL_LOC);
        DeleteLocalInt(oPC, BRAND_LVAR_PENDING);
        return;
    }

    // ---- Location row click ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BRAND_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= BRAND_LOC_COUNT) return;
        SetLocalInt(oPC, BRAND_LVAR_SEL_LOC, nIdx);

        // Update encouraged state for all rows
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < BRAND_LOC_COUNT; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, BRAND_BIND_ROW_ENC, jEncs);

        FeedBrandDetail(oPC, nToken, nIdx);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // ---- Close button ----
        if(sElem == BRAND_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ---- Conceal / reveal toggle ----
        if(sElem == BRAND_BTN_CONCEAL)
        {
            int nLoc = GetLocalInt(oPC, BRAND_LVAR_SEL_LOC);
            if(nLoc < 0) return;

            string sUuid  = GetObjectUUID(oPC);
            json   jBrand = BrandGetAtLoc(sUuid, nLoc);
            if(JsonGetType(jBrand) == JSON_TYPE_NULL) return;

            int bConc    = JsonGetInt(JsonObjectGet(jBrand, "is_concealed"));
            int bNewConc = !bConc;

            BrandSetConcealed(sUuid, nLoc, bNewConc);
            BrandApplyEffects(oPC);

            string sFlavor = bNewConc
                ? "Zakrywasz pietno. Efekty spoleczne sa teraz nieaktywne."
                : "Odslanasz pietno. Wszyscy moga je zobaczyc.";
            SendMessageToPC(oPC, "[Pietna] " + sFlavor);

            FeedBrandLocations(oPC, nToken);
            FeedBrandDetail(oPC, nToken, nLoc);
            return;
        }

        // ---- Remove button ----
        if(sElem == BRAND_BTN_REMOVE)
        {
            int nLoc = GetLocalInt(oPC, BRAND_LVAR_SEL_LOC);
            if(nLoc < 0) return;
            CreateBrandRemoveConfirm(oPC, nLoc);
            return;
        }
    }
}
