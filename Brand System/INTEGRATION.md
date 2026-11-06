# Brand System — Integracja

## Co to robi

System piętna (`brand`) śledzi trwałe znamiona wypalane lub rytualnie nakładane
na postacie graczy. Każde piętno zajmuje jedno z siedmiu miejsc na ciele i niesie
konkretne konsekwencje mechaniczne (zmiany cech, umiejętności, odporności)
oraz społeczne (flagi lokalne widoczne dla skryptów strażników, sklepikarzy, kapłanów).
Gracz może ukryć piętno pod zbroją (efekty społeczne nieaktywne, mechaniczne pozostają)
i podjąć kosztowną próbę usunięcia (1000 sz + rzut Leczenia DC 20).

## Wymagane hooki w module

| Zdarzenie modułu          | Skrypt               | Uwaga                         |
|---------------------------|----------------------|-------------------------------|
| OnModuleLoad              | `sys_on_load`        | Tworzy tabele SQLite          |
| OnClientEnter             | `sys_on_enter`       | Reaplikuje efekty po loginie  |
| OnPlayerRestFinished      | `sys_on_rest`        | Reaplikuje efekty po odpoczynku|
| OnNuiEvent                | `lib_brand_ev`       | Obsługuje kliknięcia UI       |

Jeżeli moduł posiada już centralny skrypt dla danego zdarzenia, wywołaj odpowiednią
funkcję z tego modułu wewnątrz swojego głównego hooka:

```nss
// Przykład dla OnClientEnter
#include "sys_on_enter"

void main()
{
    // ... twój kod ...
    BrandHandleOnEnter(); // wrapper — lub bezpośrednio BrandApplyEffects(GetEnteringObject())
}
```

## Zależności

- **NWN:EE** — wymagane API: `NuiCreate`, `NuiSetBind`, `SqlPrepareQueryCampaign`,
  `TagEffect`, `GetEffectTag`, `EffectDamageResistance`, `EffectSkillIncrease`.
- **Brak NWNX** — moduł działa na czystym NWN:EE bez żadnych pluginów.
- **SQLite Campaign DB** — dane przechowywane w pliku `brand.sqlite` (kampania `"brand"`).

## Placeables

Umieść na mapie placeable z OnUsed = `test_brand`:

| Zmienna lokalna     | Typ  | Opis                                              |
|---------------------|------|---------------------------------------------------|
| `BRAND_TEST_TYPE`   | int  | Jeżeli > 0, MG nakłada piętno tego typu na PC    |
| `BRAND_TEST_LOC`    | int  | Lokalizacja (0–6), domyślnie 2 = pierś            |
| `BRAND_TEST_NAME`   | str  | Własna nazwa piętna (opcjonalnie)                 |
| `BRAND_TEST_ORIGIN` | str  | Własne origin (opcjonalnie)                       |
| `BRAND_DEMO_AUTO`   | int  | 1 = automatycznie nanosi przykładowe piętno na PC|

Zalecana nazwa placeabla: **Lustro Duszy** (tag: `soul_mirror`).

## Nakładanie piętna przez skrypt

```nss
#include "lib_brand"

// Naniesienie Pieczęci Infernalnej po podpisaniu paktu
void ScenePactSigned(object oBrander, object oBranded)
{
    BrandApply(oBrander, oBranded,
        BRAND_LOC_LEFT_HAND,
        BRAND_TYPE_INFERNAL,
        "Pieczen Czarnego Tronu",
        "Podpisano krwia w Dolinie Cierpienia.");
}
```

## Flagi społeczne (sprawdzanie przez inne skrypty)

Po wywołaniu `BrandApplyEffects(oPC)` na postaci ustawiane są zmienne lokalne:

| Zmienna                | Znaczenie                                                    |
|------------------------|--------------------------------------------------------------|
| `BRAND_FX_SLAVE`       | 1 = widoczne piętno pańszczyźniane — NPC odmawiają usług    |
| `BRAND_FX_CRIMINAL`    | 1 = widoczne piętno wyrzutka — strażnicy stają się wrodzy   |
| `BRAND_FX_HERETIC`     | 1 = widoczne piętno heretyka — kapłani odmawiają uzdrowienia |
| `BRAND_FX_HUNTED`      | 1 = znacznik łowcy — NPC-owie mogą zaalarmować  łowców nagród|
| `BRAND_FX_INFERNAL`    | 1 = widoczna Pieczęć Infernalna — triggery świętych miejsc  |
| `BRAND_FX_BLOOD`       | 1 = widoczna Pieczęć Krwi — frakcje krwi rozpoznają cię     |
| `BRAND_FX_EXILE`       | 1 = widoczny stygmat wygnania — straż odmawia pomocy         |

Przykład użycia w skrypcie strażnika:
```nss
if(GetLocalInt(oPC, "BRAND_FX_CRIMINAL") || GetLocalInt(oPC, "BRAND_FX_EXILE"))
    ChangeToStandardFaction(oPC, STANDARD_FACTION_HOSTILE);
```

## Typy piętna i efekty mechaniczne

| Typ | Nazwa                  | Efekty mechaniczne                    | Efekty społeczne            |
|-----|------------------------|---------------------------------------|-----------------------------|
| 1   | Znamię Pańszczyźny     | STR -2, CHA -4                        | `BRAND_FX_SLAVE`            |
| 2   | Piętno Wyrzutka        | Perswazja -4, Blef -2                 | `BRAND_FX_CRIMINAL`         |
| 3   | Piętno Heretyka        | MĄD -2                                | `BRAND_FX_HERETIC`          |
| 4   | Znacznik Łowcy         | Strzeganie +2, Słuch +2               | `BRAND_FX_HUNTED`           |
| 5   | Pieczęć Infernalna     | Odporność ogień 5, MĄD -2             | `BRAND_FX_INFERNAL`         |
| 6   | Pieczęć Krwi           | KON +2                                | `BRAND_FX_BLOOD`            |
| 7   | Stygmat Wygnańca       | Skradanie +2, Ukrywanie +2, CHA -2    | `BRAND_FX_EXILE`            |

## Co celowo pominięto

- **Flaring Infernal Brand** — efekt obrażeń ogniowych w świętych miejscach wymaga
  triggerów (OnEnter świętej strefy). Dodaj do triggerów:
  `if(GetLocalInt(oPC, "BRAND_FX_INFERNAL")) ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(d6(2), DAMAGE_TYPE_FIRE), oPC);`
- **Efekt Blood Brand przy niskim HP** — trigger OnDamaged: gdy HP < 25%,
  tymczasowo daj STR +4 (fury krwi) na 10 rund.
- **HAK / obrazki** — brak własnych assetów; UI używa tylko tekstu NUI.
  Opcjonalnie dodaj ikonę placeable i grafikę tła przez nazwę resrefa w hak.
- **NPC nadający piętno** — nie zawiera dialoga NPC-a; nakładanie przez skrypt
  lub DM-a przez zmienna na placeablu jest wystarczające dla demo.
