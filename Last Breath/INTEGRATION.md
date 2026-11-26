# Last Breath — Integration Guide

## Co to robi

Pozwala graczom pochłaniać esencję konających potężnych istot i przechowywać ją
w kryształowych fiolkach. Wypicie esencji daje tymczasowy (5 min) potężny efekt
zależny od natury pokonanej istoty. Zbiór trwa maksymalnie 7 dni, po czym gnije.

| Typ esencji   | Efekt                                               |
|---------------|-----------------------------------------------------|
| Wojownik      | +4 STR, +20 HP tymczasowych                        |
| Bestia        | +4 CON, +30% prędkości ruchu                       |
| Nieumarły     | Immunity: Fear, Disease; 50% odporność na negative |
| Demon         | 50% odporność na fire, +3 atak, +2 fire damage     |
| Boskie        | Regeneracja 2 HP/6s, +3 AC, Immunity: Poison       |
| Arkaniczne    | +4 INT, +2 WIS, +3 Will save                       |

## Zależności

- **NWN:EE** (natywne NUI, `SqlPrepareQueryCampaign`)
- Brak NWNX
- Campaign DB: `last_breath` (tworzona automatycznie)

## Pliki

```
Last Breath/Scripts/
  sql_lbr.nss        — schemat SQL + zapytania
  lib_lbr_def.nss    — stałe, ID bindów, deklaracje
  lib_lbr.nss        — rdzeń logiki + budowa okna NUI
  lib_lbr_ev.nss     — handler eventów NUI (OnNUIEvent)
  sys_on_load.nss    — inicjalizacja SQL (OnModuleLoad)
  sys_on_enter.nss   — czyszczenie zgniłych fiolek (OnClientEnter)
  sys_on_target.nss  — obsługa targetowania pochłaniania (OnPlayerTarget)
  test_lbr.nss       — OnUsed na placeable: otwiera okno zbioru
```

## Jak włączyć w istniejącym module

1. **OnModuleLoad** — dodaj wywołanie `ExecuteScript("sys_on_load", OBJECT_SELF)` lub
   dołącz `#include "lib_lbr_def"` i wywołaj `LbrCreateTables()`.

2. **OnClientEnter** — dołącz `#include "lib_lbr_def"` i wywołaj:
   ```
   if(GetIsPC(GetEnteringObject())) LbrClearDecayed(GetEnteringObject());
   ```

3. **OnPlayerTarget** — dołącz `#include "lib_lbr"` i na początku handlera dodaj:
   ```
   if(GetLocalInt(oPC, LBR_LVAR_TARGETING))
   {
       LbrHarvestEssence(oPC, GetTargetingModeSelectedObject());
       LbrOpenWindow(oPC);
       return;
   }
   ```
   gdzie `oPC = GetLastPlayerToSelectTarget()`.

4. **Otwieranie okna** — z dowolnego konwersa NPC, skryptu rozmowy lub przedmiotu:
   ```
   #include "lib_lbr"
   LbrOpenWindow(GetPCSpeaker()); // lub inny oPC
   ```

5. **Fiolka (`lbr_vial`)** — stwórz w toolsecie Miscellaneous Item z tagiem `lbr_vial`.
   Jedna fiolka = jeden pochłon (stackable). Można sprzedawać u alchemika, zdobywać
   w skrzyniach lub dawać graczom startowo.

## Co celowo pominięto

- Trwałość efektów między restartami serwera — efekty są czysto sesyjne;
  implementacja wymagałaby `OnClientEnter` z ponownym aplikowaniem, co
  mogłoby kolidować z innymi systemami efektów.
- Klasyfikacja przez CR (poza minimalnym progiem) — typ esencji pochodzi z rasy
  i klasy, nie z siły, żeby uniknąć sytuacji kiedy wysokocr-bestia daje "arkaniczne".
- Animacja pochłaniania dedykowana moduł-specificzna — użyto standardowych VFX.
