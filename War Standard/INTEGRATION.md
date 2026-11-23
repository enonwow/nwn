# War Standard — Instrukcja integracji

## Co to robi

System bojowych sztandarów. Gracze mogą wznosić w terenie kolorowe chorągwie, które
nadają taktyczne buffy pobliskim sojusznikom (zasięg 10 m). Trzy typy sztandarów:

| Typ | Efekt |
|---|---|
| Gonfalon Legionu | Siła +2, Kondycja +1 |
| Chorągiew Pokuty | Wola +2, Odporność +2, Regeneracja 1 HP/6s |
| Sztandar Grozy | Premia do ataku +2, obrażenia +2 |

Sztandar trwa 30 minut lub do zniszczenia (20 HP, hd 5). Maks. 5 aktywnych
na obszar jednocześnie. Stan persystuje przez restart serwera.

## Wymagane hooki

| Zdarzenie modułu | Co dodać |
|---|---|
| **OnLoad** | `#include "lib_wst"` → `WstCreateTables(); WstRestoreFromDb();` |
| **OnHeartbeat** | `#include "lib_wst"` → `WstTickBuffs();` |
| **OnClientEnter** | `#include "lib_wst"` → `WstOnClientEnter(GetEnteringObject());` |
| **OnActivateItem** | `#include "lib_wst"` → `if(GetTag(GetItemActivated())==WST_TAG_KIT) WstOpenOverview(GetItemActivator());` |

Alternatywnie użyj gotowych skryptów `sys_on_*.nss` jeśli moduł nie ma
jeszcze własnych hooków.

## Pliki

```
War Standard/Scripts/
  lib_wst_def.nss   – stałe, nazwy bindów, helpery efektów
  sql_wst.nss       – schemat SQLite + funkcje CRUD
  lib_wst.nss       – logika, NUI layout, tick buffów
  lib_wst_ev.nss    – handler eventów NUI
  sys_on_load.nss   – init tabel + restore z DB
  sys_on_enter.nss  – daj kit + wstępny tick
  sys_on_hb.nss     – heartbeat (6s) → WstTickBuffs()
  sys_on_target.nss – OnActivateItem dla WST_TAG_KIT
  test_wst.nss      – OnUsed na placeablu demo
```

## Zasoby HAK / Toolset

1. **Placeable blueprint** z ResRef `nwn_war_standard` i Tag `nwn_war_standard`.
   Ustaw: Interaktywny = Tak, Zniszczalny = Tak, Bezwładność = Nie.
   Jeśli asset graficzny nie istnieje, system automatycznie spada na `plc_boulderlrg`
   (widoczny duży głaz) — funkcjonalność działa identycznie.

2. **Item blueprint** z Tag `WST_KIT` (War Standard Kit):
   - Typ: Różne → Małe (Small Miscellaneous)
   - Używalny = Tak (Activate Item event)
   - OnActivateItem skrypt: `sys_on_target`

## Zależności NWNX

Brak. Moduł używa wyłącznie natywnych funkcji NWN:EE:
- SQLite (`SqlPrepareQueryCampaign`)
- NUI (`NuiCreate`, `NuiSetBind`, `NuiFindWindow`)
- Efekty (`EffectAbilityIncrease`, `EffectRegenerate`, `EffectAttackIncrease`, itp.)
- `CreateObject(OBJECT_TYPE_PLACEABLE, ...)`

## Jak przetestować

1. Dodaj placeable do obszaru testowego i przypisz mu skrypt OnUsed: `test_wst`.
2. Wejdź na obszar i użyj placeabla → otworzy się panel *Sztandary Bitwy*.
3. Kliknij **Wznieś Sztandar**, wybierz typ, opcjonalnie wpisz napis, potwierdź.
4. Ruszaj się w pobliżu — efekty zostaną nadane po ≤ 6 s (następny tick heartbeatu).
5. Zaatakuj placeable sztandaru bronią, żeby przetestować destrukcję.

## Co celowo pominięto

- **Fear debuff na wrogów** dla Sztandaru Grozy — wymaga iteracji wszystkich
  istot w obszarze, co może być kosztowne w dużych bitwach. Łatwe do dodania
  przez wywołanie `WstApplyFearToEnemy()` wewnątrz `WstTickBuffs()`.
- **DM tool** do ręcznego usuwania sztandarów — DM może zniszczyć placeable
  standardowym toolem; heartbeat wyczyści SQL przy następnym tiku.
- **Animacja wznoszenia** (NWN cutscene API) — opcjonalne upiększenie.
- **Tabela pozycji okna NUI** — pozycja okna nie jest persystowana między
  sesjami (łatwe do dodania przez rozszerzenie sql_wst.nss).
