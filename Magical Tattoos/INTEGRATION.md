# Magical Tattoos — Integracja z Modułem

## Opis

System magicznych tatuaży pozwala graczom nanosić trwałe pieczęcie na 5 miejsc
ciała (Głowa, Szyja, Piersi, Lewe Ramię, Prawe Ramię). Każdy tatuaż daje
mechaniczny bonus (AB, AC, umiejętności, rzuty, odporność na ogień). Niektóre
wzory są przeklęte — silniejszy efekt kosztem kary. Efekty są persistentne przez
bazę SQLite i re-aplikowane przy każdym wejściu do modułu.

## Hooki do podpięcia

| Zdarzenie                | Skrypt                         |
|--------------------------|--------------------------------|
| OnModuleLoad             | `sys_on_load`                  |
| OnClientEnter            | `sys_on_enter`                 |
| Placeable OnUsed         | `test_tatu` (pracownia)        |

Jeśli masz już własne `OnModuleLoad` / `OnClientEnter`, wywołaj funkcje z tych
skryptów na końcu istniejącego handlera:

```nwscript
// W OnModuleLoad:
#include "lib_tatu_def"
// ...
TatuCreateTables();
TatuSeedDesigns();

// W OnClientEnter:
#include "lib_tatu"
// ...
object oPC = GetEnteringObject();
if(GetIsPC(oPC)) TatuApplyEffectsForPC(oPC);
```

## Skrypty do skopiowania do modułu / haka

Wszystkie pliki z folderu `Scripts/`:
- `lib_nui.nss`, `lib_nui_utility.nss` — narzędzia NUI (mogą już istnieć)
- `sql_tatu.nss` — schemat SQL i zapytania
- `lib_tatu_def.nss` — stałe, helpery, forward deklaracje
- `lib_tatu.nss` — logika, UI, efekty
- `lib_tatu_ev.nss` — handler zdarzeń NUI (wpisać jako Event Script przy NuiCreate)
- `sys_on_load.nss`, `sys_on_enter.nss`, `test_tatu.nss` — hooki

## Placeable — Pracownia Tatuaży

Utwórz dowolny Placeable z OnUsed = `test_tatu`. Rekomendowany tag: `pracownia_tatu`.
Umieść przy NPC Tatuażysty lub w osobnym pomieszczeniu.

## Atrament — wymagane itemy

Każdy wzór wymaga specjalnego attramentu (itemu po tagu). Utwórz w palecie
modułu następujące Misc Small Itemy:

| Tag           | Nazwa wyświetlana       | Użycie w projektach          |
|---------------|-------------------------|------------------------------|
| `ink_crow`    | Atrament Kruczy         | Szpon Wrony (HEAD +2 AB)     |
| `ink_sight`   | Atrament Wizji          | Oko Proroka (HEAD +3 Spot)   |
| `ink_bile`    | Atrament Żółciowy       | Pieczęć Zarazy (NECK)        |
| `ink_bone`    | Atrament Kostny         | Kość Milczenia (NECK)        |
| `ink_stone`   | Atrament Kamienny       | Serce Kamienia (CHEST)       |
| `ink_iron`    | Atrament Żelazny        | Łańcuch Obrońcy (CHEST)      |
| `ink_ash`     | Atrament Popielny       | Blizna Ognia (CHEST)         |
| `ink_shadow`  | Atrament Cienia         | Skrzydła Nocy / Znak Złodzieja |
| `ink_blood`   | Atrament Krwawy         | Pięść Tyranta (RIGHT)        |

Możesz rozdawać atrament jako loot z potworów, drop w skrzynkach lub sprzedawać
go przez NPC-handlarza.

## Zależności NWNX

Brak. Moduł używa wyłącznie standardowego API NWScript (NUI, SQL Campaign, Effects).

## Dostosowanie — dodawanie wzorów

Wywołaj `TatuSeedOne(...)` w `sys_on_load.nss` po istniejących 10 wpisach.
Tabela `tatu_designs` używa `INSERT OR IGNORE`, więc ponowne uruchomienie
modułu nie nadpisze istniejących danych.

## Usuwanie tatuażu

Koszt: 150 zł + 5 obrażeń magicznych (parametry `TATU_REMOVE_GOLD` i
`TATU_REMOVE_DMG` w `lib_tatu_def.nss`). Kliknięcie miejsca na mapie ciała
(jeśli ma tatuaż) aktywuje przycisk „Wypal Tatuaż".

## Co celowo pominięto

- Własne obrazki/ikony tatuaży (brak zasobów graficznych w repozytorium)
- Animator wizualny (efekt VFX nakładany na PC przy nanoszeniu)
- Ograniczenie wzorów do klas postaci
- GM-narzędzie do dodawania wzorów przez UI (GM musi edytować SQL ręcznie)
