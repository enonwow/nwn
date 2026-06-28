# Tribunal – Integracja z modułem

## Hooki modułu

| Zdarzenie | Skrypt do dodania | Działanie |
|---|---|---|
| `OnModuleLoad` | `sys_on_load` | Tworzy tabele SQL w bazie kampanii `tribunal` |
| `OnClientEnter` | `sys_on_enter` | Rejestruje gracza w bazie; informuje o otwartych sprawach |
| `NUI event` | `lib_trib_ev` | Handler zdarzeń NUI (wpisać w pole NUI Event Script przy `NuiCreate`) |

Skrypt `lib_trib_ev` jest podawany **automatycznie** wewnątrz `TribOpenWindow()` jako czwarty argument `NuiCreate`. Nie trzeba go mapować ręcznie — wystarczy upewnić się, że plik jest skompilowany w HAK/moduł.

## Placeable testowy

1. Stwórz placeable (np. Noticeboard / Tablice ogłoszeń) w dowolnym obszarze.
2. Ustaw skrypt `test_trib` jako `OnUsed`.
3. Użyj plaeable jako gracz lub DM — otworzy się okno Trybunału.

## Wyrok Wygnania

Aby wygnanie działało, umieść w module waypoint z tagiem `TRIB_EXILE_AREA` (stała w `lib_trib_def.nss`). Jeśli waypoint nie istnieje, gracz otrzymuje komunikat, ale nie jest teleportowany.

## Zależności

- **Czyste NWScript + NUI** — brak NWNX.
- SQLite przez `SqlPrepareQueryCampaign("tribunal", ...)` — dane persystowane w pliku kampanii `tribunal.sqlite`.
- `lib_nui.nss` i `lib_nui_utility.nss` — standardowe helpery z tego repo (wymagane w HAK).

## Integracja z innymi systemami

Moduł eksponuje trzy local-int na postaci oskarżonego:

| Zmienna | Wartość | Znaczenie |
|---|---|---|
| `TRIB_IMPRISONED` | 1 | Postać skazana na więzienie |
| `TRIB_EXILED` | 1 | Postać skazana na wygnanie |
| `TRIB_DEATH_MARK` | 1 | Postać nosi wyrok śmierci |

Moduł Prison może sprawdzać `GetLocalInt(oPC, "TRIB_IMPRISONED")` przed wpuszczeniem do celi. System PvP może sprawdzać `TRIB_DEATH_MARK`, aby zezwolić na atak.

## Co celowo pominięto

- Odwołanie od wyroku (appeal) — wymagałoby drugiej instancji lub głosowania DM; można dołożyć później jako widok w tym samym oknie.
- Ograniczenie w czasie (np. wyrok wygasa po X dniach) — trywialne do dodania w SQL (`resolved_at + X * 86400 > now`), ale zależy od decyzji projektowej.
- Powiadomienie DM o nowym oskarżeniu — brak standardowego mechanizmu w NWN bez NWNX; rozwiązanie: `SendMessageToAllDMs()`.
