# Wanted System — Integracja

## Hooki modułu

| Zdarzenie modułu | Skrypt / akcja do dołączenia |
|------------------|------------------------------|
| OnModuleLoad     | Wywołaj `WantedCreateTables()` z `sys_on_load.nss` |
| OnClientEnter    | Wywołaj kod z `sys_on_enter.nss` |
| OnClientExit     | Wywołaj kod z `sys_on_leave.nss` |

Jeśli masz już własne skrypty tych zdarzeń, wklej **ciało `main()`** zamiast
podmieniać cały plik.

## Dodawanie gorączki (API zewnętrzne)

```nss
#include "lib_wnt"

// Atak na niewinnego NPC — liczy jako przestępstwo:
WantedAddHeat(oPC, 20, TRUE);

// Efekt środowiskowy (klątwa obszaru itp.) — nie liczy do przestępstw:
WantedAddHeat(oPC, 5, FALSE);
```

Sugerowane wartości gorączki:

| Czyn | Gorączka |
|------|----------|
| Kradzież kieszonkowa | 5–10 |
| Napaść na cywila | 15–20 |
| Zabójstwo cywila | 30–40 |
| Atak na strażnika | 40–50 |
| Zabójstwo strażnika | 60 |

## Reakcja straży

Wklej do skryptu `OnPerception` strażnika (taga np. `city_guard`):

```nss
#include "lib_wnt"

void main()
{
    object oPC = GetLastPerceived();
    if(!GetLastPerceptionSeen()) return;
    WantedGuardReact(OBJECT_SELF, oPC);
}
```

`WantedGuardReact` działa tylko gdy heat >= `WNT_TH_WANTED` (40). Poniżej tego
progu straż nie reaguje mechanicznie.

## Tuning — współczynnik zaniku

W `lib_wnt_def.nss`:

```nss
const float WNT_DECAY_PER_SEC = 0.1;  // TEST: 1 heat na 10 s
```

Dla serwera produkcyjnego zalecane wartości:
- `0.016` — 1 heat/min, pełne 100 pkt. znika po ~1 h 40 min
- `0.008` — 1 heat/min, pełne 100 pkt. znika po ~3 h 20 min

## Zależności

- **NWNX**: Nie wymagany.
- **SQL**: Własna kampania `wanted` (SQLite). Nie wchodzi w konflikt z innymi
  modułami używającymi osobnych kampanii.
- **nw_inc_nui**: Standardowy include NWN:EE (dostępny w każdej instalacji).
- **Asety**: Skrypty odwołują się do ikonek `wnt_icon_0` … `wnt_icon_4` (TGA 32×32).
  Podmień je na własne lub użyj dowolnych ikon z zainstalowanego hak-paka.

## Co celowo pominięto

- **Automatyczne śledzenie ataków** — wymaga umieszczenia haka `OnPerception`
  lub `OnCombatRoundEnd` na każdym NPC-u w module; jest to zadanie dla integratora.
- **Plakaty i listy gończe jako obiekty** — wymagają osobnego systemu spawnu.
- **Maskowanie/przebranie** — możliwa integracja z modułem Appearance, poza zakresem.
- **Streaming danych do innych graczy** — każdy PC ma własny, prywatny rejestr.
