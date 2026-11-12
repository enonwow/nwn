# Karmic Scales — Szale Przeznaczenia

## Opis

System karmy dwukierunkowej (-100 do +100). Karma odzwierciedla moralny kierunek
postaci gracza i zmienia się wraz z jego czynami. Extreme wartości aktywują
trwałe efekty (kary lub bonusy). Gracz może zarządzać karmą przez okno NUI
z wizualizacją szali.

## Hooki do podpięcia w istniejącym module

| Skrypt hooka               | Wywołanie                                              |
|----------------------------|--------------------------------------------------------|
| `OnModuleLoad`             | `#include "sys_on_load"` → `KsCreateTables()`         |
| `OnClientEnter`            | `#include "sys_on_enter"` → logika z sys_on_enter.nss |
| Dowolny skrypt akcji gracza| `#include "lib_ks"` → `KsAwardKarma(oPC, n, sReason)` |

Podpięcie karmy do zdarzeń modułu (przykłady):

```nss
// Gracz zabił niewinne stworzenie (w OnCreatureDeath lub hooku):
KsAwardKarma(oPC, -5, "Zabicie niewinnej istoty");

// Gracz uleczył sojusznika (w OnSpellCastAt lub hooku):
KsAwardKarma(oPC, 3, "Uzdrowienie towarzysza");

// Gracz złamał przysięgę:
KsAwardKarma(oPC, -8, "Złamanie przysięgi");

// Gracz odprawił czarny rytuał:
KsAwardKarma(oPC, -20, "Czarny rytuał przy ołtarzu");
```

Okno UI otwiera gracz przez:
- Kliknięcie placeabla z `test_ks.nss` jako OnUsed
- Lub wywołanie `CreateKsWindow(oPC)` z dowolnego skryptu

## Zależności NWNX

Brak. Moduł używa wyłącznie standardowego NWScript + NUI + SQLite (natywne w NWN:EE).

## Baza danych

Campaign DB: `karmic_scales`

Tabele:
- `ks_karma (uuid TEXT PK, karma INTEGER)` — karma per gracz
- `ks_log (id INT PK, uuid, delta, reason, logged_at)` — historia zdarzeń
- `ks_cooldowns (uuid TEXT PK, ritual_at INTEGER)` — czas ostaniego rytuału

## Progi karma i efekty

| Próg          | Tier              | Efekt pasywny                             |
|---------------|-------------------|--------------------------------------------|
| ≤ −75         | POTĘPIENIE        | −3 Perswazja, −3 Leczenie                 |
| −74 do −25    | DOTKNIĘTY CIENIEM | −1 Charyzma                               |
| −24 do +24    | RÓWNOWAGA         | brak                                       |
| +25 do +74    | ŁASKA ŚWIATŁA     | +1 do rzutów Woli                         |
| ≥ +75         | PRÓBA WIARY       | +2 do wszystkich rzutów obronnych         |

## Rytuały (UI)

| Akcja               | Wymaganie                      | Efekt                               |
|---------------------|--------------------------------|--------------------------------------|
| Rytuał Równowagi    | 50 sz złota, cooldown 1h      | Przesuwa karmę o 10 ku 0            |
| Uwolnij Cień        | Karma ≤ −25                    | −25 karmy, +2 atak przez 60s        |
| Uwolnij Blask       | Karma ≥ +25                    | −25 karmy, regeneracja 2 PŻ/6s 60s |

## Co celowo pominięto

- Efekty dźwiękowe i animacje przy zmianie tiera (wymagają zasobów w hak)
- Automatyczne zdarzenia co jakiś czas dla tiera POTĘPIENIE (wymaga heartbeat)
- Ikona powiadamiania (jak w Mailbox) — karma zmienia się rzadko
- Opcja DM do ręcznego ustawiania karmy gracza
