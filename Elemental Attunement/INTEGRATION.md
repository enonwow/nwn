# Elemental Attunement — Integration Guide

## Czym jest ten moduł

Gdy postać przyjmuje obrażenia żywiołowe (Ogień / Zimno / Kwas / Błyskawica / Mrok),
powoli nasyca się danym żywiołem — kumulując punkty nastrojenia zapisane w SQLite.
Przekroczenie progów (100 / 300 / 600 pkt) odblokowuje kolejne stopnie odporności
i specjalnych mocy. Na Stopniu III ciało zyskuje tarczę obrażeń zwrotnych lub inny
silny efekt, ale i podatność na przeciwny żywioł.

Gracze przeglądają i czyszczą nastrojenia przy **Kamieniu Rezonansu** (placeable).

---

## Pliki

| Plik | Rola |
|------|------|
| `sql_eatt.nss` | Schemat SQLite + zapytania |
| `lib_eatt_def.nss` | Stałe, identyfikatory bindów, deklaracje |
| `lib_eatt.nss` | Rdzeń logiki, NUI, efekty |
| `lib_eatt_ev.nss` | Handler eventów NUI |
| `sys_on_load.nss` | OnModuleLoad — tworzy tabele |
| `sys_on_enter.nss` | OnClientEnter — hook + restore efektów |
| `sys_on_damaged.nss` | OnDamaged PC — akumulacja punktów |
| `test_eatt.nss` | OnUsed Kamienia Rezonansu |
| `lib_nui.nss` | Wspólna biblioteka NUI (kopia) |
| `lib_nui_utility.nss` | Pomocnicze funkcje NUI (kopia) |

---

## Zależności

- **NWN:EE 8193.35+** — wymaga `EffectDamageVulnerability`, `TagEffect`, `GetEffectTag` i `NuiProgressBar`
- **Brak wymagań NWNX** — działa na czystym NWN:EE bez pluginów zewnętrznych
- **SQLite campaign DB** — dane przechowywane w `eatt.sqlite` (Campaign DB o nazwie `"eatt"`)

---

## Jak włączyć w istniejącym module

### 1. Skompiluj skrypty

Dodaj wszystkie pliki `.nss` z folderu `Scripts/` do toolset'u i skompiluj.

### 2. OnModuleLoad

W skrypcie `OnModuleLoad` modułu dodaj wywołanie:
```nss
ExecuteScript("sys_on_load", GetModule());
```

Lub jeśli masz już własny plik, dodaj na początku:
```nss
#include "sql_eatt"
// ... w funkcji main():
EattCreateTables();
```

### 3. OnClientEnter

W skrypcie `OnClientEnter` modułu dodaj:
```nss
ExecuteScript("sys_on_enter", GetEnteringObject());
```

Lub zintegruj ręcznie (patrz komentarz w `sys_on_enter.nss` — skrypt sam chainuje poprzedni OnDamaged).

### 4. Kamień Rezonansu (Placeable)

- Stwórz placeable (np. kamień, posąg, ołtarz).
- Ustaw skrypt `OnUsed` na `test_eatt`.
- Opcjonalnie nadaj opisowy Examine Text: *„Stary kamień tętni cichą energią. Żywiołowe piętno można tu odczytać i zetrzeć."*

### 5. Opcjonalnie: komunikat powitalny

W `OnClientEnter` można dodać przypomnienie dla graczy:
```nss
SendMessageToPC(oPC, "[Nastrojenie] Przyjmowanie obrażeń żywiołowych nasyca cię ich energią. Odwiedź Kamień Rezonansu, aby śledzić postęp.");
```

---

## Mechanika szczegółowa

| Żywioł | Typ obrażeń | Specjalne (T2) | Specjalne (T3) | Podatność (T3) |
|--------|-------------|----------------|----------------|----------------|
| Ogień | FIRE | — | Tarcza ognia 1k4+2 | Zimno +10% |
| Zimno | COLD | Zasłona 10% | Tarcza zimna 1k4+2 | Ogień +10% |
| Kwas | ACID | AC naturalny +1 | AC naturalny +2 | Błyskawica +10% |
| Błyskawica | ELECTRICAL | Prędkość +10% | Prędkość +20% | Kwas +10% |
| Mrok | NEGATIVE | Zasłona 10% | Zasłona 15% | — |

Progi punktów: T1 = 100, T2 = 300, T3 = 600 (cap: 700).
Każde 5 pkt obrażeń danego żywiołu = 1 pkt nastrojenia (min. 1 pkt/trafienie).

---

## Co celowo pominięto

- **Pozytywna energia** (DAMAGE_TYPE_POSITIVE) — rzadko zadawana graczom, pominięta dla prostoty
- **Efekty dźwiękowe/VFX** żywiołu na postaci — wymagałoby dodatkowych zasobów w HAK
- **Konfirmacja przed oczyszczeniem** — wystarczy jedno kliknięcie; zapobieganie przez cenę 500 sz
- **Limit jednego Stopnia III naraz** — w obecnej wersji można mieć wiele T3 jednocześnie (design decision: opłaca się narażać na wiele żywiołów)
