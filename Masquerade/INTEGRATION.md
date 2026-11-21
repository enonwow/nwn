# Masquerade — Integracja

## Wymagane hooki

| Zdarzenie modułu        | Skrypt do wywołania       | Uwagi                                    |
|-------------------------|---------------------------|------------------------------------------|
| OnModuleLoad            | `sys_on_load.nss`         | Tworzy tabele SQL                        |
| OnClientEnter           | `sys_on_enter.nss`        | Rejestruje maski z ekwipunku, reset      |
| OnClientLeave           | `sys_on_leave.nss`        | Zdejmuje maskę przy wylogowaniu          |
| OnPlayerTarget          | `sys_on_target.nss`       | Opcjonalny: nalicza podejrzenia za czary |

Jeśli moduł używa wielu skryptów na jednym zdarzeniu, wywołuj je przez wrapper:

```nss
// Przykładowy sys_on_enter.nss w module
#include "sys_on_enter"   // istniejący
void main() {
    ExecuteScript("sys_on_enter", OBJECT_SELF);  // istniejący
    ExecuteScript("msk_enter",    OBJECT_SELF);  // ten moduł
}
```

Lub przez NWNX_Events jeśli dostępne:
```nss
NWNX_Events_AddScript("NWNX_ON_CLIENT_ENTER_AFTER", "sys_on_enter");
```

## Baza danych

Kampania SQLite: `masquerade` (plik `masquerade.sqlite` w katalogu kampanii).

Tabele:
- `msk_masks` — definicje masek (seed w `MskSeedDefaultMasks`)
- `msk_owned` — właściciele masek per PC UUID

## Jak uruchomić test

1. Umieść w obszarze placeable z tagiem `msk_test_chest`.
2. Ustaw `OnUsed` → `test_msk`.
3. Podejdź i użyj — gracz otrzyma 5 startowych masek i otworzy panel NUI.

## NWNX

Nie wymagany. Cały moduł działa na standardowym NWScript + SQLite.

Opcjonalnie: `NWNX_Events` ułatwia podpięcie wielu skryptów pod to samo zdarzenie.

## Dodawanie własnych masek

Wstaw wiersz do `msk_masks`:
```sql
INSERT INTO msk_masks (tag, name, flavor, susp_rate)
VALUES ('msk_mask_assassin', 'Oblicze Zabójcy',
        'Twarz, której nikt nie pamięta — bo nikt, kto ją widział, nie żył dość długo.', 3);
```

`susp_rate` to mnożnik biernego wzrostu podejrzeń (1 = wolny, 3 = szybki).

Następnie daj graczowi maskę przez:
```nss
MskRegisterMaskForPC(oPC, "msk_mask_assassin");
```

## Co pominięto celowo

- Fizyczne itemy-maski w haku — mechanika działa czysto przez DB; hakowcy mogą dodać itemy ozdobne.
- Per-frakcyjne podejrzenia — uproszczono do jednego globalnego miernika.
- DM-tool do resetu masek — można zrobić przez bezpośredni SQL (`MskRestoreMask`).
