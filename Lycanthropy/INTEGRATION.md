# Lycanthropy — Instrukcja Integracji

## Hooki modułu (Module Events)

| Zdarzenie modułu | Skrypt | Opis |
|---|---|---|
| OnModuleLoad | `sys_on_load` | Tworzy tabele SQLite; wywoływany raz przy starcie serwera. |
| OnClientEnter | `sys_on_enter` | Przywraca efekty klątwy po zalogowaniu; uruchamia per-PC heartbeat. |
| OnClientLeave | `sys_on_leave` | Przywraca formę ludzką przy rozłączeniu (czystość stanu). |

Jeśli moduł ma już własne skrypty dla tych zdarzeń, dodaj wywołania:
```nss
// Na końcu istniejącego OnClientEnter:
ExecuteScript("sys_on_enter", GetEnteringObject());
```
lub skopiuj zawartość do istniejących skryptów.

## Silver Weapon Damage (opcjonalne)

Skrypt `sys_on_attacked.nss` obsługuje zadawanie dodatkowych obrażeń przez srebrne bronie.
Należy go podpiąć jako `EVENT_SCRIPT_CREATURE_ON_DAMAGED` lub `OnPhysicalAttacked`
dla postaci graczy — najwygodniej w `sys_on_enter.nss`:

```nss
SetEventScript(oPC, EVENT_SCRIPT_CREATURE_ON_PHYSICAL_ATTACKED, "sys_on_attacked");
```

**Uwaga:** To nadpisze istniejący skrypt `OnPhysicalAttacked` PC. Jeśli masz inne
systemy korzystające z tego zdarzenia, połącz je w jeden skrypt.

## Bronie srebrne

Broń zadaje dodatkowe `2d6` obrażeń magicznych transformowanemu wilkołakowi,
jeśli jej **tag** lub **nazwa** zawiera podciąg `silver` (małe litery).

Przykładowe tagi: `silver_sword`, `blade_of_silver`, `silverlight`.

## Placeable testowy

1. Utwórz dowolny Placeable z tagiem np. `lycan_test`.
2. Ustaw `OnUsed = test_lycan`.
3. Opcjonalnie ustaw lokalną zmienną `LYCAN_TEST_MODE` (INT):
   - `1` — zaraź gracza (etap utajony)
   - `2` — awansuj do pełnego wilkołactwa
   - `3` — wylecz klątwę bez kitu
   - `0` (domyślnie) — otwórz tylko okno statusu

## Przedmiot: Zestaw Odpędnika Wilkołaka

Utwórz przedmiot (np. zwój lub mikstura) z **tagiem `lycan_cure_kit`**.
Sprzedawaj go u kapłanów lub alchemików za wysoką cenę.

Gracz musi posiadać ten przedmiot w ekwipunku i **nie być w formie wilka**,
by przeprowadzić rytuał oczyszczenia z poziomu okna statusu.

## Tuning cyklu księżyca

W `lib_lycan_def.nss` zmień:

```nss
const int LYCAN_MOON_CYCLE_S = 7560; // sekundy realnego czasu na 28 "dni NWN"
```

Domyślnie: `7560 s ≈ 2.1 h` (zakłada 1 dzień NWN = ok. 4.5 min realnego czasu).

Pełnia trwa od dnia 12 do 16 cyklu (zakres konfigurowalny przez `LYCAN_FULL_MOON_START`/`END`).

## Zależności

| Zależność | Wymagana? | Uwagi |
|---|---|---|
| NWNX | NIE | Moduł w całości opiera się na standardowym NWScript + NWN:EE NUI |
| SQLite Campaign DB | TAK | `SqlPrepareQueryCampaign` — dostępne w NWN:EE od wersji 8193.14.3 |
| appearance.2da | TAK | Rząd 285 = Dire Wolf; możliwa podmiana na własny werewolf |

## Co celowo pominięto

- **Zarażanie przez walkę NPC→PC**: silnik NWN nie udostępnia modułowego zdarzenia
  „PC dostał cios od NPC X". Spread dotyczy tylko PC→PC w pobliżu (heartbeat).
- **Moonphase tilesetowe**: brak modyfikacji skyboxa; wizualna zmiana księżyca
  wymagałaby niestandardowego haka lub NWNX:Weather.
- **Kurator specjalny**: rytuał oczyszczenia realizowany przez item, nie przez
  rozmowę z NPC — upraszcza moduł i pozostawia integrację z systemem NPC
  konwersacji po stronie serwera.
- **Ulepszone wilcze zdolności**: transformacja daje jedynie zmianę wyglądu + efekty
  statystyk; specjalne ataki (gryzienie, wyjeczenie AoE) są opcjonalne do dobudowania.
