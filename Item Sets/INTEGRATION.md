# Starożytne Zestawy — Integration Guide

## Co to robi

System wykrywa, ile elementów każdego z pięciu legendarnych zestawów gracz
ma aktualnie założonych, i przyznaje mu narastające premie (2/3/4 elementy).
Premie działają jako permanentne efekty otagowane unikalnym stringiem, więc
są automatycznie usuwane i przeliczane przy każdej zmianie ekwipunku.

## Pliki

| Plik | Rola |
|------|------|
| `lib_sets_def.nss` | Stałe, NUI IDs, dane zestawów (tagi, nazwy, progi bonusów) |
| `lib_sets.nss` | Logika efektów, detekcja, budowanie + karmienie NUI |
| `lib_sets_ev.nss` | Handler eventów NUI (main()) |
| `lib_nui.nss` | Wspólne narzędzia NUI (kopia z Mailbox) |
| `lib_nui_utility.nss` | Wspólne narzędzia NUI (kopia z Mailbox) |
| `sys_on_load.nss` | Hook OnLoad (pusty – brak SQL) |
| `sys_on_equip.nss` | Hook OnEquipItem |
| `sys_on_unequip.nss` | Hook OnUnEquipItem |
| `test_sets.nss` | Skrypt OnUsed na Placeable (QA) |

## Jak włączyć w istniejącym module

### 1. Skopiuj skrypty do hak/Override

Wszystkie `.nss` z `Item Sets/scripts/` → do hak projektu.

### 2. Podepnij hooki w module

W Aurora Toolset:
- **Module → Module Properties → Events**
  - `OnEquipItem`  → `sys_on_equip`
  - `OnUnEquipItem` → `sys_on_unequip`
  - `OnLoad`       → `sys_on_load`

Jeśli te eventy są już zajęte przez inne skrypty, wywołaj `SetsUpdateAll(oPC)`
wewnątrz istniejącego handlera:

```nss
#include "lib_sets"
// ... twój kod ...
SetsUpdateAll(GetPCItemLastEquippedBy());
```

### 3. Oznacz przedmioty zestawów

Każdy przedmiot należący do zestawu musi mieć odpowiedni **Tag** ustawiony
w Toolset. Lista tagów:

| Zestaw | Tagi elementów |
|--------|---------------|
| Zbroja Mrocznego Rycerza | `set_dk_helm` \| `set_dk_chest` \| `set_dk_gaunt` |
| Szaty Martwego Maga | `set_dm_robe` \| `set_dm_ring` \| `set_dm_staff` |
| Rząd Korsarza | `set_co_coat` \| `set_co_gloves` \| `set_co_boots` \| `set_co_blade` |
| Pierścienie Przeklętych | `set_pr_ring1` \| `set_pr_ring2` |
| Śmiertelny Obłęd | `set_so_mask` \| `set_so_robe` \| `set_so_bracer` \| `set_so_blade` |

### 4. Opcjonalnie: podepnij trigger/placeable do otwierania okna

Aby gracz mógł otworzyć panel ręcznie:

```nss
#include "lib_sets"
void main() { SetsOpenWindow(GetLastUsedBy()); }
```

Jako skrypt `OnUsed` na dowolnym placeable.

### 5. Testowanie

Skrypt `test_sets.nss` jako `OnUsed` na placeable tworzy przykładowe
przedmioty i otwiera panel. Usuń go z produkcji.

## Premie zestawów

### Zbroja Mrocznego Rycerza (3 szt.)
- (2): +2 do trafień
- (3): +2 do trafień, immunitet na strach

### Szaty Martwego Maga (3 szt.)
- (2): Inteligencja +2
- (3): Charyzma +2

### Rząd Korsarza (4 szt.)
- (2): Zręczność +2
- (3): Skradanie +4, Cichobieg +4
- (4): Zręczność +2 (łącznie +4), +2 do trafień

### Pierścienie Przeklętych (2 szt.)
- (2): Wola +4, wrażliwość na boskość 25%

### Śmiertelny Obłęd (4 szt.)
- (2): Redukcja obrażeń 5/+1
- (3): Regeneracja 1 co 6 sek.
- (4): Kondycja +2

## Zależności

- NWN:EE build ≥ 8193.25 (wymagane `GetEffectTag`, `TagEffect`, `EffectRegenerate`)
- Brak NWNX
- Brak SQL

## Co celowo pominięto

- Definiowanie nowych zestawów przez DM w runtime (wszystkie zestawy są w stałych)
- Ikony przedmiotów w panelu NUI (brak resref bez konkretnego hak)
- Persystencja zalogowanych bonusów (efekty są przeliczane od zera przy logowaniu;
  wywołaj `SetsUpdateAll` w `OnClientEnter`, jeśli chcesz to naprawić)
- Lokalizacja EN (identyfikatory i kod po angielsku, UI po polsku)
