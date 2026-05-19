// lib_bst_def.nss — constants, race tables, tier helpers, lore text
#include "lib_nui"
#include "sql_bst"

// Forward declarations (defined in lib_bst.nss)
void BstOpenCodex(object oPC);
void BstFeedList(object oPC, int nToken);
void BstFeedDetail(object oPC, int nToken, int nRaceIdx);
void BstApplyBonuses(object oPC);
void BstHandleTarget(object oPC);

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string BST_WIN_CODEX  = "BST_WIN_CODEX";
const string BST_EV_SCRIPT  = "lib_bst_ev";
const string BST_GRP_DETAIL = "bst_grp_detail";
const string BST_WIN_GEOM   = "bst_win_geom";

// ----------------------------------------------------------------
// Bind names
// ----------------------------------------------------------------

// List panel (array binds)
const string BST_BIND_ROW_NAME  = "bst_row_name";
const string BST_BIND_ROW_KILLS = "bst_row_kills";
const string BST_BIND_ROW_TIER  = "bst_row_tier";
const string BST_BIND_ROW_COLOR = "bst_row_color";
const string BST_BIND_ROW_ENC   = "bst_row_enc";

// Detail panel
const string BST_BIND_DET_TITLE = "bst_det_title";
const string BST_BIND_DET_KILLS = "bst_det_kills";
const string BST_BIND_DET_LORE  = "bst_det_lore";
const string BST_BIND_DET_BONUS = "bst_det_bonus";
const string BST_BIND_STUDY_ENA = "bst_study_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string BST_BTN_CLOSE  = "bst_btn_close";
const string BST_BTN_ROW    = "bst_btn_row";
const string BST_BTN_STUDY  = "bst_btn_study";

// ----------------------------------------------------------------
// Local variable names
// ----------------------------------------------------------------

const string BST_LVAR_SEL_IDX  = "BST_SEL_IDX";   // selected race index in codex
const string BST_LVAR_STUDYING = "BST_STUDYING";   // 1 while in targeting mode for study

// Stamped on creature to prevent double-study of same instance
const string BST_LVAR_STUDIED  = "BST_STUDIED";

// Tag for managed effects (NWN:EE TagEffect API)
const string BST_EFFECT_TAG    = "bst_bonus";

// ----------------------------------------------------------------
// Layout constants
// ----------------------------------------------------------------

const float BST_W      = 720.0;
const float BST_H      = 500.0;
const float BST_LIST_W = 270.0;

// ----------------------------------------------------------------
// Tier thresholds (study points per racial type)
// ----------------------------------------------------------------

const int BST_TIER1_KILLS = 5;
const int BST_TIER2_KILLS = 20;
const int BST_TIER3_KILLS = 75;

// Cumulative bonus caps (across all races)
const int BST_MAX_BONUS_AB  = 3;
const int BST_MAX_BONUS_DMG = 2;

// ----------------------------------------------------------------
// Race table — 14 tracked monster racial types
// ----------------------------------------------------------------

const int BST_RACE_COUNT = 14;

int BstRaceIndexToType(int nIdx)
{
    switch(nIdx)
    {
        case 0:  return RACIAL_TYPE_ABERRATION;
        case 1:  return RACIAL_TYPE_ANIMAL;
        case 2:  return RACIAL_TYPE_BEAST;
        case 3:  return RACIAL_TYPE_CONSTRUCT;
        case 4:  return RACIAL_TYPE_DRAGON;
        case 5:  return RACIAL_TYPE_ELEMENTAL;
        case 6:  return RACIAL_TYPE_FEY;
        case 7:  return RACIAL_TYPE_GIANT;
        case 8:  return RACIAL_TYPE_HUMANOID_GOBLINOID;
        case 9:  return RACIAL_TYPE_HUMANOID_MONSTROUS;
        case 10: return RACIAL_TYPE_HUMANOID_ORC;
        case 11: return RACIAL_TYPE_MAGICAL_BEAST;
        case 12: return RACIAL_TYPE_OUTSIDER;
        case 13: return RACIAL_TYPE_UNDEAD;
    }
    return RACIAL_TYPE_INVALID;
}

// Returns 0..13 or -1 if the racial type is not tracked.
int BstTypeToRaceIndex(int nType)
{
    int i;
    for(i = 0; i < BST_RACE_COUNT; i++)
    {
        if(BstRaceIndexToType(i) == nType) return i;
    }
    return -1;
}

string BstRaceIndexToName(int nIdx)
{
    switch(nIdx)
    {
        case 0:  return "Aberracje";
        case 1:  return "Zwierzęta";
        case 2:  return "Bestie";
        case 3:  return "Konstrukty";
        case 4:  return "Smoki";
        case 5:  return "Żywiołaki";
        case 6:  return "Leśne Duchy";
        case 7:  return "Olbrzymy";
        case 8:  return "Goblinoidy";
        case 9:  return "Potwory";
        case 10: return "Orki";
        case 11: return "Mag. Bestie";
        case 12: return "Przybysze";
        case 13: return "Nieumarli";
    }
    return "Nieznane";
}

// ----------------------------------------------------------------
// Tier helpers
// ----------------------------------------------------------------

int BstGetTier(int nKills)
{
    if(nKills >= BST_TIER3_KILLS) return 3;
    if(nKills >= BST_TIER2_KILLS) return 2;
    if(nKills >= BST_TIER1_KILLS) return 1;
    return 0;
}

string BstGetTierLabel(int nTier)
{
    switch(nTier)
    {
        case 1: return "Poznany";
        case 2: return "Zbadany";
        case 3: return "Mistrz";
    }
    return "-";
}

json BstGetTierColor(int nTier)
{
    switch(nTier)
    {
        case 1: return NuiColor(200, 200,  80);   // żółty
        case 2: return NuiColor( 80, 200, 130);   // zielony
        case 3: return NuiColor(220,  80,  80);   // czerwony
    }
    return NuiColor(120, 120, 120);               // szary
}

// ----------------------------------------------------------------
// Lore text (Polish, dark-fantasy flavor)
// ----------------------------------------------------------------

string BstGetLoreText(int nIdx, int nTier)
{
    if(nTier == 0)
        return "Zbyt mało obserwacji, by odnotować cokolwiek wartościowego."
             + " Zbadaj więcej stworzeń tej rasy, aby odkryć ich tajemnice.";

    string sT1;
    switch(nIdx)
    {
        case 0:  sT1 = "Aberracje to skrzywione byty spoza porządku natury. Odporne na paraliż"
                      " i trucizny, reagują boleśnie na zaklęcia przywracające porządek."; break;
        case 1:  sT1 = "Zwierzęta kierują się instynktem i terytorializmem. Ich wzrok śledzi"
                      " ruch — bezruch i cierpliwość często skuteczniejsze niż szarża."; break;
        case 2:  sT1 = "Bestie mają nadnaturalną siłę i żarłoczność. Ognisko i hałas odstraszają"
                      " słabsze osobniki — silniejsze przyciąga jedynie zapach krwi."; break;
        case 3:  sT1 = "Konstrukty nie oddychają, nie czują bólu, nie znają zmęczenia."
                      " Magia umysłu i trucizny są bezużyteczne — atakuj spoiwo formy."; break;
        case 4:  sT1 = "Smoki pamiętają czasy, gdy bogowie byli młodzi. Każdy kolor kryje"
                      " inny oddech — czerwień to piekło, biel to grób lodowy."; break;
        case 5:  sT1 = "Żywiołaki są inkarnacją sił natury. Bez broni +1 lub lepszej"
                      " twoje ciosy przenikają przez nie jak przez mgłę."; break;
        case 6:  sT1 = "Leśne duchy drżą przed żelazem i srebrem. Ich czar niewidzialności"
                      " rozprasza się, gdy dotykają metalu wykutego ludzką ręką."; break;
        case 7:  sT1 = "Olbrzymy są powolne i przewidywalne. Unik i kontratak — to ich słabość."
                      " Rzucają głazami z daleka, bo z bliska mają słabe pole widzenia."; break;
        case 8:  sT1 = "Goblinoidy żyją w klanach z twardą hierarchią. Ich przywódca jest celem"
                      " priorytetowym — bez niego reszta traci wolę walki."; break;
        case 9:  sT1 = "Monstrualne humanoidalne stwory są odporne na zastraszenie."
                      " Każde ma unikalne zdolności — obserwuj wzorzec przed atakiem."; break;
        case 10: sT1 = "Orki walczą w furii. Wściekłość daje im siłę, ale mąci zmysły."
                      " Drwina i prowokacja mogą skłonić je do ataku nieprzemyślanego."; break;
        case 11: sT1 = "Magiczne bestie łączą naturę z nadprzyrodzonością. Dispel Magic"
                      " osłabia ich wrodzone zdolności jak zimny deszcz gasi żagiew."; break;
        case 12: sT1 = "Przybysze ze sfer zewnętrznych przynoszą ze sobą obcą logikę bytu."
                      " Broń Dobra lub Zła, zależnie od ich natury, przebija ich ochronę."; break;
        case 13: sT1 = "Nieumarli nie znają zmęczenia ani bólu. Magia Dobra, Consecrate"
                      " i ogień palą tę starą magię, która trzyma ich w świecie żywych."; break;
        default: sT1 = "Obserwacje są niepełne."; break;
    }

    if(nTier < 2) return sT1;

    string sT2;
    switch(nIdx)
    {
        case 0:  sT2 = "Studium: Aberracje mają punkty kontroli w ciałach — kryształy,"
                      " oka lub rdzenie energii. Celny atak w ten punkt niszczy je szybciej."; break;
        case 1:  sT2 = "Studium: Stado zwierząt można rozproszyć zabijając dominanta."
                      " Zaklęcia wpływające na Wolę są zaskakująco skuteczne."; break;
        case 2:  sT2 = "Studium: Bestie atakują w rytm — chwila po ugryzeniu to moment na"
                      " kontratak. Wyczucie tego rytmu jest trudne, lecz ratuje życie."; break;
        case 3:  sT2 = "Studium: Konstrukty mają krytyczny punkt łączenia energii."
                      " Skupiony, silny cios w to miejsce powoduje kaskadową awarię."; break;
        case 4:  sT2 = "Studium: Skrzydła smoka to jego słabość i siła zarazem."
                      " Unieruchomienie lotu niweluje mobilność i część ataków obszarowych."; break;
        case 5:  sT2 = "Studium: Żywiołak ognia boi się wody, żywiołak wody — uderzenia"
                      " elektryczności. Atak przeciwnym żywiołem zadaje podwójne cierpienie."; break;
        case 6:  sT2 = "Studium: Leśne duchy tracą moc w otwartej przestrzeni."
                      " Ciągłe Światło eliminuje ich skrytość i osłabia zdolność ucieczki."; break;
        case 7:  sT2 = "Studium: Olbrzymy mają niski Refleks, lecz ogromną Fortitudę."
                      " Zaklęcia unieruchamiające lub spowalniające są najskuteczniejsze."; break;
        case 8:  sT2 = "Studium: Gdy przywódca pada, goblinoidy uciekają lub dezorganizują się."
                      " Zamknięta przestrzeń eliminuje tę przewagę — nie daj im drogi odwrotu."; break;
        case 9:  sT2 = "Studium: Monstrualne humanoidalne stwory często potrafią się regenerować."
                      " Ogień i kwas zapobiegają odnowie — rany muszą zostać wypalzone."; break;
        case 10: sT2 = "Studium: Orcka furia ma ograniczony czas. Defensywna taktyka"
                      " i przeczekanie wściekłości oszczędza siły na decydujący cios."; break;
        case 11: sT2 = "Studium: Magiczne bestie mają charakterystyczne sekwencje ataków."
                      " Przerwa między natarciami to twoja szansa na wyprzedzający cios."; break;
        case 12: sT2 = "Studium: Przybysze mogą przywoływać sojuszników z macierzystych sfer."
                      " Wyeliminowanie kapłanów lub magów wśród nich przerywa ten proces."; break;
        case 13: sT2 = "Studium: Nieumarli słabną w polu Consecrate — wnętrze świątyń jest"
                      " dla nich polem minowym. Kapłan ze zdolnością Turn Undead jest bezcenny."; break;
        default: sT2 = ""; break;
    }

    if(nTier < 3) return sT1 + "\n\n" + sT2;

    string sT3;
    switch(nIdx)
    {
        case 0:  sT3 = "Mistrzostwo: Wzorce aberracji są dla ciebie jak otwarta księga."
                      " Twoje ataki omijają ich ochronne pola z chirurgiczną precyzją."; break;
        case 1:  sT3 = "Mistrzostwo: Znasz każdy nawyk i rytm zwierząt tych ziem."
                      " Twoja obecność ich nie płoszy — możesz zbliżyć się bez prowokacji."; break;
        case 2:  sT3 = "Mistrzostwo: Bestie nie zaskakują cię już nigdy. Każdy ruch"
                      " przewidujesz, każde zagrożenie czujesz, zanim ono poczuje ciebie."; break;
        case 3:  sT3 = "Mistrzostwo: Budownicze skonstruowali je z myślą, że nikt nie znajdzie"
                      " ich słabości. Ty je znalazłeś. Jeden celny cios — i konstrukcja pada."; break;
        case 4:  sT3 = "Mistrzostwo: Smoki wiedzą, czym jesteś. Ich starożytny strach"
                      " przestał działać na ciebie — jesteś tak zimny jak sam smoczy oddech."; break;
        case 5:  sT3 = "Mistrzostwo: Rozumiesz dualizm żywiołów głębiej niż większość magów."
                      " Przejście żywiołaka między formami to moment, na który czekasz."; break;
        case 6:  sT3 = "Mistrzostwo: Widzisz leśne duchy nawet ukryte w mroku i liściach."
                      " Ich złudzenia są dla ciebie przezroczyste jak woda w strumieniu."; break;
        case 7:  sT3 = "Mistrzostwo: Znasz wszystkie słabe punkty olbrzymów — stawy, ścięgna,"
                      " kark. Twoje ciosy lądują tam, gdzie ból jest nie do zniesienia."; break;
        case 8:  sT3 = "Mistrzostwo: Rozumiesz taktykę goblinoidów na wylot. Możesz ich"
                      " przechytrzyć, zanim zdadzą sobie sprawę, że bitwa już się skończyła."; break;
        case 9:  sT3 = "Mistrzostwo: Każda monstrualna forma odsłoniła ci swoje tajemnice."
                      " Instynkt zastąpił teorię — działasz szybciej niż ich ataki."; break;
        case 10: sT3 = "Mistrzostwo: Doświadczyłeś niezliczonych ataków orkowych hord."
                      " Ich wzorce, słabości i wrzaski bojowe są dla ciebie jak kołysanka."; break;
        case 11: sT3 = "Mistrzostwo: Twoja intuicja jest szybsza niż ich wrodzona magia."
                      " Działasz w przerwach ich sekwencji z precyzją godną starych mistrzów."; break;
        case 12: sT3 = "Mistrzostwo: Zewnętrzne sfery nie mają już przed tobą tajemnic."
                      " Przybysze patrzą w twoje oczy i widzą kogoś, kto był tam z nimi."; break;
        case 13: sT3 = "Mistrzostwo: Twój wzrok przebija mrok nieumarłości. Znasz każdy trik,"
                      " każdą słabość. Śmierć cię nie przeraża — za dużo jej widziałeś."; break;
        default: sT3 = ""; break;
    }

    return sT1 + "\n\n" + sT2 + "\n\n" + sT3;
}

// ----------------------------------------------------------------
// Bonus summary text (for detail panel)
// ----------------------------------------------------------------

string BstGetBonusText(int nTotalTier2, int nTotalTier3)
{
    if(nTotalTier2 == 0 && nTotalTier3 == 0)
        return "Brak aktywnych premii.\nZbadaj więcej ras, aby odblokować bonusy bojowe.";

    int nAB  = nTotalTier2 < BST_MAX_BONUS_AB  ? nTotalTier2  : BST_MAX_BONUS_AB;
    int nDmg = nTotalTier3 < BST_MAX_BONUS_DMG ? nTotalTier3  : BST_MAX_BONUS_DMG;

    string sResult = "Aktywne premie bojowe:";
    if(nAB > 0)
        sResult = sResult + "\n  +" + IntToString(nAB) + " do Ataku"
                + "  (ze " + IntToString(nTotalTier2) + " zbadanych ras, max " + IntToString(BST_MAX_BONUS_AB) + ")";
    if(nDmg > 0)
        sResult = sResult + "\n  +" + IntToString(nDmg) + " do Obrażeń"
                + "  (z " + IntToString(nTotalTier3) + " opanowanych ras, max " + IntToString(BST_MAX_BONUS_DMG) + ")";
    if(nAB == 0 && nTotalTier2 > 0)
        sResult = sResult + "\n  (limit Ataku osiągnięty)";
    if(nDmg == 0 && nTotalTier3 > 0)
        sResult = sResult + "\n  (limit Obrażeń osiągnięty)";
    return sResult;
}
