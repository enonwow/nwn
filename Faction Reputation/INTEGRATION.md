# Faction Reputation — Integration Guide

## Co to robi

System czterech rywalizujących frakcji mrocznego fantasy z trwałą reputacją
(-1000 … +1000 punktów per frakcja) i mechanicznymi konsekwencjami zależnymi
od poziomu nastawienia. Okno NUI pokazuje reputację, opis i aktualne efekty
każdej frakcji. Pasywne efekty (bonus do umiejętności / statystyk) są
automatycznie reaplikowane po każdej zmianie i po każdym logowaniu.

## Frakcje

| ID | Nazwa | Rival |
|----|-------|-------|
| 0 | Zelazna Straz | Bractwo Cienia |
| 1 | Bractwo Cienia | Zelazna Straz |
| 2 | Kult Wiecznej Nocy | Zakon Plomienia |
| 3 | Zakon Plomienia | Kult Wiecznej Nocy |

Zysk reputacji u jednej frakcji = 50% kary u rywala (automatyczne).

## Poziomy nastawienia

| Poziom | Zakres | Efekt pasywny |
|--------|--------|---------------|
| Wrogi | <= -500 | Kara statystyczna |
| Nieufny | -499 .. -100 | Brak |
| Neutralny | -99 .. 99 | Brak |
| Przychylny | 100 .. 499 | Niewielki bonus |
| Szanowany | 500 .. 749 | Sredni bonus |
| Wyniesiony | 750 .. 1000 | Pelny bonus + tytul |

## Pliki

```
Faction Reputation/
  Scripts/
    sql_fac.nss        — schemat SQLite + CRUD (DB: "factions")
    lib_fac_def.nss    — stalé, dane frakcji, helpery standing
    lib_fac.nss        — logika glowna, NUI, efekty pasywne
    lib_fac_ev.nss     — handler zdarzen NUI
    sys_on_load.nss    — hook OnModuleLoad (tworzy tabele)
    sys_on_enter.nss   — hook OnClientEnter (reaplikuje efekty)
    test_fac.nss       — placeable OnUsed, demo reputacji
```

## Zależności

- **NWScript NUI** (wbudowany od NWN EE 8193.14) — wymagany
- **SQLite campaign DB** (wbudowany od NWN EE) — wymagany, DB name: `"factions"`
- **NWNX** — opcjonalny; moduł nie wymaga żadnego pluginu NWNX

## Jak włączyć w istniejącym module

### 1. Hooki modułu

W toolsecie, w Module Properties → Events:

| Zdarzenie | Skrypt |
|-----------|--------|
| OnModuleLoad | `sys_on_load` (lub wywołaj `FacInit()` w istniejącym) |
| OnClientEnter | `sys_on_enter` (lub wywołaj `FacApplyAllEffects(oPC)`) |
| OnNuiEvent | `lib_fac_ev` (lub dispatcher z `NuiFindWindow` check) |

### 2. Otwieranie okna

Podepnij pod przycisk NPC / placeable / item:

```nss
#include "lib_fac"
void main() { FacOpenWindow(GetPCSpeaker()); }
```

### 3. Zmiana reputacji ze skryptu questa / zdarzenia

```nss
#include "lib_fac"

// Gracz pomógł Żelaznej Straży pojmać zbiega:
FacAdjust(oPC, FAC_ID_IRON_GUARD, 150, "quest:fugitive_captured");

// Gracz zabił strażnika:
FacAdjust(oPC, FAC_ID_IRON_GUARD, -200, "event:guard_killed");

// Gracz ukończył rytuał Kultu:
FacAdjust(oPC, FAC_ID_NIGHT_CULT, 300, "quest:cult_ritual");
```

### 4. Odczyt reputacji w skryptach NPC (np. dialog, OnSpawn)

```nss
#include "lib_fac"

void main()
{
    object oPC = GetPCSpeaker();
    int nPts = FacGetPoints(oPC, FAC_ID_IRON_GUARD);
    int nStanding = FacGetStanding(nPts);

    if(nStanding <= FAC_STANDING_HOSTILE)
    {
        // NPC atakuje
        SetIsTemporaryEnemy(oPC, OBJECT_SELF);
        ActionAttack(oPC);
    }
    else if(nStanding >= FAC_STANDING_HONORED)
    {
        // NPC ma specjalny dialog
        BeginConversation();
    }
}
```

## Co celowo pominięto

- **DM panel** — brak GUI dla mistrza gry do ręcznej edycji reputacji;
  można to zrobić przez chat command lub dodatkowy placeable z test_fac.
- **Logi online** — historia zapisywana w `fac_history`, ale brak UI do
  jej przeglądania.
- **NPC-specific faction tags** — moduł nie zarządza automatycznie
  wrogością konkretnych NPC; to należy do skryptów OnSpawn/OnPerception
  danego placeable lub NPC (przykład w sekcji wyżej).
- **Merchant price modifiers** — konsekwencje cenowe opisane w UI,
  ale wymaga hooka OnStore lub rozmowy z konkretnym kupcem.
- **Offline progression** — reputacja nie zmienia się gdy gracz jest offline.
