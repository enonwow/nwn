# Nałogi (Vices) — Integration Guide

## Hooks wymagane w module

Podepnij skrypty pod zdarzenia modułu (Tool -> Module Properties -> Events):

| Zdarzenie modułu    | Skrypt do podpięcia | Uwagi                             |
|---------------------|---------------------|-----------------------------------|
| OnModuleLoad        | `sys_on_load`       | Tworzy tabele SQL                 |
| OnClientEnter       | `sys_on_enter`      | Przywraca efekty, startuje tick   |
| OnClientLeave       | `sys_on_leave`      | Zatrzymuje tick, czyści efekty    |

Jeśli moduł ma już skrypty OnClientEnter/Leave, wywołaj z nich bezpośrednio:

```nss
// W istniejącym OnClientEnter:
#include "lib_vic"
// ...
VicRestoreEffects(GetEnteringObject());
VicStartTick(GetEnteringObject());
```

## NWNX

Brak — moduł używa wyłącznie NWScript + NWN EE NUI + `SqlPrepareQueryCampaign`.

## SQL

Baza kampanii: `"vices"` (plik `vices.sqlite3` w folderze modułu lub kampanii).  
Tabela tworzona automatycznie przy OnModuleLoad (`CREATE TABLE IF NOT EXISTS`).

## Demo placeable

Stwórz dowolny placeable, ustaw skrypt OnUsed na `test_vic`.  
Gracz kliknie → otworzy panel Nałogów → może spożywać substancje i próbować odwyku.

## Integracja z systemem przedmiotów

Aby wymagać konkretnego przedmiotu do spożycia, w logice sprzedawcy/item:

```nss
#include "lib_vic"

// W skrypcie OnUsed na przedmiocie (lub OnActivateItem):
void main()
{
    object oPC   = GetItemActivator();      // lub GetLastUsedBy()
    object oItem = GetItemActivated();      // przedmiot

    // np. sprawdź tag
    if(GetTag(oItem) == "vic_moonfire_bottle")
    {
        DestroyObject(oItem);               // konsumuje przedmiot
        VicConsumeDose(oPC, VICE_MOONFIRE);
    }
}
```

Sugerowane tagi przedmiotów:

| Substance         | Tag przedmiotu                |
|-------------------|-------------------------------|
| Księżycowy Trunek | `vic_moonfire_bottle`         |
| Proch Snów        | `vic_dreamdust_pouch`         |
| Krew Demona       | `vic_demon_blood_vial`        |
| Czarny Korzeń     | `vic_blackroot_extract`       |
| Mleko Czarownicy  | `vic_witch_milk_flask`        |
| Pasta Cienia      | `vic_shadow_paste_jar`        |

## Efekty mechaniczne per substancja

### Księżycowy Trunek (VICE_MOONFIRE = 0)
- **Nasycony:** +STR, +CON, -INT
- **Odstawienie:** -STR, -DEX; poziom 4+ dodaje VFX_DUR_BLUR

### Proch Snów (VICE_DREAMDUST = 1)
- **Nasycony:** +WIS, +CHA, -DEX
- **Odstawienie:** -WIS, -CHA; poziom 3+ dodaje VFX_DUR_MIND_AFFECTING_NEGATIVE

### Krew Demona (VICE_DEMON_BLOOD = 2)
- **Nasycony:** +STR+1, +AB (misc), -CHA, aura czerwona
- **Odstawienie:** -STR+1, -CON; poziom 3+ aura pulsująca

### Czarny Korzeń (VICE_BLACKROOT = 3)
- **Nasycony:** +CON, immunity:fear, -WIS
- **Odstawienie:** -CON, -WIS; poziom 2+ VFX_DUR_MIND_AFFECTING_FEAR

### Mleko Czarownicy (VICE_WITCH_MILK = 4)
- **Nasycony:** +CHA, +Persuade, -CON
- **Odstawienie:** -CHA, -Persuade

### Pasta Cienia (VICE_SHADOW_PASTE = 5)
- **Nasycony:** +Hide×2, +Move Silently, Ultravision, -Spot
- **Odstawienie:** -Hide×2, -Move Silently; poziom 3+ -DEX

## Mechanika uzależnienia

- Poziomy 1–5; poziom 0 = czysta postać.
- Pierwsze spożycie zawsze daje poziom 1.
- Każde kolejne spożycie: 20% szans na podniesienie poziomu.
- Odwyk: 30 min bez dawki + szansa sukcesu (80% na poziomie 1, −15% na każdy poziom, min 10%).
- Nieudany odwyk przy poziomie 3+ może podnieść poziom o 1 (30% szans).
- Naturalne oczyszczenie: 24h bez dawki, w stanie odstawienia → poziom −1 automatycznie.
- Tick sprawdza stan co 60 sekund. Przejścia: Nasycony → Pragnienie → Odstawienie.

## Co celowo pominięto

- Brak wizualnych ikon substancji (wymagałoby pliku HAK z grafikami).
- Brak integracji z systemem walutowym (zakup dawek od sprzedawcy).
- Brak powiadomień DM o stanie uzależnienia graczy.
- Brak logowania historii dawek (tabela ma `total_doses` ale bez timestampów per dawkę).
