# Bloodline — Przebudzone Dziedzictwo

## Skrypty

| Plik | Hook modułu |
|---|---|
| `scripts/sys_on_load.nss` | **OnModuleLoad** — tworzy tabelę SQLite |
| `scripts/sys_on_enter.nss` | **OnClientEnter** — przywraca efekty pasywne po relogu |
| `scripts/test_bld.nss` | OnUsed na placeable "Blood Font" — otwiera UI |
| `scripts/lib_bld_ev.nss` | Skrypt NUI podany jako `NuiCreate(..., "lib_bld_ev")` |

Pozostałe pliki są bibliotekami include i nie podpinają się bezpośrednio.

## Podpięcie hooków

### OnModuleLoad
```nss
#include "sql_bld"
// ... inne inicjalizacje ...
BldCreateTables();
```

### OnClientEnter
```nss
#include "lib_bld"
object oPC = GetEnteringObject();
if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
{
    BldEnsureRecord(oPC);
    BldApplyEffects(oPC);
}
```

## Baza danych

Kampania SQLite: `bloodline`  
Tabela: `bld_chars (uuid TEXT PK, bloodline_type INT, purity INT, last_ritual INT)`

Plik .sqlite tworzony automatycznie przez NWN:EE w katalogu kampanii.

## NWNX

Brak zależności od NWNX. Wymaga wyłącznie NWN:EE (NUI + SupernaturalEffect + TagEffect + RemoveEffectByTag + SqlPrepareQueryCampaign).

## Uruchomienie testu

1. Dodaj placeable do modułu, ustaw skrypt OnUsed na `test_bld`.
2. Dodaj `sys_on_load` do OnModuleLoad i `sys_on_enter` do OnClientEnter.
3. Uruchom moduł. Podejdź do placeable i użyj go — otworzy się UI dziedzictwa.
4. Wybierz linię krwi z listy i kliknij "Przebudzic Krew".
5. Rytuał: upewnij się, że postać ma dość HP i złota, kliknij "Odpraw Rytual Krwi".

## Co celowo pominięto

- Ikony graficzne per bloodline (wymagałyby dedykowanego HAK; zamiast tego użyto styled labels).
- Mechanika "przebudzenia wyglądu" (zmiana koloru skóry / tattoo) — to zależy od struktury modułu
  i nakłada się z modułem Appearance. Można zintegrować przez wywołanie `BldGetCurrentTier()`
  w sys_on_enter.nss Appearance.
- Opcje dialogowe NPC reagujące na krew — to warstwa treści modułu, nie systemu.
- Możliwość cofnięcia wyboru linii — projektowo nieodwracalne (dark fantasy).
