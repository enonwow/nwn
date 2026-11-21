#include "sql_drm"

// Forward declarations
void DrmOpenWindow(object oPC);
void DrmFeedTranceView(object oPC, int nToken);
void DrmFeedJournalView(object oPC, int nToken);
void DrmApplyVisionEffect(object oPC, int nFxType, int nFxValue);
json DrmGetVisionById(int nId);
json DrmDrawVisions(object oPC);

// ----------------------------------------------------------------
// Vision data — 20 hand-crafted visions across 6 categories
// ----------------------------------------------------------------
// Vision JSON: {id, category, title, text, fx_type, fx_value}

json DrmMakeVision(int nId, string sCat, string sTitle, string sText, int nFxType, int nFxValue)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "id",       JsonInt(nId));
    j = JsonObjectSet(j, "category", JsonString(sCat));
    j = JsonObjectSet(j, "title",    JsonString(sTitle));
    j = JsonObjectSet(j, "text",     JsonString(sText));
    j = JsonObjectSet(j, "fx_type",  JsonInt(nFxType));
    j = JsonObjectSet(j, "fx_value", JsonInt(nFxValue));
    return j;
}

json DrmGetVisionById(int nId)
{
    switch(nId)
    {
        // ---- ŚMIERĆ (Death) — id 1-4 ----
        case 1: return DrmMakeVision(1, DRM_CAT_DEATH,
            "Kościana Ręka",
            "Widmo śmierci wyciąga ku tobie dłoń w wizji. Palce z kości sunęły wolno przez twoją zbroję, nie napotykając oporu. Poczujesz ich dotyk przez najbliższe godziny — gdy zajdzie potrzeba obrony, ciało odmówi posłuszeństwa.",
            DRM_FX_AC_PENLT, 2);

        case 2: return DrmMakeVision(2, DRM_CAT_DEATH,
            "Kruk nad Tobą",
            "Czarny kruk z oczami jak żarzące się węgle krąży ponad twoją głową. Nie uleci. Patrzy. Twoja ręka drżeć będzie gdy sięgać będziesz po broń — śmierć nosi piętno na tych, którzy już ją widzieli.",
            DRM_FX_ATTACK_PENLT, 2);

        case 3: return DrmMakeVision(3, DRM_CAT_DEATH,
            "Próg Niebytności",
            "Stoisz na krawędzi nicości. Za tobą życie; przed tobą — cisza doskonała. Każdy cios może okazać się ostatnim. Wola twoja słabnie wobec nieuchronności, a zmysły odmawiają pełnej czujności.",
            DRM_FX_SAVE_PENLT, 2);

        case 4: return DrmMakeVision(4, DRM_CAT_DEATH,
            "Wieczny Sen",
            "Widzisz własny nagrobek, porośnięty mchem nieznanych lat. Imię zatarte. Data — wkrótce. Wizja ta nie niesie kary, lecz przypomnienie: każda chwila jest pożyczona od ciemności.",
            DRM_FX_REVEAL, 0);

        // ---- TRYUMF (Triumph) — id 5-8 ----
        case 5: return DrmMakeVision(5, DRM_CAT_TRIUMPH,
            "Ostrze Przeznaczenia",
            "W wizji trzymasz w rękach miecz wykuty ze skrzepłego światła gwiazd. Widzisz siebie triumfującego nad bezimiennym wrogiem u swych stóp. Twoja ręka staje się pewna, oko bystre — cel ucieka rzadziej niż zwykle.",
            DRM_FX_ATTACK_BONUS, 2);

        case 6: return DrmMakeVision(6, DRM_CAT_TRIUMPH,
            "Tarcza Wiary",
            "Ogniste skrzydła rozwijają się za twoimi plecami i obejmują cię jak mur. W ich blasku skóra twardnieje, a pancerz staje się czymś więcej niż żelazem. Możesz przyjąć ciosy, których inni by nie przeżyli.",
            DRM_FX_AC_BONUS, 2);

        case 7: return DrmMakeVision(7, DRM_CAT_TRIUMPH,
            "Nieujarzmiony",
            "Wicher zmian szaleje wokół ciebie, lecz twoja postać stoi nieruchomo jak monolith. Wola twoja jest niepokonana — trucizna traci jad, ogień swój żar, a przekleństwo moc. Przez pewien czas nic cię nie ugnie.",
            DRM_FX_SAVE_BONUS, 2);

        case 8: return DrmMakeVision(8, DRM_CAT_TRIUMPH,
            "Krew Herosów",
            "Krew dawnych bohaterów płynie w twoich żyłach — słyszysz ich głosy, czujesz ich siłę. Ciało twoje napełnia się tymczasową witalnością, jaką daje wspomnienie zwycięstw minionych pokoleń.",
            DRM_FX_TEMP_HP, 15);

        // ---- CHAOS (Chaos) — id 9-12 ----
        case 9: return DrmMakeVision(9, DRM_CAT_CHAOS,
            "Dwulicowy Los",
            "Tysiąc ścieżek rozbiega się przed tobą. Na jednej — chwała; na innej — ruina. Wizja nie daje odpowiedzi. Przyjmując ją, otwierasz drzwi nieznanemu — co przyjdzie, to przyjdzie. Gotów?",
            DRM_FX_CHAOS_RANDOM, 0);

        case 10: return DrmMakeVision(10, DRM_CAT_CHAOS,
            "Szaleństwo Gwiazd",
            "Gwiazdy falują i zamieniają się miejscami. Konstelacje rozpadają się i sklejają w nowe znaki, których nikt nie zna. Kosmiczny chaos objawia swoją twarz — i ty możesz go dotknąć, choć nie wiedzieć czego się spodziewać.",
            DRM_FX_CHAOS_RANDOM, 0);

        case 11: return DrmMakeVision(11, DRM_CAT_CHAOS,
            "Maska Fortuny",
            "Za uśmiechniętą maską kryje się płacz. Za płaczącą — śmiech. Fortuna igra twoją postacią jak kostką do gry. Wizja ta przyniesie coś — lecz czy dobrego czy złego, tego żaden wieszcz nie powie.",
            DRM_FX_CHAOS_RANDOM, 0);

        case 12: return DrmMakeVision(12, DRM_CAT_CHAOS,
            "Spirala Bez Centrum",
            "Wizja nie ma początku ani końca — spirala wciąga cię w coraz głębsze warstwy rzeczywistości. Na dnie czeka dar lub przekleństwo, których natura zależy od twego serca. Nie wiesz, które masz.",
            DRM_FX_CHAOS_RANDOM, 0);

        // ---- PRAWDA (Truth) — id 13-15 ----
        case 13: return DrmMakeVision(13, DRM_CAT_TRUTH,
            "Odsłonięta Twarz",
            "W czarnej wodzie widzisz odbicie swojej twarzy — lecz chwilę później twarz należy do kogoś innego. Ktoś cię obserwuje, naśladuje, czeka. Wizja ostrzega: nie jesteś tu sam. Uważaj na tych, którzy się uśmiechają.",
            DRM_FX_REVEAL, 1);

        case 14: return DrmMakeVision(14, DRM_CAT_TRUTH,
            "Mroczne Zapiski",
            "Zakazana księga otwiera się sama na właściwej stronie. Rozumiesz każde słowo, mimo że język jest obcy. Linie opisują mechanikę świata — zaklęcie, które można złamać, barierę, którą można przekroczyć. Wiedza ta trwa krótko, lecz trwa.",
            DRM_FX_REVEAL, 2);

        case 15: return DrmMakeVision(15, DRM_CAT_TRUTH,
            "Ślepy Prorok",
            "Stary ślepiec wskazuje na ciebie przez tłum w wizji i szepcze: »Twoja krew pamięta coś, o czym ty zapomniałeś.« Nie powie więcej. Lecz intuicja twoja wyostrza się na chwilę — widzisz kontury spraw ukrytych.",
            DRM_FX_REVEAL, 3);

        // ---- CIEŃ (Shadow) — id 16-17 ----
        case 16: return DrmMakeVision(16, DRM_CAT_SHADOW,
            "Utkany z Mroku",
            "Stajesz się jednym z cienia. Twoje kontury rozmywają się, krok milknie, oddech zamiera. Nikt cię nie dostrzeże, gdy nie zechcesz. Ciemność jest twoim płaszczem i bronią przez czas, który wizja ci ofiarowuje.",
            DRM_FX_STEALTH_BONUS, 5);

        case 17: return DrmMakeVision(17, DRM_CAT_SHADOW,
            "Krok Między Zasłonami",
            "Poruszasz się między planarną zasłoną a rzeczywistością — w miejscu, gdzie nie ma dźwięku, gdzie posadzka nie czuje ciężaru. Twoje ruchy są niesłyszalne; ślady nikną zanim zdążą powstać.",
            DRM_FX_STEALTH_BONUS, 4);

        // ---- KREW (Blood) — id 18-20 ----
        case 18: return DrmMakeVision(18, DRM_CAT_BLOOD,
            "Czerwona Pasja",
            "Twoje serce bije szybciej niż kiedykolwiek. Krew śpiewa w żyłach — stara pieśń polowania. Każdy cios twojej broni niesie w sobie ten rytm i druzgocze mocniej niż zwykle.",
            DRM_FX_DAMAGE_BONUS, 2);

        case 19: return DrmMakeVision(19, DRM_CAT_BLOOD,
            "Ofiara Krwi",
            "W wizji kroplą własnej krwi pieczętujesz układ z czymś bez imienia. W zamian za przyszły dług — teraz nadpływ mocy. Ciało twoje nasyca się tymczasową witalnością, gorącą i bolesną jak wrzątek.",
            DRM_FX_TEMP_HP, 20);

        case 20: return DrmMakeVision(20, DRM_CAT_BLOOD,
            "Wrzask Ofiary",
            "Wizja pełna bólu i rozpaczy — czyjejś, nie twojej. Jej ból staje się twoją siłą. Atakujesz celniej, a ból innych pali cię jak paliwo. Mroczny dar, który wielu odrzuca.",
            DRM_FX_ATTACK_BONUS, 3);
    }
    return JsonNull();
}

// ----------------------------------------------------------------
// Weighted pool — weighting based on PC state
// ----------------------------------------------------------------

json DrmDrawVisions(object oPC)
{
    int nHP    = GetCurrentHitPoints(oPC) * 100 / GetMaxHitPoints(oPC);
    int bNight = GetIsNight();

    // Build a flat list of IDs; each ID appears N times based on weight.
    // Death IDs: 1-4, Triumph: 5-8, Chaos: 9-12, Truth: 13-15, Shadow: 16-17, Blood: 18-20
    json jPool = JsonArray();
    int i;

    // Death: base 2x, extra 2x when HP < 50%
    int nDeathW = 2 + (nHP < 50 ? 2 : 0);
    for(i = 0; i < nDeathW; i++)
    {
        jPool = JsonArrayInsert(jPool, JsonInt(1));
        jPool = JsonArrayInsert(jPool, JsonInt(2));
        jPool = JsonArrayInsert(jPool, JsonInt(3));
        jPool = JsonArrayInsert(jPool, JsonInt(4));
    }

    // Triumph: base 2x
    for(i = 0; i < 2; i++)
    {
        jPool = JsonArrayInsert(jPool, JsonInt(5));
        jPool = JsonArrayInsert(jPool, JsonInt(6));
        jPool = JsonArrayInsert(jPool, JsonInt(7));
        jPool = JsonArrayInsert(jPool, JsonInt(8));
    }

    // Chaos: base 2x
    for(i = 0; i < 2; i++)
    {
        jPool = JsonArrayInsert(jPool, JsonInt(9));
        jPool = JsonArrayInsert(jPool, JsonInt(10));
        jPool = JsonArrayInsert(jPool, JsonInt(11));
        jPool = JsonArrayInsert(jPool, JsonInt(12));
    }

    // Truth: base 1x
    jPool = JsonArrayInsert(jPool, JsonInt(13));
    jPool = JsonArrayInsert(jPool, JsonInt(14));
    jPool = JsonArrayInsert(jPool, JsonInt(15));

    // Shadow: base 2x, extra 2x at night
    int nShadowW = 2 + (bNight ? 2 : 0);
    for(i = 0; i < nShadowW; i++)
    {
        jPool = JsonArrayInsert(jPool, JsonInt(16));
        jPool = JsonArrayInsert(jPool, JsonInt(17));
    }

    // Blood: base 2x, extra 1x when HP < 50%
    int nBloodW = 2 + (nHP < 50 ? 1 : 0);
    for(i = 0; i < nBloodW; i++)
    {
        jPool = JsonArrayInsert(jPool, JsonInt(18));
        jPool = JsonArrayInsert(jPool, JsonInt(19));
        jPool = JsonArrayInsert(jPool, JsonInt(20));
    }

    int nPoolSize = JsonGetLength(jPool);

    // Pick DRM_VISIONS_PER_SESSION distinct vision IDs without replacement.
    json jResult  = JsonArray();
    json jUsedIds = JsonArray();

    int nAttempts = 0;
    while(JsonGetLength(jResult) < DRM_VISIONS_PER_SESSION && nAttempts < 200)
    {
        nAttempts++;
        int nIdx = Random(nPoolSize);
        int nId  = JsonGetInt(JsonArrayGet(jPool, nIdx));

        int bUsed = FALSE;
        int j;
        for(j = 0; j < JsonGetLength(jUsedIds); j++)
        {
            if(JsonGetInt(JsonArrayGet(jUsedIds, j)) == nId) { bUsed = TRUE; break; }
        }
        if(bUsed) continue;

        jUsedIds = JsonArrayInsert(jUsedIds, JsonInt(nId));
        jResult  = JsonArrayInsert(jResult,  DrmGetVisionById(nId));
    }

    return jResult;
}

// ----------------------------------------------------------------
// Effect descriptions
// ----------------------------------------------------------------

string DrmEffectLabel(int nFxType, int nFxValue)
{
    string sVal = IntToString(nFxValue);
    switch(nFxType)
    {
        case DRM_FX_ATTACK_BONUS:  return "Premia do trafienia: +" + sVal;
        case DRM_FX_ATTACK_PENLT:  return "Kara do trafienia: -"  + sVal;
        case DRM_FX_AC_BONUS:      return "Premia do AC: +"        + sVal;
        case DRM_FX_AC_PENLT:      return "Kara do AC: -"          + sVal;
        case DRM_FX_SAVE_BONUS:    return "Premia do rzutów obronnych: +" + sVal;
        case DRM_FX_SAVE_PENLT:    return "Kara do rzutów obronnych: -"   + sVal;
        case DRM_FX_STEALTH_BONUS: return "Premia do Skradania/Ciszy: +"  + sVal;
        case DRM_FX_DAMAGE_BONUS:  return "Premia do obrażeń: +"   + sVal;
        case DRM_FX_TEMP_HP:       return "Tymczasowe PW: +"        + sVal;
        case DRM_FX_CHAOS_RANDOM:  return "Efekt: nieznany — los zadecyduje";
        case DRM_FX_REVEAL:        return "Efekt: Wgląd — zobaczysz wiadomość";
        case DRM_FX_NONE:          return "Brak efektu mechanicznego";
    }
    return "";
}

// ----------------------------------------------------------------
// Apply effect
// ----------------------------------------------------------------

void DrmApplyVisionEffect(object oPC, int nFxType, int nFxValue)
{
    float fDur = DRM_EFFECT_DURATION_S;
    effect eFx;
    int bApply = TRUE;

    switch(nFxType)
    {
        case DRM_FX_ATTACK_BONUS:
            eFx = EffectAttackIncrease(nFxValue, ATTACK_BONUS_MISC);
            break;
        case DRM_FX_ATTACK_PENLT:
            eFx = EffectAttackDecrease(nFxValue, ATTACK_BONUS_MISC);
            break;
        case DRM_FX_AC_BONUS:
            eFx = EffectACIncrease(nFxValue, AC_DODGE_BONUS);
            break;
        case DRM_FX_AC_PENLT:
            eFx = EffectACDecrease(nFxValue, AC_DODGE_BONUS);
            break;
        case DRM_FX_SAVE_BONUS:
            eFx = EffectSavingThrowIncrease(nFxValue, SAVING_THROW_ALL);
            break;
        case DRM_FX_SAVE_PENLT:
            eFx = EffectSavingThrowDecrease(nFxValue, SAVING_THROW_ALL);
            break;
        case DRM_FX_STEALTH_BONUS:
            eFx = EffectSkillIncrease(SKILL_HIDE, nFxValue);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectLinkEffects(eFx, EffectSkillIncrease(SKILL_MOVE_SILENTLY, nFxValue)),
                oPC, fDur);
            bApply = FALSE;
            break;
        case DRM_FX_DAMAGE_BONUS:
            eFx = EffectDamageIncrease(nFxValue, DAMAGE_TYPE_MAGICAL);
            break;
        case DRM_FX_TEMP_HP:
            eFx = EffectTemporaryHitpoints(nFxValue);
            break;
        case DRM_FX_CHAOS_RANDOM:
        {
            int nRoll = Random(6);
            string sChaosDesc;
            switch(nRoll)
            {
                case 0: eFx = EffectAttackIncrease(2, ATTACK_BONUS_MISC);       sChaosDesc = "Ręka pewna jak skała (+2 trafienie)";        break;
                case 1: eFx = EffectACDecrease(2, AC_DODGE_BONUS);              sChaosDesc = "Chaos osłabia obronę (-2 AC)";               break;
                case 2: eFx = EffectSavingThrowIncrease(2, SAVING_THROW_ALL);   sChaosDesc = "Wola wzmocniona (+2 rzuty obronne)";         break;
                case 3: eFx = EffectTemporaryHitpoints(10);                     sChaosDesc = "Życiodajna fala (+10 tymczasowych PW)";       break;
                case 4: eFx = EffectAttackDecrease(1, ATTACK_BONUS_MISC);       sChaosDesc = "Drżąca ręka (-1 trafienie)";                 break;
                default:eFx = EffectACIncrease(3, AC_DODGE_BONUS);              sChaosDesc = "Nieprzewidywalna ochrona (+3 AC)";            break;
            }
            SendMessageToPC(oPC, "[Kodeks Wizji] Chaos przemówił: " + sChaosDesc + ".");
            break;
        }
        case DRM_FX_REVEAL:
        {
            int nMsg = Random(4);
            if(nFxValue > 0 && nFxValue <= 3) nMsg = nFxValue - 1;
            string sReveal;
            switch(nMsg)
            {
                case 0:  sReveal = "Wizja ostrzega: za uśmiechniętą twarzą kryje się zdrajca. Ufaj tylko tym, których znasz od dawna.";           break;
                case 1:  sReveal = "Antyczna prawda przemawia przez sen: każde zaklęcie ma swój przeciw-klucz — szukaj symbolu na odwrocie.";      break;
                case 2:  sReveal = "Krew twoja pamięta: gdzieś w tym miejscu zakopano prawdę. Szukaj tam, gdzie ziemia jest ciemniejsza niż powinna."; break;
                default: sReveal = "Prorok szepcze: ten, kto cię szuka, już tu był. Jego ślad biegnie w kierunku, w którym nie chciałeś patrzeć.";  break;
            }
            FloatingTextStringOnCreature("[Wizja] " + sReveal, oPC, FALSE);
            SendMessageToPC(oPC, "[Kodeks Wizji] " + sReveal);
            bApply = FALSE;
            break;
        }
        default:
            bApply = FALSE;
            break;
    }

    if(bApply)
    {
        eFx = ExtraordinaryEffect(eFx);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFx, oPC, fDur);
    }
}

// ----------------------------------------------------------------
// Category color
// ----------------------------------------------------------------

json DrmCategoryColor(string sCategory)
{
    if(sCategory == DRM_CAT_DEATH)    return NuiColor(160, 0,   160);
    if(sCategory == DRM_CAT_TRIUMPH)  return NuiColor(220, 180, 0);
    if(sCategory == DRM_CAT_CHAOS)    return NuiColor(220, 100, 0);
    if(sCategory == DRM_CAT_TRUTH)    return NuiColor(0,   200, 200);
    if(sCategory == DRM_CAT_SHADOW)   return NuiColor(140, 140, 180);
    if(sCategory == DRM_CAT_BLOOD)    return NuiColor(200, 30,  30);
    return NuiColor(200, 200, 200);
}

// ----------------------------------------------------------------
// NUI — Trance view (current vision in session)
// ----------------------------------------------------------------

json DrmBuildTranceView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fTextH = GetNuiScaleDimension(oPC, 240.0);

    // Progress label
    json jProgress = NuiLabel(NuiBind(DRM_BIND_PROGRESS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jProgress = NuiHeight(jProgress, GetNuiScaleDimension(oPC, 22.0));

    // Category label (colored)
    json jCategory = NuiLabel(NuiBind(DRM_BIND_CATEGORY),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCategory = NuiStyleForegroundColor(jCategory, NuiBind(DRM_BIND_CAT_COLOR));
    jCategory = NuiHeight(jCategory, GetNuiScaleDimension(oPC, 24.0));

    // Title label
    json jTitle = NuiLabel(NuiBind(DRM_BIND_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 30.0));

    // Vision text (scrollable group with NuiText)
    json jText = NuiText(NuiBind(DRM_BIND_TEXT), TRUE);
    json jTextGrp = NuiGroup(jText, TRUE, NUI_SCROLLBARS_Y);
    jTextGrp = NuiHeight(jTextGrp, fTextH);

    // Effect label
    json jFxLbl = NuiLabel(NuiBind(DRM_BIND_FX_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFxLbl = NuiHeight(jFxLbl, GetNuiScaleDimension(oPC, 22.0));
    jFxLbl = NuiStyleForegroundColor(jFxLbl, NuiColor(180, 180, 100));

    // Accept button
    json jAccept = NuiButton(NuiBind(DRM_BIND_ACC_LBL));
    jAccept = NuiId(jAccept, DRM_BTN_ACCEPT);
    jAccept = NuiEnabled(jAccept, NuiBind(DRM_BIND_ACC_ENA));
    jAccept = NuiWidth(jAccept, GetNuiScaleDimension(oPC, 200.0));
    jAccept = NuiHeight(jAccept, fBtnH);

    // Reject button
    json jReject = NuiButton(JsonString("Odrzuć"));
    jReject = NuiId(jReject, DRM_BTN_REJECT);
    jReject = NuiEnabled(jReject, NuiBind(DRM_BIND_REJ_ENA));
    jReject = NuiWidth(jReject, GetNuiScaleDimension(oPC, 120.0));
    jReject = NuiHeight(jReject, fBtnH);

    // Journal button
    json jJournal = NuiButton(JsonString("Kodeks ▼"));
    jJournal = NuiId(jJournal, DRM_BTN_JOURNAL);
    jJournal = NuiWidth(jJournal, GetNuiScaleDimension(oPC, 120.0));
    jJournal = NuiHeight(jJournal, fBtnH);

    // "Session done" row — shown instead of accept/reject when all visions processed
    json jDoneLbl = NuiLabel(
        JsonString("Wizja zakończona. Możesz zamknąć okno."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDoneLbl = NuiVisible(jDoneLbl, NuiBind(DRM_BIND_DONE_VIS));
    jDoneLbl = NuiHeight(jDoneLbl, fBtnH);

    // Trance controls row
    json jCtrlRow = JsonArray();
    jCtrlRow = JsonArrayInsert(jCtrlRow, jReject);
    jCtrlRow = JsonArrayInsert(jCtrlRow, NuiSpacer());
    jCtrlRow = JsonArrayInsert(jCtrlRow, jAccept);

    json jCtrlGrp = NuiRow(jCtrlRow);
    jCtrlGrp = NuiVisible(jCtrlGrp, NuiBind(DRM_BIND_TRANCE_VIS));

    // Footer row: journal toggle
    json jFootRow = JsonArray();
    jFootRow = JsonArrayInsert(jFootRow, jJournal);
    jFootRow = JsonArrayInsert(jFootRow, NuiSpacer());

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jProgress);
    jCol = JsonArrayInsert(jCol, jCategory);
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jTextGrp);
    jCol = JsonArrayInsert(jCol, jFxLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jCtrlGrp);
    jCol = JsonArrayInsert(jCol, jDoneLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jFootRow));

    float fContentW = GetNuiScaleDimension(oPC, 520.0);
    json jSide  = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMain  = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// NUI — Journal view (history of past sessions)
// ----------------------------------------------------------------

json DrmBuildJournalView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);

    // List row template
    json jDateLbl = NuiLabel(NuiBind(DRM_BIND_J_DATE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, GetNuiScaleDimension(oPC, 90.0));
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiBind(DRM_BIND_J_COLOR));

    json jCatLbl = NuiLabel(NuiBind(DRM_BIND_J_CAT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCatLbl = NuiWidth(jCatLbl, GetNuiScaleDimension(oPC, 80.0));
    jCatLbl = NuiStyleForegroundColor(jCatLbl, NuiBind(DRM_BIND_J_COLOR));

    json jTitleLbl = NuiLabel(NuiBind(DRM_BIND_J_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiBind(DRM_BIND_J_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jDateLbl);
    jCellRow = JsonArrayInsert(jCellRow, jCatLbl);
    jCellRow = JsonArrayInsert(jCellRow, jTitleLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, DRM_BTN_J_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(DRM_BIND_J_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    float fListH = GetNuiScaleDimension(oPC, 200.0);
    json jList = NuiList(jTmpl, NuiBind(DRM_BIND_J_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Body preview
    float fBodyH = GetNuiScaleDimension(oPC, 180.0);
    json jBody = NuiGroup(NuiText(NuiBind(DRM_BIND_J_BODY), FALSE), TRUE, NUI_SCROLLBARS_Y);
    jBody = NuiHeight(jBody, fBodyH);

    // Back button
    json jBack = NuiButton(JsonString("Powrót do transu"));
    jBack = NuiId(jBack, DRM_BTN_BACK);
    jBack = NuiWidth(jBack, GetNuiScaleDimension(oPC, 160.0));
    jBack = NuiHeight(jBack, fBtnH);

    json jFootRow = JsonArray();
    jFootRow = JsonArrayInsert(jFootRow, jBack);
    jFootRow = JsonArrayInsert(jFootRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiLabel(JsonString("Kodeks Wizji — Historia Transów"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jBody);
    jCol = JsonArrayInsert(jCol, NuiRow(jFootRow));

    float fContentW = GetNuiScaleDimension(oPC, 520.0);
    json jSide  = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMain  = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// Window: create / open
// ----------------------------------------------------------------

void DrmOpenWindow(object oPC)
{
    if(!DrmCooldownReady(oPC))
    {
        int nSecs = DrmCooldownRemaining(oPC);
        int nH    = nSecs / 3600;
        int nM    = (nSecs % 3600) / 60;
        SendMessageToPC(oPC, "[Kodeks Wizji] Pieczęć krwi pulsuje słabo... Trans możliwy za "
            + IntToString(nH) + "h " + IntToString(nM) + "min.");
        return;
    }

    if(NuiFindWindow(oPC, DRM_WIN_MAIN) != 0)
    {
        DrmFeedTranceView(oPC, NuiFindWindow(oPC, DRM_WIN_MAIN));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, DRM_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, DRM_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, DRM_W), GetNuiScaleDimension(oPC, DRM_H));

    // Close button in top bar
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, DRM_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow,
        NuiHeight(NuiLabel(JsonString("KODEKS WIZJI"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
            fBtnH));
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Swappable content group
    json jSwapGrp = NuiGroup(DrmBuildTranceView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, DRM_GRP_SWAP);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(DRM_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    // Draw a dark background rectangle (uses DrawList on the swap group).
    // (No hak image required — solid NUI background suffices.)

    int nToken = NuiCreate(oPC, jWin, DRM_WIN_MAIN, DRM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DRM_WIN_GEOM, jGeom);

    // Draw the visions and initialize session state.
    json jPool = DrmDrawVisions(oPC);
    SetLocalJson(oPC, DRM_LVAR_POOL,     jPool);
    SetLocalInt (oPC, DRM_LVAR_CURSOR,   0);
    SetLocalInt (oPC, DRM_LVAR_SAVED,    0);
    SetLocalJson(oPC, DRM_LVAR_ACCEPTED, JsonArray());

    DrmSetCooldown(oPC);
    DrmFeedTranceView(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — trance view binds
// ----------------------------------------------------------------

void DrmFeedTranceView(object oPC, int nToken)
{
    json jPool  = GetLocalJson(oPC, DRM_LVAR_POOL);
    int  nCursor = GetLocalInt(oPC, DRM_LVAR_CURSOR);
    int  nTotal  = JsonGetLength(jPool);
    int  bDone   = (nCursor >= nTotal);

    NuiSetBind(oPC, nToken, DRM_BIND_DONE_VIS,  JsonBool(bDone));
    NuiSetBind(oPC, nToken, DRM_BIND_TRANCE_VIS,JsonBool(!bDone));

    if(bDone)
    {
        NuiSetBind(oPC, nToken, DRM_BIND_PROGRESS, JsonString("Sesja transu zakończona."));
        NuiSetBind(oPC, nToken, DRM_BIND_CATEGORY, JsonString(""));
        NuiSetBind(oPC, nToken, DRM_BIND_TITLE,    JsonString(""));
        NuiSetBind(oPC, nToken, DRM_BIND_TEXT,     JsonString("Wizje zostały przyjęte lub odrzucone. Ich treść zachowana jest w Kodeksie."));
        NuiSetBind(oPC, nToken, DRM_BIND_FX_LBL,   JsonString(""));
        NuiSetBind(oPC, nToken, DRM_BIND_CAT_COLOR, NuiColor(200, 200, 200));
        NuiSetBind(oPC, nToken, DRM_BIND_ACC_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, DRM_BIND_REJ_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, DRM_BIND_ACC_LBL,   JsonString("Przyjmij Wizję"));

        if(!GetLocalInt(oPC, DRM_LVAR_SAVED))
        {
            SetLocalInt(oPC, DRM_LVAR_SAVED, 1);
            json jAccepted  = GetLocalJson(oPC, DRM_LVAR_ACCEPTED);
            json jVisionIds = JsonArray();
            int i;
            for(i = 0; i < nTotal; i++)
                jVisionIds = JsonArrayInsert(jVisionIds,
                    JsonInt(JsonGetInt(JsonObjectGet(JsonArrayGet(jPool, i), "id"))));
            DrmSaveSession(oPC, jVisionIds, jAccepted);
        }
        return;
    }

    json jVision  = JsonArrayGet(jPool, nCursor);
    string sCat   = JsonGetString(JsonObjectGet(jVision, "category"));
    string sTitle = JsonGetString(JsonObjectGet(jVision, "title"));
    string sText  = JsonGetString(JsonObjectGet(jVision, "text"));
    int nFxType   = JsonGetInt   (JsonObjectGet(jVision, "fx_type"));
    int nFxValue  = JsonGetInt   (JsonObjectGet(jVision, "fx_value"));

    NuiSetBind(oPC, nToken, DRM_BIND_PROGRESS,  JsonString("Wizja " + IntToString(nCursor + 1) + " z " + IntToString(nTotal)));
    NuiSetBind(oPC, nToken, DRM_BIND_CATEGORY,  JsonString(sCat));
    NuiSetBind(oPC, nToken, DRM_BIND_CAT_COLOR, DrmCategoryColor(sCat));
    NuiSetBind(oPC, nToken, DRM_BIND_TITLE,     JsonString(sTitle));
    NuiSetBind(oPC, nToken, DRM_BIND_TEXT,      JsonString(sText));
    NuiSetBind(oPC, nToken, DRM_BIND_FX_LBL,    JsonString(DrmEffectLabel(nFxType, nFxValue)));
    NuiSetBind(oPC, nToken, DRM_BIND_ACC_ENA,   JsonBool(TRUE));
    NuiSetBind(oPC, nToken, DRM_BIND_REJ_ENA,   JsonBool(TRUE));
    NuiSetBind(oPC, nToken, DRM_BIND_ACC_LBL,   JsonString("Przyjmij Wizję"));
}

// ----------------------------------------------------------------
// Feed — journal view binds
// ----------------------------------------------------------------

void DrmFeedJournalView(object oPC, int nToken)
{
    json jJournal = DrmGetJournal(oPC);
    int nCount    = JsonGetLength(jJournal);
    int nSel      = GetLocalInt(oPC, DRM_LVAR_JSEL);

    json jDates  = JsonArray();
    json jCats   = JsonArray();
    json jTitles = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow       = JsonArrayGet(jJournal, i);
        int  nAt        = JsonGetInt(JsonObjectGet(jRow, "session_at"));
        string sVidStr  = JsonGetString(JsonObjectGet(jRow, "vision_ids"));
        string sAidStr  = JsonGetString(JsonObjectGet(jRow, "accepted_ids"));

        // Build summary: list first vision's title and category
        json jVids   = JsonParse(sVidStr);
        string sCat  = "";
        string sTitle= "";
        if(JsonGetLength(jVids) > 0)
        {
            int nFirstId = JsonGetInt(JsonArrayGet(jVids, 0));
            json jV      = DrmGetVisionById(nFirstId);
            if(JsonGetType(jV) != JSON_TYPE_NULL)
            {
                sCat  = JsonGetString(JsonObjectGet(jV, "category"));
                sTitle= JsonGetString(JsonObjectGet(jV, "title"));
            }
        }

        // Count accepted
        json jAids = JsonParse(sAidStr);
        int  nAcc  = JsonGetLength(jAids);
        string sCountSuffix = " (" + IntToString(nAcc) + " przyjęte)";

        jDates  = JsonArrayInsert(jDates,  JsonString(DrmFormatDate(nAt)));
        jCats   = JsonArrayInsert(jCats,   JsonString(sCat));
        jTitles = JsonArrayInsert(jTitles, JsonString(sTitle + sCountSuffix));
        jColors = JsonArrayInsert(jColors, DrmCategoryColor(sCat));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, DRM_BIND_J_DATE,  jDates);
    NuiSetBind(oPC, nToken, DRM_BIND_J_CAT,   jCats);
    NuiSetBind(oPC, nToken, DRM_BIND_J_TITLE, jTitles);
    NuiSetBind(oPC, nToken, DRM_BIND_J_COLOR, jColors);
    NuiSetBind(oPC, nToken, DRM_BIND_J_ENC,   jEncs);
    NuiSetBind(oPC, nToken, DRM_BIND_J_COUNT, JsonInt(nCount));

    // Body preview for selected row
    string sBody = "";
    if(nSel >= 0 && nSel < nCount)
    {
        json jRow    = JsonArrayGet(jJournal, nSel);
        int  nAt     = JsonGetInt(JsonObjectGet(jRow, "session_at"));
        string sVids = JsonGetString(JsonObjectGet(jRow, "vision_ids"));
        string sAids = JsonGetString(JsonObjectGet(jRow, "accepted_ids"));
        json jVids   = JsonParse(sVids);
        json jAids   = JsonParse(sAids);

        sBody = "Sesja: " + DrmFormatDate(nAt) + "\n";
        sBody = sBody + "Wizje wylosowane:\n";
        int j;
        for(j = 0; j < JsonGetLength(jVids); j++)
        {
            int nVid = JsonGetInt(JsonArrayGet(jVids, j));
            json jV  = DrmGetVisionById(nVid);
            if(JsonGetType(jV) == JSON_TYPE_NULL) continue;
            string sCat   = JsonGetString(JsonObjectGet(jV, "category"));
            string sTit   = JsonGetString(JsonObjectGet(jV, "title"));
            int bAccepted = FALSE;
            int k;
            for(k = 0; k < JsonGetLength(jAids); k++)
            {
                if(JsonGetInt(JsonArrayGet(jAids, k)) == nVid) { bAccepted = TRUE; break; }
            }
            sBody = sBody + "  [" + (bAccepted ? "Przyjęta" : "Odrzucona") + "] "
                  + sCat + " — " + sTit + "\n";
        }
    }
    else
    {
        sBody = "Wybierz sesję z listy, aby zobaczyć szczegóły.";
    }
    NuiSetBind(oPC, nToken, DRM_BIND_J_BODY, JsonString(sBody));
}
