// sys_on_death.nss — Trophy Hall: trophy loot spawner
//
// Assign this as the OnDeath script for every creature type you want to track.
// Alternatively, if NWNX_Events is loaded, hook NWNX_ON_CREATURE_KILL_AFTER
// and call ExecuteScript("sys_on_death", oDeadCreature) from there.
//
// Trophy drop rate: 40% per kill.  Bosses/named can override with
// a local int TRPH_FORCE_DROP = 1 on the creature to guarantee a drop.

#include "lib_trph_def"

void main()
{
    object oDead = OBJECT_SELF;

    // Never drop from PCs or DM-possessed creatures
    if(GetIsPC(oDead) || GetIsDMPossessed(oDead)) return;

    int nRacial = GetRacialType(oDead);
    int nCat    = TrphGetCategory(nRacial);
    if(nCat < 0) return;

    // Named/boss creatures can force a drop
    int bForce = GetLocalInt(oDead, "TRPH_FORCE_DROP");
    if(!bForce && Random(10) >= 4) return;   // 40% base drop rate

    string sTag    = TRPH_ITEM_TAG + IntToString(nCat);
    string sName   = TrphItemName(nCat);
    string sDesc   = "Trofeum: " + TrphCatName(nCat)
                   + ". Złóż w Sali Trofeów, by potwierdzić swoje łowy.";

    // Try the custom HAK resref first
    object oItem = CreateItemOnObject(sTag, oDead);

    if(!GetIsObjectValid(oItem))
    {
        // Fallback: re-use a generic misc item from base game and overwrite its identity
        oItem = CreateItemOnObject("nw_it_msmlmisc22", oDead);
    }

    if(!GetIsObjectValid(oItem)) return;

    SetTag        (oItem, sTag);
    SetName       (oItem, sName);
    SetDescription(oItem, sDesc);
}
