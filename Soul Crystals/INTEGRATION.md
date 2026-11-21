# Soul Crystals — Integracja z istniejącym modułem

## Hooki do podpięcia

| Zdarzenie modułu    | Skrypt do ustawienia | Uwaga |
|---------------------|----------------------|-------|
| `OnModuleLoad`      | `sys_on_load.nss`    | Tworzy tabele SQLite w kampanii `soc` |
| `OnClientEnter`     | `sys_on_enter.nss`   | Rejestruje gracza, powiadamia o posiadanych duszach |
| `OnPlayerTarget`    | `sys_on_target.nss`  | Obsługuje schwytanie duszy po wejściu w tryb celowania |

Jeśli moduł ma już skrypty dla tych zdarzeń, należy dołączyć wywołania z powyższych skryptów do istniejącego handlera (np. przez `#include "sys_on_enter"` i wywołanie `main()` lub refaktoryzację do wspólnej funkcji).

## Placeable — Kuźnia Dusz

1. Stwórz placeable (np. `plc_altar1` lub dowolny stosowny wizualnie).
2. Ustaw `OnUsed` → `test_soc.nss`.
3. Nadaj mu nazwę np. **„Kuźnia Dusz"** lub **„Kryształowy Ołtarz"**.
4. Umieść w świecie. Gracze aktywują go, by otworzyć UI zarządzania kryształami.

## Wymagania

- **NWN:EE** z obsługą NUI (`nw_inc_nui.nss`) — patch 8193.32 lub nowszy.
- **Brak NWNX** — moduł używa wyłącznie wbudowanego API NWScript i SQLite.
- Kampania SQLite: `soc.db` tworzna automatycznie przy pierwszym załadowaniu modułu.

## Jak działa schwytanie duszy

1. Gracz klika „Zwiąż Duszę" w oknie Kuźni Dusz.
2. Kursor przechodzi w tryb celowania (strzałka wyboru).
3. Gracz klika na stworzenie z HP ≤ 25% (nie-PC).
4. `sys_on_target.nss` uruchamia `SocOnPlayerTarget`: waliduje cel, zabija go efektem śmierci i zapisuje duszę do SQL.
5. Kryształ pojawia się natychmiast w liście po lewej stronie okna.

## Typy kryształów

| Tier        | Dotyczy                         | Esencja maks |
|-------------|---------------------------------|--------------|
| Popękany    | Humanoidy HD < 4                | ~20          |
| Zwykły      | Bestie HD 4–7                   | ~40          |
| Wyższy      | Nieumarli lub HD 8–14           | ~80          |
| Nieskazitelny | Przybysze lub HD ≥ 15         | ~250         |

## Efekty wzmocnień (consume)

| Przycisk           | Efekt                                       | Koszt        |
|--------------------|---------------------------------------------|--------------|
| Moc Siły           | Siła +2…+8, 1–10 min                       | 50% esencji  |
| Bystrość Ducha     | Mądrość + Inteligencja +2…+8, 1–10 min     | 50% esencji  |
| Pancerz Duszy      | Pancerz unikowy +1…+6, 1–10 min            | 50% esencji  |
| Regeneracja        | Leczenie 1–5 HP/rundę, 1–10 min            | 50% esencji  |
| Wchłonij Całość    | Wszystkie powyższe (silniejsze) + Haste     | 100% (usuwa kryształ), CD 5 min |
| Uwolnij Duszę      | Brak efektu; zwrot złota = tier×5 + ess/10 | Usuwa kryształ |

## Co celowo pominięto

- **Fizyczne itemy kryształów** w ekwipunku — całość trzymana w SQL; brak potrzeby haka.
- **Handel kryształami** między graczami.
- **Efekty cząsteczkowe** na krysztale (wymagałoby niestandardowego assetu w haku).
- **Integracja z Runic Forge** — esencja mogłaby zasilać enkhanty, ale to rozszerzenie dla przyszłych modułów.
