#include "lib_smit"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Notify the player if they have crafting materials in inventory.
    int nIron    = SmithCountMat(oPC, SMIT_TAG_IRON);
    int nLeather = SmithCountMat(oPC, SMIT_TAG_LEATHER);
    int nBone    = SmithCountMat(oPC, SMIT_TAG_BONE);

    if(nIron + nLeather + nBone > 0)
    {
        string sMsg = "[Kuznia] Detekcja materialow: "
            + IntToString(nIron)    + "x zelazna sztabka, "
            + IntToString(nLeather) + "x pasek skory, "
            + IntToString(nBone)    + "x odlamek kosci. "
            + "Znajdz kowadlo, by wykuc bron lub zbroje.";
        SendMessageToPC(oPC, sMsg);
    }
}
