# Relic Vault — Integracja

## Wymagania

- NWN:EE 8193.36+ (wymaga `TagEffect` / `GetEffectTag`, `EffectRegenerate`, `SqlPrepareQueryCampaign`)
- Brak zależności NWNX
- Brak własnego HAK (brak grafik — używa wbudowanych zasobów silnika)

## Pliki

| Plik | Rola |
|------|------|
| `sql_rlc.nss` | Schemat SQLite i wszystkie zapytania |
| `lib_rlc_def.nss` | Stałe: ID bindów, ID relikwii, koszty, tagi efektów |
| `lib_rlc.nss` | Rdzeń: dane relikwii, budowa okna NUI, feed, efekty, tick klątwy |
| `lib_rlc_ev.nss` | Handler zdarzeń NUI (`NuiGetEventType` switch) |
| `sys_on_load.nss` | Wywołaj z OnModuleLoad — tworzy tabelę `rlc_attunements` |
| `sys_on_enter.nss` | Wywołaj z OnClientEnter — przywraca efekty po relogu, sprawdza tick klątwy |
| `sys_on_hbeat.nss` | Wywołaj z OnHeartbeat — eskaluje klątwy online graczy (~co 6 min) |
| `test_rlc.nss` | OnUsed na placeablu demonstracyjnym |

## Jak podpiąć w istniejącym module

```nss
// OnModuleLoad — dodaj wywołanie:
#include "sql_rlc"
void main() {
    RlcCreateTables();
    // ... reszta twojego on_load
}

// OnClientEnter — dodaj wywołanie:
#include "lib_rlc"
void main() {
    object oPC = GetEnteringObject();
    if(GetIsPC(oPC)) {
        RlcApplyEffects(oPC);
        RlcCheckCurseTick(oPC);
    }
    // ... reszta twojego on_enter
}

// OnHeartbeat — dodaj wywołanie:
#include "lib_rlc"
void main() {
    // throttle jest wbudowany — wywołuj bezwarunkowo
    RlcOnHeartbeat(); // patrz niżej
    // ... reszta twojego heartbeatu
}
```

> Uwaga: `sys_on_hbeat.nss` zawiera logikę throttle wewnątrz `main()`. Przy integracji
> wytnij zawartość do osobnej funkcji `void RlcOnHeartbeat()` w `lib_rlc.nss`.

## Jak otworzyć okno

Dowolny skrypt po stronie serwera:
```nss
#include "lib_rlc"
RlcShowWindow(oPC);
```

## Mechanika w skrócie

- 6 relikwii, każda może być dzierżona przez jedną postać jednocześnie.
- Atunowanie: 500 sz. Uwolnienie: 200 sz.
- Co **10 minut realnych** klątwa wzrasta o 1 (max 5). Na poziomie 5 moc się podwaja.
- Oczyszczenie: 1000 sz, 60% szansy na redukcję klątwy o 1 — można powtarzać.
- Po relogu efekty są przywracane z SQL; gracze offline nie otrzymują ticków po powrocie
  (tylko jeden tick catch-up w `sys_on_enter.nss`).

## Co celowo pominięto

- HAK / grafiki relikwii — możliwe rozszerzenie z własnym `rlc_*.tga`.
- Fizyczne itemy relikwii w ekwipunku — uproszczono do systemu czystych efektów.
- Animacje / VFX przy atunowaniu — można dodać `ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(...))`.
- Wielokrotny catch-up ticków przy długiej nieobecności — świadomy wybór: gracze nie mogą przegapić eskalacji przez unikanie logowania.
