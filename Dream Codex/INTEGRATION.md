# Dream Codex — Integracja

## Hooki modułowe

| Zdarzenie modułu | Skrypt do wywołania |
|---|---|
| OnModuleLoad | `sys_on_load` |
| OnClientEnter | `sys_on_enter` |
| OnNuiEvent | `lib_drm_ev` |

> Jeśli moduł ma już własne hooki w tych zdarzeniach, dodaj wywołania `ExecuteScript("sys_on_load", GetModule())` / `ExecuteScript("sys_on_enter", GetEnteringObject())` / `ExecuteScript("lib_drm_ev", OBJECT_SELF)` wewnątrz istniejących skryptów.

## Placeable — Kamień Wizji

1. Umieść w toolsecie dowolny placeable (np. altar, monolith, stone circle).
2. W polu **OnUsed** wpisz: `test_drm`.
3. Brak dodatkowych zmiennych — skrypt sam sprawdza cooldown.

## SQL

Moduł tworzy własną bazę campaign o nazwie `dreamcodex` (tabele: `drm_sessions`, `drm_cooldowns`).  
Bazy nie trzeba inicjalizować ręcznie — `sys_on_load` wywołuje `DrmCreateTables()` która używa `CREATE TABLE IF NOT EXISTS`.

## Zależności NWNX

**Brak.** Moduł korzysta wyłącznie z natywnego NWScript + NUI (NWN:EE 8193+).

## Konfiguracja

Stałe w `lib_drm_def.nss`:

| Stała | Domyślna wartość | Opis |
|---|---|---|
| `DRM_COOLDOWN_HOURS` | `8` | Godziny między sesjami transu |
| `DRM_VISIONS_PER_SESSION` | `3` | Liczba wizji na sesję |
| `DRM_JOURNAL_MAX` | `15` | Max sesji w historii per postać |
| `DRM_EFFECT_DURATION_S` | `14400.0` | Czas trwania efektów (sekundy) |

## Jak otworzyć okno ze skryptu

```nss
#include "lib_drm"

void main()
{
    object oPC = GetPCSpeaker(); // lub inny obiekt PC
    DrmOpenWindow(oPC);
}
```

## Pula wizji

20 wizji w 6 kategoriach (szczegóły w `lib_drm.nss`, funkcja `DrmGetVisionById`):

| Kategoria | ID | Efekt bazowy |
|---|---|---|
| ŚMIERĆ | 1–4 | Kara AC, kara trafienie, kara rzuty obronne, objawienie |
| TRYUMF | 5–8 | Premia trafienie, premia AC, premia rzuty obronne, tymczasowe PW |
| CHAOS | 9–12 | Losowy efekt spośród 6 możliwości |
| PRAWDA | 13–15 | Wiadomość z klimatyczną wskazówką fabularną |
| CIEŃ | 16–17 | Premia Skradanie + Cicha Stopa |
| KREW | 18–20 | Premia obrażenia, tymczasowe PW, premia trafienie |

Ważenie puli: wizje ŚMIERĆ i KREW częściej przy HP < 50%; CIEŃ częściej w nocy.
