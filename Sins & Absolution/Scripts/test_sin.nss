#include "lib_sin"

// OnUsed script for a placeable "Ołtarz Spowiedzi" (Confession Altar).
// Demonstrates the full API: adds sample sins then opens the UI.
// Remove the sample SinAddSin calls in production — replace with
// just SinOpenWindow(oPC) so the altar only shows the current state.
void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC)) return;

    SinRegisterChar(oPC);

    // Demo only: inject a variety of sins to show different types + colors
    SinAddSin(oPC, SIN_TYPE_MURDER,      8,  "Zabójstwo niewinnego pielgrzyma");
    SinAddSin(oPC, SIN_TYPE_THEFT,       3,  "Kradzież z kościelnej ofiarni");
    SinAddSin(oPC, SIN_TYPE_BLASPHEMY,   5,  "Bluźnierstwo przed obliczem Helma");
    SinAddSin(oPC, SIN_TYPE_DARK_RITUAL, 10, "Udział w mrocznym rytuale o północy");
    SinAddSin(oPC, SIN_TYPE_BETRAYAL,    6,  "Zdrada towarzysza w obliczu śmierci");
    SinAddSin(oPC, SIN_TYPE_UNDEAD,      7,  "Ożywienie zwłok zabitego strażnika");
    SinAddSin(oPC, SIN_TYPE_DESECRATION, 4,  "Profanacja grobów na cmentarzu w Baldur's Gate");

    SinOpenWindow(oPC);
}
