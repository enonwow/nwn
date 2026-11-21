# Egzorcyzmy — Instrukcja integracji

## Co to robi

Moduł dodaje pełny system opętania demonami i rytuał egzorcyzmu z mini-grą NUI.
Postacie mogą zostać opętane przez demony lub duchy na trzech poziomach intensywności.
Egzorcysta otwiera okno rytuału i musi kliknąć 4 symbole w losowej kolejności w ciągu 35 sekund.

## Poziomy opętania

| Poziom | Nazwa            | Kary                                       |
|--------|------------------|--------------------------------------------|
| 0      | Czysta dusza     | brak                                       |
| 1      | Szepty demonów   | -2 CHA, szeptane komunikaty co ~60s        |
| 2      | Opanowanie       | -2 CHA, -2 WIS, -15% ruch                 |
| 3      | Manifestacja     | -2 CHA, -2 WIS, -4 STR, aura wizualna, demon mówi przez postać |

## Hooki do podpięcia

### OnModuleLoad
Podepnij `sys_on_load` — tworzy tabelę SQLite.

### OnClientEnter
Podepnij `sys_on_enter` — przywraca efekty opętania po ponownym logowaniu.

### OnModuleHeartbeat
Podepnij `sys_module_hb` lub dodaj wywołanie jego `main()` do istniejącego HB:
```nss
#include "sys_module_hb"
// w istniejącym OnModuleHeartbeat dodaj na końcu:
// ExrcDoHeartbeat();  // lub wywołaj script bezpośrednio przez ExecuteScript
```

## NWNX

Brak wymagań NWNX — moduł korzysta wyłącznie z `SqlPrepareQueryCampaign`.

## Pliki do HAK

Ikony symboli rytuału (TGA 32×32 lub 64×64, bez alpha):

| Stała             | Resref       | Opis                        |
|-------------------|--------------|-----------------------------|
| `EXRC_ICON_0`     | `is_blessng` | Symbol Krzyża (Bless)       |
| `EXRC_ICON_1`     | `is_holywrd` | Symbol Słowa Świętego       |
| `EXRC_ICON_2`     | `is_divinef` | Symbol Boskiej Tarczy       |
| `EXRC_ICON_3`     | `is_recallp` | Symbol Cofnięcia            |
| `EXRC_ICON_4`     | `is_resurr`  | Symbol Zmartwychwstania     |
| `EXRC_ICON_5`     | `is_death2`  | Symbol Pieczęci Śmierci     |

Stałe te są zdefiniowane w `lib_exrc_def.nss` — zmień resrefy jeśli używasz własnych grafik.

## Przedmiot: Święta Woda

Stwórz item z tagiem `exrc_holy_water` (zdefiniowanym w `EXRC_HOLY_WATER_TAG`).
Koszt rytuału = poziom opętania celu (1 fiolka dla poziomu 1, 2 dla 2, 3 dla 3).

## Jak zadać opętanie z zewnętrznego skryptu

```nss
#include "lib_exrc"

// Opęta gracza na poziomie 2
ExrcInflictPossession(oPC, EXRC_LEVEL_DOMINATED, "Baltazar Wieczny");

// Sprawdź poziom opętania
int nLevel = ExrcGetLevel(oPC);

// Czyste z poziomu skryptu (np. po śmierci / wskrzeszeniu)
ExrcSavePossession(oPC, EXRC_LEVEL_CLEAN, "");
ExrcRemovePossessionEffects(oPC);
```

## Jak otworzyć okno rytuału

```nss
#include "lib_exrc"

// Egzorcysta oPC bada cel oTarget
ExrcOpenDetectWindow(oPC, oTarget);

// Lub bezpośrednio otwiera rytuał:
ExrcOpenRitualWindow(oPC, oTarget);
```

## Testowanie

1. Umieść placeable z OnUsed = `test_exrc` w obszarze testowym.
2. Naciśnij go jako zwykły gracz — postać zostaje opętana (poziom 1).
3. Naciśnij ponownie — otwiera się okno detekcji z przyciskiem egzorcyzmu.
4. Naciśnij jako DM — otwiera detekcję na najbliższego gracza.
5. Upewnij się, że masz `exrc_holy_water` w ekwipunku (1 fiolka dla poziomu 1).

## Co celowo pominięto

- Opętanie NPC (mechanika dotyczy tylko PC).
- Automatyczne rozprzestrzenianie opętania między graczami (25% szansa przy niepowodzeniu rytuału dotyczy tylko eskalacji poziomu).
- Odporność na opętanie (można dodać check na spell resistance lub atrybuty WIS).
- Leczenie przez smierć/zmartwychwstanie (decyzja designerska — można dodać hook OnPlayerDeath).
