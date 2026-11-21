# Wytrzymałość — Durability System

System trwałości ekwipunku dla dark fantasy CRPG opartych na NWN EE.
Brak zależności od NWNX — działa na czystym silniku.

---

## Jak to działa

Każdy z 7 śledzonych slotów wyposażenia (broń główna, lewa ręka,
zbroja, hełm, buty, rękawice, peleryna) ma wartość wytrzymałości 0–100
zapisaną w kampanijnej bazie SQLite (`durability`).

Podczas walki (co ~60 sekund, `sys_module_hb.nss`) sprzęt traci punkt(y)
wytrzymałości. Przy przekroczeniu progów 75 / 50 / 25 / 0 nakładane są
supernaturalne kary do ataku i/lub KP.

| Stan        | Próg  | Kara broni | Kara zbroi/tarczy |
|-------------|-------|------------|-------------------|
| Dobry       | ≥ 75  | 0          | 0                 |
| Zużyty      | ≥ 50  | −1         | −1                |
| Uszkodzony  | ≥ 25  | −2         | −2                |
| Złamany     | > 0   | −4         | −4                |
| Zniszczony  | = 0   | −6         | −6                |

Naprawa dostępna przy kuźni (tańsza) lub w polu (3× drożej + zestaw
z tagiem `dur_repair_kit`).

---

## Pliki

| Plik                          | Rola                                                  |
|-------------------------------|-------------------------------------------------------|
| `Scripts/sql_dur.nss`         | Schemat SQLite + wszystkie zapytania                  |
| `Scripts/lib_dur_def.nss`     | Stałe, ID bindów NUI, ID przycisków, helpery slotów  |
| `Scripts/lib_dur.nss`         | Rdzeń: logika kar, decay, budowa NUI, feed, naprawa  |
| `Scripts/lib_dur_ev.nss`      | Handler zdarzeń NUI                                   |
| `Scripts/sys_on_load.nss`     | Inicjalizacja tabel (OnModuleLoad)                    |
| `Scripts/sys_on_enter.nss`    | Przywracanie kar przy wejściu gracza                  |
| `Scripts/sys_module_hb.nss`   | Heartbeat — decay podczas walki                       |
| `Scripts/test_dur.nss`        | OnUsed na kuźni/placeable — otwiera UI                |
| `Scripts/lib_nui.nss`         | Kopia wspólnego helperów NUI (GUI scale etc.)         |
| `Scripts/lib_nui_utility.nss` | Kopia wspólnych utilsów NUI                           |

---

## Jak włączyć w istniejącym module

### 1. Skopiuj skrypty

Wszystkie pliki z `Durability/Scripts/` do folderu skryptów modułu
(lub do paczki HAK).

Jeśli moduł już korzysta z `lib_nui.nss` / `lib_nui_utility.nss`,
pomiń te pliki — zawartość jest identyczna.

### 2. Podepnij hooki

| Zdarzenie modułu   | Skrypt do dodania (lub wywołania)     |
|--------------------|---------------------------------------|
| OnModuleLoad       | `sys_on_load.nss`                     |
| OnClientEnter      | `sys_on_enter.nss`                    |
| OnHeartbeat        | `sys_module_hb.nss`                   |

Jeśli któryś hook już istnieje, dołącz wywołanie na końcu:

```nss
// w istniejącym sys_on_enter.nss:
#include "lib_dur"
// ...
DelayCommand(2.0, DurCheckAllSlots(oPC));
```

### 3. Umieść kuźnię w świecie gry

Dodaj placeable (np. `plc_wdragonforge`, `plc_cobblestone`) i ustaw
skrypt `test_dur.nss` jako `OnUsed`. Gracze muszą kliknąć kuźnię,
by naprawić ekwipunek taniej niż w terenie.

### 4. (Opcjonalnie) Zestaw naprawczy w terenie

Stwórz item z tagiem `dur_repair_kit` (np. zestaw narzędzi kowalskich,
zakupiony u handlarza). Pozwoli graczom naprawiać ekwipunek poza kuźnią
za 3× cenę złota.

---

## Zależności NWNX

**Brak.** System korzysta wyłącznie z czystego NWN EE (NUI, SQLite,
efekty supernaturalne).

---

## Potencjalne konflikty

- System używa `SUBTYPE_SUPERNATURAL` do oznaczenia kar. Inne systemy,
  które nakładają permanentne supernaturalne efekty `ATTACK_DECREASE`
  lub `AC_DECREASE` na gracza, mogą zostać omyłkowo usunięte przy
  przeliczeniu. Jeśli moduł posiada taki system, podepnij NWNX_Effect
  do tagowania efektów i zmodyfikuj `DurClearPenaltyEffects` w
  `lib_dur.nss`.

---

## Co celowo pominięto

- **Trwałość ekwipunku NPC** — zbędna złożoność bez mechanicznej wartości.
- **Estetyczne zmiany wyglądu** (lodowe pęknięcia itp.) — wymaga HAK/NWNX.
- **Decay poza walką** — zbyt karzący; można włączyć zmieniając warunek
  `GetIsInCombat` w `sys_module_hb.nss`.
- **Naprawa niestandardowymi materiałami** (rudy, skóra) — złoto jako
  universal resource jest prostsze i nie wymaga nowych itemów w HAK.
- **Różna max wytrzymałość per base item type** — uniform 100 upraszcza
  balans; można rozbudować przez tabelę per `GetBaseItemType`.
