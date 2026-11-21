# Obsessions & Fixations — Integration Guide

## Co to robi

System śledzi 10 kategorii **punktów obsesji** per postać w SQLite.
Gdy gracz przekroczy próg punktowy, aktywuje się nowy poziom (Skłonność →
Przymus → Obsesja → Obłęd) dający premię do rzutów, ale też wymuszający
rzut Woli lub wywołując przymusowe zachowanie. Gracz może przeglądać swój
stan w oknie **Kroniki Obsesji** i tłumić obsesje za 500 zł.

## Wymagania

- NWN:EE 8193.35+ (NUI, `SqlPrepareQueryCampaign`, `WillSave`)
- Brak zależności NWNX — czyste NWScript
- Kampania SQLite: `obsessions.sqlite3` tworzona automatycznie

## Hooki do podpięcia

| Hook modułu          | Skrypt                        |
|----------------------|-------------------------------|
| `OnModuleLoad`       | `sys_on_load.nss`             |
| `OnClientEnter`      | `sys_on_enter.nss`            |
| `OnModuleHeartbeat`  | `sys_on_heartbeat.nss`        |

Jeśli moduł już ma własne skrypty na te zdarzenia, wywołaj odpowiednie
funkcje z lib_obs przez `ExecuteScript` lub bezpośrednie `#include`.

## Nadawanie punktów obsesji

Wywołaj z odpowiednich hooków (OnCreatureDeath, OnSpellCast, itp.):

```nss
#include "lib_obs_def"

// Gdy gracz zabije nieumarłego:
ObsAddPoints(oPC, OBS_CAT_UNDEAD, 3);

// Gdy gracz wybierze zamek:
ObsAddPoints(oPC, OBS_CAT_THEFT, 1);

// Gdy gracz wypije alkohol (sprawdź tag przedmiotu):
ObsAddPoints(oPC, OBS_CAT_DRINK, 2);

// Gdy gracz rzuci zaklęcie arkanowe:
ObsAddPoints(oPC, OBS_CAT_ARCANE, 1);
```

Sugerowane wartości: 1–3 pkt. za zdarzenie; próg dla pierwszego poziomu to 25 pkt.

## Otwieranie UI

```nss
#include "lib_obs"
ObsOpenUI(oPC);  // np. z komendy /obsesje lub NPC-spowiednika
```

## Demo

Umieść placeable z `OnUsed = test_obs.nss` — skrypt doda przykładowe
punkty i otworzy okno, by przetestować wygląd wszystkich poziomów.

## Co celowo pominięto

- Ikony kategorii w liście (wymagałyby assets w HAK)
- Szczegółowe warunkowe obrażenia BLOOD dla każdego rodzaju (uproszczono do AB)
- Integracja z systemem kupna mikstur (DRINK trigger)
- Efekty wizualne/dźwiękowe per kategoria (łatwe do dodania)
- Redukcja punktów z czasem (projektowo obsesje są permanentne — tłumienie to jedyna opcja)
