# Death's Ledger — Integracja

## Czym jest ten moduł

System paktu ze Śmiercią. Gdy gracz miałby umrzeć, pojawia się okno NUI
z propozycją wskrzeszenia za cenę rosnącego długu (0–10). Każdy poziom długu
nakłada kumulatywne kary mechaniczne i co dobę przyzywa Posłańca Śmierci.
Dług można zmniejszyć przez ołtarz: złoto, trwałą utratę HP lub 7-dniową pokutę.

## Wymagane NWNX

Brak. Moduł używa wyłącznie natywnego NWScript i SQLite przez
`SqlPrepareQueryCampaign`. Działa na czystym NWN:EE 8193+.

## Hooki do podpięcia

| Zdarzenie modułu       | Skrypt          |
|------------------------|-----------------|
| OnModuleLoad           | `sys_on_load`   |
| OnClientEnter          | `sys_on_enter`  |
| OnPlayerDying          | `sys_on_dying`  |
| OnModuleHeartBeat      | `sys_on_hb`     |

Jeśli masz już istniejące skrypty na tych zdarzeniach, wywołaj
odpowiednie funkcje z `#include "lib_dlg"` wewnątrz swoich skryptów:

```nwscript
// przykład OnPlayerDying
#include "lib_dlg"
void main() {
    // ... twój kod ...
    object oPC = GetLastPlayerDied();
    if(GetIsPC(oPC) && !GetLocalInt(oPC, DLG_LVAR_DYING))
        ExecuteScript("sys_on_dying", GetModule());
}
```

## Obiekty w świecie

### Ołtarz Śmierci (obowiązkowy)
- Stwórz placeable z tagiem `DLG_ALTAR`
- Skrypt OnUsed: `test_dlg`
- Po kliknięciu gracz z długiem > 0 widzi okno księgi

### Obiekt testowy (opcjonalny)
- Placeable z tagiem `DLG_TEST`, skrypt OnUsed: `test_dlg`
- Otwiera okno paktu jak podczas umierania (do testów)

### Obiekt informacyjny (opcjonalny)
- Placeable z innym tagiem, skrypt OnUsed: `test_dlg`
- Wypisuje do czatu aktualny status długu

## Baza danych SQLite

Kampania: `deaths_ledger`  
Tabela: `dlg_debt`

| Kolumna          | Typ     | Opis                                   |
|------------------|---------|----------------------------------------|
| uuid             | TEXT PK | UUID postaci                           |
| debt             | INTEGER | Obecny poziom długu (0–10)             |
| hp_penalty       | INTEGER | Suma permanentnych kar HP              |
| last_bargain     | INTEGER | Unix timestamp ostatniego paktu        |
| last_emissary    | INTEGER | Unix timestamp ostatniego Posłańca     |
| penance_deadline | INTEGER | Unix timestamp końca pokuty (0 = brak) |

## Efekty mechaniczne według poziomu

| Dług | Rzuty vs śmierć | Rzuty vs neg. | Siła | Posłaniec | Aura |
|------|-----------------|---------------|------|-----------|------|
| 1    | -1              | —             | —    | Nie       | Nie  |
| 2    | -1              | -2            | —    | Nie       | Nie  |
| 3    | -1              | -2            | -2   | Tak       | Nie  |
| 4    | -2              | -2            | -3   | Tak       | Nie  |
| 5    | -2              | -3            | -3   | Tak       | Tak  |
| 6    | -2              | -3            | -4   | Tak       | Tak  |
| 7    | -3              | -3            | -4   | Tak       | Tak  |
| 8    | -3              | -4            | -4   | Tak       | Tak  |
| 9    | -3              | -4            | -5   | Tak       | Tak  |
| 10   | -3              | -4            | -5   | Tak       | Tak  |

## Co celowo pominięto

- Grafika/hak: moduł nie wymaga własnego .hak; emissary używa stockowych
  resrefów NWN (szkielet, cień, wight). Można je zmienić w `lib_dlg_def.nss`.
- DM-tool do ręcznego ustawiania długu (można dodać jako oddzielny skrypt).
- Plik .mod demonstracyjny: środowisko build nie posiada narzędzi do pakowania
  `.mod`; zamiast tego dostarczono ten plik INTEGRATION.md.
- System nagród za unikanie walki (pokuta honorowa): implementacja wymagałaby
  śledzenia każdej walki co jest kosztowne; zamiast tego pokuta działa na honor
  gracza + timer.
