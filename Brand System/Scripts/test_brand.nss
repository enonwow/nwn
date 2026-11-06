// test_brand.nss -- OnUsed script for demonstration placeable "Lustro Duszy"
// Place a Placeable with this script as OnUsed.
//
// Local vars on the placeable (set via toolset or DM client):
//   BRAND_TEST_TYPE  int  > 0: apply this brand type to the user (or DM target)
//   BRAND_TEST_LOC   int  0-6: body location for the test brand (default: BRAND_LOC_CHEST)
//
// If BRAND_TEST_TYPE is 0 (default): open the Brand inspection window for the PC.
// If used by a DM with BRAND_TEST_TYPE set: apply a brand to the nearest PC as a demonstration.
#include "lib_brand"

void main()
{
    object oUser     = GetLastUsedBy();
    int    nTestType = GetLocalInt(OBJECT_SELF, "BRAND_TEST_TYPE");
    int    nTestLoc  = GetLocalInt(OBJECT_SELF, "BRAND_TEST_LOC");

    if(nTestLoc < BRAND_LOC_FOREHEAD || nTestLoc >= BRAND_LOC_COUNT)
        nTestLoc = BRAND_LOC_CHEST;

    if(nTestType > 0 && GetIsDM(oUser))
    {
        // DM applies a test brand to the nearest PC
        object oBranded = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, PLAYER_CHAR_IS_PC, OBJECT_SELF);
        if(!GetIsObjectValid(oBranded))
        {
            SendMessageToPC(oUser, "[Pietna] Brak pobliskich graczy do oznaczenia.");
            return;
        }
        string sName   = GetLocalString(OBJECT_SELF, "BRAND_TEST_NAME");
        string sOrigin = GetLocalString(OBJECT_SELF, "BRAND_TEST_ORIGIN");
        if(sName   == "") sName   = BrandTypeName(nTestType);
        if(sOrigin == "") sOrigin = BrandOriginDefault(nTestType);

        BrandApply(oUser, oBranded, nTestLoc, nTestType, sName, sOrigin);
        SendMessageToPC(oUser, "[Pietna] Naniesiono " + sName + " na " + GetName(oBranded) + ".");
        return;
    }

    if(!GetIsPC(oUser)) return;

    // PC opens the inspection window
    CreateBrandWindow(oUser);

    // Demo: apply a sample brand on first use if PC has no brands (tutorial-style)
    int nCount = BrandGetCount(GetObjectUUID(oUser));
    if(nCount == 0 && GetLocalInt(OBJECT_SELF, "BRAND_DEMO_AUTO") == 1)
    {
        DelayCommand(0.5, BrandApply(OBJECT_SELF, oUser, BRAND_LOC_CHEST,
            BRAND_TYPE_EXILE,
            "Stygmat Wygnanca",
            "Wypalono w dniu wyroku, gdy miasto odwrocilo sie plecami."));
    }
}
