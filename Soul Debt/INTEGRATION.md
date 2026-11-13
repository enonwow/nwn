# Soul Debt — Instrukcja integracji

## Co to robi

System długu dusz umożliwia graczom (uzdrowicielom/kapłanom) rejestrowanie
roszczeń wobec postaci, które „uratowali" od śmierci. Dłużnik może:

- **Przyjąć** dług (zmiana statusu `pending` → `active`)
- **Spłacić** go złotem (500 sz., zamknięcie)
- **Odrzucić** — ściągając na siebie natychmiastowe 15 HP i 24-godzinne
  przekleństwo (-2 do wszystkich rzutów obronnych)

Wierzyciel może:

- **Wywołać** dług aktywny — dłużnik traci 3 HP co 5 minut, dopóki nie
  ureguluje zobowiązania
- **Odpuścić** dług bez konsekwencji

Wszystkie dane są trwałe (SQLite), okno NUI `Księga Dusz` dostępne z
każdego miejsca przez skrypt `test_sdebt.nss` (na placeable) lub przez
wywołanie `SDebtOpenWindow(oPC)` z dowolnego skryptu.

## Pliki do dodania do HAK

Wszystkie pliki z folderu `Soul Debt/Scripts/`:

| Plik | Rola |
|---|---|
| `sql_sdebt.nss` | Schematy SQL i zapytania |
| `lib_sdebt_def.nss` | Stałe, ID bindów, deklaracje |
| `lib_sdebt.nss` | Rdzeń: NUI, logika gry, efekty |
| `lib_sdebt_ev.nss` | Handler eventów NUI |
| `sys_on_load.nss` | Init tabel przy starcie modułu |
| `sys_on_enter.nss` | Rejestracja gracza + notyfikacje |
| `test_sdebt.nss` | OnUsed na placeable demonstracyjnym |
| `lib_nui.nss` | Pomocnicze stałe i funkcje NUI |
| `lib_nui_utility.nss` | Narzędzia NUI |

## Hooki do podpięcia w istniejącym module

| Hook modułu | Skrypt | Uwagi |
|---|---|---|
| OnModuleLoad | `sys_on_load.nss` | Inicjalizuje tabele SQLite |
| OnClientEnter | `sys_on_enter.nss` | Rejestruje gracza, sprawdza wywołane długi |

Opcjonalnie: po `RaiseDead` / `Resurrection` możesz wywołać
`SDebtOpenWindow(oCaster)` aby kapłan mógł od razu zarejestrować roszczenie.
Przykład (w skrypcie OnSpellCastAt lub własnym wrapperze):

```nwscript
#include "lib_sdebt"

// Po pomyślnym rzuceniu Raise Dead / Resurrection na PC:
void SDebtSuggestClaim(object oCaster, object oTarget)
{
    if(!GetIsPC(oCaster) || !GetIsPC(oTarget)) return;
    string sMsg = "[Dług Duszy] Uratowałeś " + GetName(oTarget)
                + ". Otwórz Księgę Dusz, by zarejestrować roszczenie.";
    SendMessageToPC(oCaster, sMsg);
}
```

## Zależności

- **NWScript + NUI** — wbudowane w NWN:EE, brak zewnętrznych zależności
- **SQLite campaign DB** — przechowywana w `soul_debt.sqlite` (tworzona automatycznie)
- Brak wymagań NWNX

## Parametry konfiguracyjne (w `lib_sdebt_def.nss`)

| Stała | Wartość domyślna | Opis |
|---|---|---|
| `SDEBT_REPAY_GOLD` | 500 | Złoto za spłatę długu |
| `SDEBT_INVOKE_DMG` | 3 | HP tracone na tick przy wywołaniu |
| `SDEBT_INVOKE_TICK` | 300.0 | Interwał ticków (sekundy) |
| `SDEBT_RENOUNCE_DMG` | 15 | HP tracone przy odrzuceniu |
| `SDEBT_CURSE_DURATION` | 86400 | Czas trwania przekleństwa (sekundy) |

## Co celowo pominięto

- Brak limitu ilości długów na gracza (można dodać walidację w `SDebtCreate`)
- Brak mechanizmu „spłaty przysługą" przez GM (można dodać status `service_pending`)
- Brak wizualnego efektu pieczęci na modelu postaci (wymagałoby niestandardowych
  VFX w HAK)
- Brak ekspiracji długów po upłynięciu czasu (można dodać pole `expires_at`
  i warunek w zapytaniach)
