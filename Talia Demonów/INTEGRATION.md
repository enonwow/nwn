# Talia Demonów — Integracja z modułem NWN

## Co to robi

System losowania demonicznych kart tarota z trwałymi efektami na postać.
Gracz losuje jedną z 22 unikalnych kart, każda nadaje premię mechaniczną
i wiąże się z klątwą/obowiązkiem fabularnym. Wylosowane karty są zapisywane
w SQLite — efekty przeżywają relog. Po wylosowaniu wszystkich 22 kart
talia może zostać przetasowana.

## Wymagane pliki (dodaj do HAK lub Scripts)

```
lib_tarot_def.nss
lib_tarot.nss
lib_tarot_ev.nss
sql_tarot.nss
sys_on_load.nss
sys_on_enter.nss
test_tarot.nss
lib_nui.nss        (wspólna utilka NUI — już w projekcie)
lib_nui_utility.nss
```

### Ikony kart (HAK)

Dodaj do paczki HAK 23 pliki graficzne `.tga` lub `.dds`:

| Plik                  | Opis                                |
|-----------------------|-------------------------------------|
| `tarot_card_back.tga` | Rewers karty (nieznana)             |
| `tarot_card_00.tga`   | Nieczysta Moc                       |
| `tarot_card_01.tga`   | Czarna Brama                        |
| …                     | …                                   |
| `tarot_card_21.tga`   | Koniec Ery                          |

Do testów możesz użyć dowolnych istniejących ikon z podstawowej gry
(np. `ir_potion2` jako rewers i kolejne ikony zaklęć jako twarze kart).
Zmień tylko stałe `TarotCardIcon()` i `TarotCardBackIcon()` w
`lib_tarot_def.nss`.

## Hooki modułowe

### OnModuleLoad

```nss
#include "sys_on_load"
// (lub wywołaj ręcznie z istniejącego skryptu OnLoad)
void main() { TarotInitDB(); }
```

Wywołuje `TarotInitDB()` — tworzy tabelę `tarot_drawn` jeśli nie istnieje.

### OnClientEnter

```nss
#include "sys_on_enter"
// (lub dorzuć do istniejącego skryptu OnEnter)
void main() {
    object oPC = GetEnteringObject();
    if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
        TarotApplyAllDrawnEffects(oPC);
}
```

Przywraca wszystkie efekty kart po ponownym zalogowaniu.

## Placeable — punkt dostępu

1. Stwórz Placeable (np. `"Chest"` lub niestandardowy model).
2. Ustaw `OnUsed` → `test_tarot`.
3. Nazwa placeable: `Zapieczętowana Talia Demonów`.
4. Umieść w dowolnym miejscu w module.

Możesz też wywołać `TarotOpenWindow(oPC)` bezpośrednio z dowolnego
dialogu NPC.

## Brak NWNX

Moduł nie wymaga NWNX. Używa wyłącznie standardowego API NWN:EE
i wbudowanego SQLite (kampania modułu).

## SQL

Dane przechowywane w kampanii modułu (`SqlPrepareQueryCampaign`):

```sql
CREATE TABLE IF NOT EXISTS tarot_drawn (
    pc_uuid    TEXT    NOT NULL,
    card_id    INTEGER NOT NULL,
    drawn_at   INTEGER NOT NULL DEFAULT 0,
    draw_count INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (pc_uuid, card_id)
);
```

## Co celowo pominięto

- **Animacje rysowania kart** — NWN nie obsługuje animacji wewnątrz NUI
  poza efektami placeable; można to obejść przez krótki `DelayCommand` + VFX.
- **Efekty warunkowe** (np. karta 10: AB +3 tylko poniżej 50% HP) —
  wymagałyby OnHeartbeat hook; uproszczono do stałych efektów.
- **Unikalny wygląd okna** (background image) — wymaga dedykowanego
  assetu w HAK; pominięto dla przenośności.
- **Limit wylosowań** (można by ograniczyć do 1 losowania / relog) —
  decyzja projektowa należy do serwera.
- **Efekt karty 1** (Czarna Brama: teleportacja) — NWN nie pozwala
  na wbudowane 1/dzień efekty bez OnHeartbeat lub item z odpowiednim
  spell; zastąpiono Dex+2 + prędkość ruchu.
