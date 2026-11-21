# Portrait Gallery — Integration Guide

## Co to robi

Moduł śledzi **magiczne portrety** postaci w trwałej galerii. Każdy portret gromadzi
„mrok" proporcjonalnie do popełnianych przez właściciela czynów i zmienia kolor opisu
w NUI. Czysty portret inspiruje (kontemplacja → +1 do rzutów obronnych i +2 Persuade
przez 1 godz.); zniszczony portret nakłada klątwę (−1 do rzutów obronnych na stałe,
dopóki nie zostanie naprawiony). Portrety poległych postaci można oznaczyć jako
epitafia (tylko MG).

## Mechanika w skrócie

| Próg mroku | Opis      | Kolor NUI                  |
|-----------|-----------|----------------------------|
| 0–20      | Czysty    | ciepłe złoto (200,180,110) |
| 21–50     | Zmącony   | brudne żółto (160,130,50)  |
| 51–80     | Skażony   | ciemna purpura (150,60,170)|
| 81–100    | Przeklęty | głęboka czerwień (210,40,40)|

Stany portretu: `0` = normalny, `1` = zniszczony, `2` = epitafium.

## Wymagane hooki modułu

| Zdarzenie             | Skrypt            |
|-----------------------|-------------------|
| `OnModuleLoad`        | `sys_on_load`     |
| `OnClientEnter`       | `sys_on_enter`    |

Jeśli masz już własne skrypty `OnModuleLoad` / `OnClientEnter`, dodaj wywołania:

```nss
// OnModuleLoad:
#include "lib_por_def"
// ...
PorCreateTables();

// OnClientEnter:
#include "lib_por"
// ...
PorCheckOnEnter(GetEnteringObject());
```

## Pliki skryptów

```
Portrait Gallery/Scripts/
  lib_por_def.nss   — stałe, IDs bindów, forward deklaracje
  sql_por.nss       — schemat SQLite + wszystkie zapytania
  lib_por.nss       — logika, efekty, budowanie NUI, funkcje feed
  lib_por_ev.nss    — handler eventów NUI (przypisz do lib_por_ev)
  sys_on_load.nss   — tworzy tabele przy starcie modułu
  sys_on_enter.nss  — sprawdza stan portretu przy wejściu gracza
  test_por.nss      — skrypt OnUsed dla placeable testowego
  lib_nui.nss       — wspólna biblioteka NUI (kopiowana z innych modułów)
  lib_nui_utility.nss — pomocnicze funkcje NUI
```

## Baza danych

**Campaign DB:** `"portraits"` (tworzona automatycznie przez `PorCreateTables()`).

Tabela `por_portraits`:

| Kolumna        | Typ      | Opis                                         |
|----------------|----------|----------------------------------------------|
| `id`           | INTEGER  | klucz główny, auto-increment                 |
| `owner_uuid`   | TEXT     | UUID postaci (UNIQUE)                        |
| `owner_name`   | TEXT     | imię w chwili komisji                        |
| `owner_class`  | TEXT     | klasa w chwili komisji                       |
| `owner_level`  | INTEGER  | poziom w chwili komisji                      |
| `owner_align`  | TEXT     | wyrównanie w chwili komisji                  |
| `shadow_score` | INTEGER  | 0–100, rośnie z ciemnymi czynami             |
| `state`        | INTEGER  | 0=normalny, 1=zniszczony, 2=epitafium        |
| `motto`        | TEXT     | inskrypcja podana przez gracza               |
| `created_at`   | INTEGER  | unix timestamp komisji                       |
| `last_buff_at` | INTEGER  | unix timestamp ostatniej kontemplacji        |

## Publiczne API

```nss
// Dodaj mrok do portretu postaci po ciemnym czynie.
// Wywoływalne z dowolnego skryptu modułu.
void PorAddShadow(object oPC, int nAmount);
// Przykład — wywołaj po zabójstwie niewinnego:
PorAddShadow(oPC, 3);

// Oznacz portret jako epitafium (np. w OnPlayerDeath):
void PorMarkMemorial(object oPC);

// Sprawdź i (re)aplikuj klątwę/buffy przy wejściu:
void PorCheckOnEnter(object oPC);
```

## Zależności NWNX

**Brak.** Moduł korzysta wyłącznie z vanilla NWN:EE API.

## Jak umieścić galerię w świecie

1. Umieść placeable w obszarze modułu (np. NWN Toolset → Interior Fixtures →
   Paintings and Tapestries lub dowolny inny).
2. Przypisz skrypt `test_por` do zdarzenia `OnUsed` placeabla.
3. Dodaj do HAK pliki graficzne (`por_frame`, itp.) jeśli chcesz własne tło galerii.
   Bez nich okno działa bez grafiki tła.

## Co celowo pominięto

- **Grafika portretów:** NWN:EE nie pozwala renderować dynamicznie generowanych
  obrazów. Stan portretu wyraża się opisem tekstowym i kolorem NUI.
- **Automatyczne zniszczenie portretu:** nie ma domyślnego hoooku `OnPlayerDeath`
  niszczącego portret — decyzja należy do MG (przycisk `Epitafium [MG]` w galerii).
  Aby włączyć automatykę, wywołaj `PorMarkMemorial(oPC)` z własnego `OnPlayerDeath`.
- **Eksport .mod:** środowisko CI nie ma dostępu do NWN Toolset; użyj skryptu
  `test_por.nss` na placeablu w istniejącym module deweloperskim.
