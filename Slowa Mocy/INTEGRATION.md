# Słowa Mocy — Integracja

## Opis mechaniki

Gracz uczy się arcaicznych słów z trzech kategorii: **Żywioł** (6 opcji),
**Cel** (4 opcje) i **Moc** (3 poziomy siły). W oknie NUI łączy trzy słowa
w inkantację, zapisuje ją w jednym z 6 slotów per-postać (SQLite) i wywołuje
w trakcie gry. Koszt każdej inkantacji to punkty życia (8 / 16 / 32 PŻ).
Inkantacje na Wroga lub Sojusznika wchodzą w tryb celowania; na Siebie i
Przestrzeń są aktywowane natychmiast.

## Hooki — co podpiąć w Toolsecie

| Zdarzenie modułu | Skrypt |
|---|---|
| OnModuleLoad | `sys_on_load` |
| OnPlayerTarget | `sys_on_target` |

> **Uwaga:** jeśli masz już własne `sys_on_load` i `sys_on_target`, wywołaj
> te skrypty wewnątrz istniejących handlerów, lub dodaj
> `ExecuteScript("sys_on_load", GetModule())` / `ExecuteScript("sys_on_target", GetModule())`.

## Jak otworzyć okno

Wywołaj `OpenSlmWindow(oPC)` z dowolnego skryptu (dialog NPC, item OnActivate,
spell hook itp.).

Dołączony `test_slm.nss` to skrypt `OnUsed` dla placeable — uczy wszystkich
słów i otwiera okno. Idealny do testów.

## Zależności NWNX

Brak — moduł działa na czystym NWN EE 1.69+.

## SQL

Moduł korzysta z `SqlPrepareQueryCampaign("slm", ...)`.
Wymaga wybranego katalogu kampanii (ustawienie w module) lub dostosowania
nazwy "slm" do własnej kampanii we wszystkich wywołaniach SQL w `sql_slm.nss`.

Tabele tworzone automatycznie przez `SlmCreateTables()` w `sys_on_load`.

## Nauka słów

Funkcja `SlmLearnWord(oPC, nWordId)` uczy jednego słowa. Stałe word ID:

| Żywioł | ID | Cel | ID | Moc | ID |
|---|---|---|---|---|---|
| Ogień | 1 | Wróg | 11 | Szept | 21 |
| Lód | 2 | Sojusznik | 12 | Głos | 22 |
| Cień | 3 | Siebie | 13 | Krzyk | 23 |
| Światło | 4 | Przestrzeń | 14 | | |
| Piorun | 5 | | | | |
| Mrok | 6 | | | | |

Wywołaj `SlmLearnAllWords(oPC)` by odblokować wszystko (np. test/debug).

## Pliki skryptów

```
Slowa Mocy/Scripts/
  sql_slm.nss         — schemat SQL + wszystkie zapytania
  lib_slm_def.nss     — stałe, ID bindów, pomocniki słów
  lib_slm.nss         — mechanika efektów, budowanie NUI, funkcje Feed
  lib_slm_ev.nss      — handler zdarzeń NUI (main())
  sys_on_load.nss     — tworzy tabele SQL przy starcie modułu
  sys_on_target.nss   — obsługuje kliknięcie celu po wejściu w tryb celowania
  test_slm.nss        — OnUsed na placeable: demo, uczy wszystkich słów
  lib_nui.nss         — wspólny helper NUI (kopiowany z innych modułów)
  lib_nui_utility.nss — wspólny helper NUI
```

## Co celowo pominięto

- **Animacje rzucania czarów** — brak dedykowanego VFX na animację cast; używane są
  tylko efekty trafienia (impact VFX).
- **System nauczyciela NPC** — stała `SLM_LEARN_GOLD` istnieje, ale sam NPC-dialog
  nie jest częścią modułu; integracja z systemem dialogów leży po stronie modułu.
- **Drain On Hit (Mrok+Siebie)** — full drain-on-next-hit wymaga hooka
  `OnPhysicalAttacked`; flaga `SLM_VOID_DRAIN` jest ustawiana, ale efekt jest
  symulowany przez bonus do ataku (pełna implementacja z NWNX jest opcjonalna).
- **Hak `.hak`** — moduł nie wymaga własnego haka; assets (ikony, tło) są
  opcjonalne i nie blokują działania.
