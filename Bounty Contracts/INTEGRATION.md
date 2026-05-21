# Bounty Contracts — Integration Guide

## Hooki modułu

| Zdarzenie modułu | Skrypt do podpięcia | Notatka |
|---|---|---|
| OnModuleLoad | `sys_on_load` | tworzy tabele SQLite |
| OnClientEnter | `sys_on_enter` | rejestruje gracza, powiadamia o kontrakcie |
| OnPlayerDeath | `sys_on_pdeath` | auto-wypłata nagrody za zabicie gracza-celu |
| OnNUIEvent | `lib_bnt_ev` | obsługa UI (wymagane dla wszystkich okien NUI) |

Jeśli moduł ma już własne skrypty dla tych zdarzeń, wywołaj powyższe przez `ExecuteScript`:

```nss
// przykład — w istniejącym OnModuleLoad:
ExecuteScript("sys_on_load", GetModule());
```

## Placeable — Tablica Ogłoszeń

1. Utwórz placeable (np. `plc_board`) w edytorze modułu.
2. Ustaw jego skrypt `OnUsed` na `test_bnt`.
3. Gracze klikają tablicę → otwiera się okno Kontraktów.

## Zależności NWNX

Brak — moduł korzysta wyłącznie z wbudowanych funkcji NWN:EE (NUI, SQLite, JSON).

## Baza danych SQLite

Dane trafiają do kampanii o nazwie `bounty` (`bounty.sqlite3` w katalogu `userdata/saves/`).

Tabele:
- `bnt_contracts` — wszystkie kontrakty z pełnym stanem
- `bnt_players`  — rejestr graczy do wyszukiwania celów PC

Schemat jest idempotentny (`CREATE TABLE IF NOT EXISTS`) — bezpieczny po restarcie serwera.

## Jak włączyć automatyczną wypłatę za graczy-PC

Wypłata działa bez dodatkowej konfiguracji pod warunkiem podpięcia `sys_on_pdeath`
do `OnPlayerDeath`. Identyfikacja zabójcy opiera się na `GetLastHostileActor`
(fallback: `GetLastDamager`). Jeśli serwer korzysta z NWNX_Events i hookuje
`NWNX_ON_CREATURE_DEATH_AFTER`, można tam wpleść dodatkowe wywołanie
`BntCheckDeathPayout` dla pewniejszej identyfikacji zabójcy.

## Co celowo pominięto

- **Wyszukiwanie graczy przez popup** — dla celów PC imię musi być wpisane dokładnie
  (wielkość liter ignorowana). Wymagałoby to osobnego okna w stylu `Mailbox`.
- **Ograniczenie liczby aktywnych kontraktów na gracza** — łatwe do dodania przez
  zapytanie COUNT w `BntHandlePost`.
- **Historia zakończonych kontraktów** — tabela `bnt_contracts` przechowuje je
  z `state = 2` (completed), ale brak dedykowanego widoku UI.
- **Powiadomienia dla posters po ukończeniu** — wiadomo kto zlecał; łatwo dodać
  `SendMessageToPC` do `sys_on_pdeath` lub `BntHandleClaim`.
- **.mod demo** — środowisko nie obsługuje pakowania pliku `.mod`; wymagane jest
  ręczne wgranie skryptów przez Toolset lub `nwnsc`.
