# Haruspicy — Integracja

## Co to robi

Pozwala graczom odczytywać wnętrzności zabitych stworzeń jako wróżbę.
Po zabiciu stworzenia (CR >= 2, nie-konstrukt) zwłoki są oznaczane jako
"czytelne". Gracz używa **Zestawu Haruspika** (`haru_kit`) i wskazuje
zwłoki. Otwiera się okno NUI z 6 narządami i ich znakami (pomyślny /
neutralny / zły omen). Na podstawie sumy znaków wyświetlone zostaje
proroctwo i efekt mechaniczny. Gracz klika "Przyjmij Wróżbę" — efekt
jest aplikowany, odczyt ląduje w kronice SQL.

## Wymagania

- NWN:EE 8193.35+ (NUI, SqlPrepareQueryCampaign, GetChallengeRating)
- Brak zależności NWNX
- Kampania SQLite o nazwie `haruspicy` (tworzona automatycznie)

## Skrypty — jakie hooki podpiąć

| Zdarzenie modułu | Skrypt | Uwagi |
|---|---|---|
| `OnModuleLoad` | `sys_on_load` | Tworzy tabele SQL |
| `OnCreatureDeath` | `sys_on_death` | Markuje zwłoki jako czytelne |
| `OnActivateItem` | `sys_on_activate` | Obsługuje użycie `haru_kit` |
| `OnPlayerTarget` | `sys_on_target` | Zbiera wynik trybu celowania |

Jeśli moduł już ma własne skrypty dla tych zdarzeń, wywołaj
odpowiednią funkcję wewnątrz — np. na końcu istniejącego
`OnCreatureDeath` dodaj:

```nss
#include "lib_haru"
// ...
// Na końcu istniejącego handlera:
int nCR = FloatToInt(GetChallengeRating(oDead));
if(!GetIsPC(oDead) && GetRacialType(oDead) != RACIAL_TYPE_CONSTRUCT && nCR >= 2)
{
    SetLocalInt(oDead, HARU_SRC_READABLE, 1);
    SetLocalString(oDead, HARU_SRC_CNAME, GetName(oDead));
    SetLocalInt(oDead, HARU_SRC_CTYPE, HaruClassifyCreature(oDead));
    SetLocalInt(oDead, HARU_SRC_CR, nCR);
}
```

Dla zdarzenia **creature's own OnDeath** (skrypt na samym potworze),
zamień `GetLastKilled()` w `sys_on_death.nss` na `OBJECT_SELF`.

## Przedmiot: Zestaw Haruspika

Utwórz item o tagu `haru_kit` (resref dowolny). Powinien być:
- noszony w ekwipunku (Miscellaneous Equipment lub Tool)
- aktywowany przez prawy klik → Use

Gracz otrzymuje go startowo lub kupuje u handlarza.

## Test bez .mod

Umieść placeable z OnUsed = `test_haru` w dowolnej lokacji.
Skrypt symuluje zabitego wilka i otwiera pełne okno czytania.
Klknij "Przyjmij Wróżbę" — efekt jest aplikowany, odczyt zapisywany.

## Skrypt `sys_on_death.nss` — tryb creature-event

Domyślnie `sys_on_death.nss` zakłada, że jest podpięty pod
`OnCreatureDeath` modułu (OBJECT_SELF = moduł, GetLastKilled() = ofiara).
Jeśli podpinasz go bezpośrednio pod OnDeath **stworzenia**, zmień
pierwszą linię `main()`:

```nss
// Zamiast:
object oDead = GetLastKilled();
// Użyj:
object oDead = OBJECT_SELF;
```

## Co celowo pominięto

- Niestandardowy resref itemu `haru_kit` — DM tworzy sam z tagu
- Animacje / efekty dźwiękowe — framework nie zawiera HAK z SFX
- Interfejs DM do ręcznego oznaczania zwłok (dostępny przez skrypt)
- Różnicowanie znaków zależnie od frakcji zabójcy
