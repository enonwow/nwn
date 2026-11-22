# Flayed Masks — Integration Guide

## Co to robi

Moduł umożliwia graczom zdzieranie twarzy pokonanych humanoidów
i przechowywanie ich w magicznym Grimuarze. Założona maska całkowicie
zmienia wygląd postaci (wszystkie body party + kolory) i nadaje pasywny
bonus rasowy. Każda maska ma ograniczoną liczbę użyć; przeklęte maski
szepczą do nosiciela mroczne frazy po polsku.

## Wymagane hooki w module

| Zdarzenie         | Skrypt           | Uwaga                                           |
|-------------------|------------------|-------------------------------------------------|
| OnModuleLoad      | `sys_on_load`    | Tworzy tabele SQLite (idempotentne).            |
| OnClientEnter     | `sys_on_enter`   | Przywraca nałożoną maskę po relogu.             |
| OnPlayerTarget    | `sys_on_target`  | Obsługuje zrywanie twarzy (EnterTargetingMode). |

Jeśli moduł już korzysta z tych zdarzeń, wywołaj funkcje z tego modułu
wewnątrz istniejących skryptów:

```nss
// W istniejącym sys_on_load:
#include "lib_fmask_def"
FmaskCreateTables();

// W istniejącym sys_on_enter:
#include "lib_fmask"
// (na końcu handlera)
FmaskRestoreOnEnter(oPC);  // odpowiednik logiki z sys_on_enter.nss

// W istniejącym sys_on_target:
#include "lib_fmask"
// (na początku handlera, przed innymi modułami)
if(GetLocalInt(oPC, FMASK_LVAR_TARGETING))
{
    DeleteLocalInt(oPC, FMASK_LVAR_TARGETING);
    FmaskHandleFlayTarget(oPC);
    return;
}
```

## Placeable — Grimuar

Stwórz placeable (np. rzeźbiony sarkofag / skrzynia) z OnUsed:
`test_fmask`

Możesz też otworzyć okno z dowolnego miejsca przez:
```nss
#include "lib_fmask"
CreateFmaskWindow(oPC);
```

## Baza danych

Kampania SQLite: `fmask`
- `fmask_collection` — kolekcja masek per gracz
- `fmask_worn` — aktualnie nałożona maska (do odtworzenia po relogu)

## Zależności NWNX

Brak — moduł używa wyłącznie natywnego NWScript + NUI.

## Celowo pominięto

- Animacja zakładania/zdejmowania maski (brak odpowiedniego VFX w standardowym HAK)
- System PvP — flay można wykonać tylko na NPC (warunek: HP > 0 sprawdzany przez gracza)
- Podgląd miniatury maski (NUI nie wspiera dynamicznego renderu creature portret w oknie listy)
- Limit czasowy noszenia — można go dodać przez DelayCommand usuwający maskę
