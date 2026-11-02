# Watchfire — Integration Guide

## Co to jest

System obozu i odpoczynku. Gracz podchodzi do ogniska (placeable), klika „Użyj" i otwiera panel z trzema zakładkami: Ognisko (odpoczynek), Kuchnia (gotowanie z ingrediencji) i Dziennik (historia sesji).

## Hooki do podpięcia w module

| Zdarzenie modułu | Skrypt          | Uwagi                          |
|------------------|-----------------|--------------------------------|
| OnModuleLoad     | `sys_on_load`   | Opcjonalny; nie robi nic krytycznego |
| OnClientEnter    | `sys_on_enter`  | Tworzy tabelę SQL dla gracza   |

Jeśli moduł ma już `OnClientEnter`, wywołaj `WfCreateTables(GetEnteringObject())` z poziomu istniejącego skryptu zamiast podpinać plik bezpośrednio.

## Placeable ogniska

1. Utwórz placeable `Campfire` (lub dowolny, klimatyczny odpowiednik).
2. Ustaw `OnUsed = test_wf` (lub własny skrypt wywołujący `WfOpenWindow(oPC, OBJECT_SELF)`).
3. Opcjonalnie: ustaw lokalną zmienną int `WF_DANGER` na 0–5, gdzie 0 = spokojny obszar, 5 = śmiertelne zagrożenie. Domyślnie 0.

## Ingrediencje (gotowanie)

Składniki sprawdzane są przez tag przedmiotu (`GetItemPossessedBy`). Dodaj do HAK przedmioty z tagami:

| Tag             | Opis                      |
|-----------------|---------------------------|
| `wf_herb_fire`  | Zioło ogniste             |
| `wf_herb_heal`  | Zioło lecznicze           |
| `wf_herb_mind`  | Zioło mentalne            |
| `wf_herb_power` | Korzeń mocy               |
| `wf_meat`       | Kawał mięsa               |
| `wf_ration`     | Racja żywnościowa         |
| `wf_dark_water` | Mroczna woda źródlana     |

Skrypt `test_wf.nss` tymczasowo tworzy te przedmioty z resrefa `nw_it_mabltherb` — wystarczy do testów, ale nie jest ładny wizualnie. Dla pełnego wdrożenia stwórz własne przedmioty z właściwymi ikonami.

## Zależności NWNX

Brak. Moduł korzysta wyłącznie z NWScript + NUI + SQLite (per-character `SqlPrepareQueryObject`).

## Dane persystentne

Dane zapisywane są na obiekcie postaci (`.bic`/playerdb) za pomocą `SqlPrepareQueryObject`. Tabela `wf_sessions` tworzona jest automatycznie przy pierwszym użyciu. Brak globalnego schematu kampanii.

## Mechanikat zdarzeń odpoczynku

- **Krótki odpoczynek** (przez wywołanie `WfDoRest_Short`): +2h czasu, 25% PŻ max.
- **Długi odpoczynek**: +8h czasu, pełne PŻ (50% jeśli warta aktywna).
- **Spotkanie**: rzut k20 vs. DC = `8 + Zagrożenie*2 − (Warta?3:0)`. Wynik < DC → opis zagrożenia w czacie (bez automatycznego spawna — DM decyduje, czy dodać hostile NPC).

## Co celowo pominięto

- Automatyczny spawn wrogów przy nieudanej warcie — wymaga przygotowania encounter table per-area przez DM.
- Zarządzanie wartą dla partii graczy — dla uproszczenia warta jest decyzją jednego PC.
- Animacje obozowe (siedzenie, sen) — wymagałyby dodatkowych animacji w HAK lub NWNX_Creature.
- Konieczność posiadania „namiotu" lub „drewna" — celowo nie dodano resource gate, żeby mechanikat był dostępny szybko.
