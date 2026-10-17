# Inkantator — Integracja w module NWN:EE

## Opis

Warsztat kaligraficzny pozwalający graczom wytwarzać magiczne zwoje przez
test Magii Zaklęć. Cztery podstawowe formuły dostępne od razu; cztery
zaawansowane odkrywane przez przedmioty-tomy. Wynik zależy od rzutu k20
plus bonus umiejętności — krytyczna porażka zadaje obrażenia, wyjątkowy
sukces produkuje dwa zwoje.

## Hooki modułu

| Zdarzenie | Skrypt |
|---|---|
| OnModuleLoad | `sys_on_load` |
| OnClientEnter (lub OnPlayerEnter) | `sys_on_enter` |
| OnUsed (na placeablu) | `test_ink` |

## Wymagane itemy w palecie modułu

Stwórz poniższe itemy (tagi muszą być dokładne; zalecane stackowalne miscellaneous):

| Tag | Opis |
|---|---|
| `ink_parchment` | Pergamin (stackowalny) |
| `ink_vial_blue` | Szafirowy atrament (stackowalny) |
| `ink_vial_red` | Rubinowy atrament (stackowalny) |
| `ink_vial_black` | Obsydianowy atrament (stackowalny) |
| `ink_bone_powder` | Proch kości (stackowalny; dobry drop z nieumarłych) |
| `ink_moonstone` | Kamień księżycowy |
| `ink_blood_vial` | Fiolka krwi |

## Odkrywanie zaawansowanych formuł (ID 5–8)

Utwórz item z tagiem `ink_spell_tome` i ustaw zmienną lokalną int
`INK_TOME_FORMULA` = ID formuły (5, 6, 7 lub 8).

W skrypcie `OnActivateItem` (lub `OnUsed` na itemie) wywołaj:

```nss
#include "lib_ink_def"

void main()
{
    object oPC   = GetItemActivator();
    object oItem = GetItemActivated();
    if(GetTag(oItem) != INK_TAG_TOME) return;

    int nFormId = GetLocalInt(oItem, INK_VAR_TOME_ID);
    if(nFormId < INK_FORM_FIRST_ADV || nFormId > INK_FORMULA_COUNT) return;

    if(InkIsFormulaKnown(oPC, nFormId))
    {
        SendMessageToPC(oPC, "[Inkantator] Tę formułę już znasz.");
        return;
    }

    InkLearnFormula(oPC, nFormId);
    SendMessageToPC(oPC, "[Inkantator] Odczytujesz zakazane słowa... Formuła \""
        + InkGetFormulaName(nFormId) + "\" zapisana w twoim grimuarze.");
    DestroyObject(oItem);
}
```

## Weryfikacja resrefów zwojów

Resrefy w `InkGetFormulaScrollResref()` (`lib_ink_def.nss`) to standardowe
NWN:EE — zweryfikuj, że istnieją w twoim module (zwłaszcza po EE patchach):

| Formuła | Resref | Zaklęcie |
|---|---|---|
| Mgiełka Umysłu | `nw_sc_clrcomp` | Clarity |
| Pieczęć Ochronna | `nw_sc_protcevl` | Protection from Evil |
| Zaklęcie Grozy | `nw_sc_causfe` | Cause Fear |
| Kwas Melfego | `nw_sc_melf` | Melf's Acid Arrow |
| Dotyk Wampira | `nw_sc_vamptouc` | Vampiric Touch |
| Pieczęć Prawdy | `nw_sc_dominate` | Dominate Person |
| Klątwą Objęty | `nw_sc_bestwo` | Bestow Curse |
| Szept Ciemności | `nw_sc_darkns` | Darkness |

## Zależności NWNX

Brak — moduł korzysta wyłącznie z wbudowanego SQLite NWN:EE
(`SqlPrepareQueryCampaign`) i standardowego API NUI.

## Szybki test

1. Podepnij hooki.
2. Wejdź na serwer — `sys_on_enter` nada formuły 1–4.
3. Dodaj do ekwipunku `ink_parchment` (x1) i `ink_vial_blue` (x1).
4. Użyj placeabla z `test_ink` — otworzy się okno Inkantator.
5. Wybierz „Mgiełka Umysłu" → „Zapisz Zaklęcie".
6. Sprawdź ekwipunek — przy sukcesie pojawi się zwój Clarity.

## Celowo pominięto

- UI ikonki dla składników (brak customowego HAK — użyj standardowych ikon).
- Craftowanie składników (atramentów/pergaminów) — to zakres osobnego modułu
  (np. Alchemy / Herbarium).
- Cooldown między inkantacjami — łatwo dodać przez `GetLocalInt(oPC, "INK_CD")`.
