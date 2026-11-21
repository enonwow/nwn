# Alchemy — Instrukcja integracji

## Opis

System alchemii pozwala graczom odkrywać i warzyć mikstury przy stole alchemika.
Każda postać posiada własną listę poznanych przepisów (persystowaną w SQLite).
Warzenie nieznanej kombinacji niszczy składniki i może zakończyć się wybuchem;
trafienie w nieznany przepis odkrywa go i nagradza bonusowym XP.

## Hooki modułu

| Zdarzenie modułu      | Skrypt                          |
|-----------------------|---------------------------------|
| OnModuleLoad          | `sys_on_load.nss`               |
| OnClientEnter         | `sys_on_enter.nss`              |
| OnPlayerTarget        | `sys_on_target.nss`             |

> Jeśli moduł ma już własne skrypty dla tych zdarzeń, dodaj wywołania
> funkcji alchemy na końcu istniejących skryptów:
>
> ```nss
> // w OnModuleLoad:
> AlchCreateTables();
>
> // w OnClientEnter:
> if(GetIsPC(GetEnteringObject())) {
>     int nKnown = AlchGetKnownCount(GetEnteringObject());
>     // ... opcjonalna wiadomość
> }
>
> // w OnPlayerTarget:
> object oPC = GetLastPlayerToSelectTarget();
> if(GetIsPC(oPC) && NuiFindWindow(oPC, ALCH_WINDOW) != 0
> && GetLocalInt(oPC, ALCH_LVAR_TARGETING) > 0)
>     AlchHandleTargeting(oPC);
> ```

## Placeable — stół alchemika

1. Umieść dowolny placeable z tag `alchemy_bench` (lub innym).
2. Ustaw jego skrypt OnUsed na `test_alch`.
3. W produkcyjnym module zastąp `test_alch` własnym skryptem, który:
   - Sprawdza odległość gracza od stołu (opcjonalnie).
   - Sprawdza umiejętność Craft Alchemy (opcjonalnie).
   - Woła `AlchOpenWindow(oPC)`.

## HAK / zasoby

Moduł wymaga następujących resrefów w HAK-u lub module:

### Składniki (resrefy = tagi itemów)

| Tag / resref              | Opis                          |
|---------------------------|-------------------------------|
| `alch_herb_glasswort`     | Ziele głogu                   |
| `alch_herb_elfwood`       | Łzy elfiego drzewa            |
| `alch_herb_bloodmoss`     | Krwawy mech                   |
| `alch_herb_archangel`     | Ziele Archanioła              |
| `alch_mineral_bezoar`     | Kamień bezoarowy              |
| `alch_herb_nightshade`    | Czarny bez                    |
| `alch_fat_shadowcat`      | Tłuszcz kota cienia           |
| `alch_herb_firecoral`     | Ognisty koral                 |
| `alch_mineral_sulfur`     | Siarka                        |
| `alch_fat_salamander`     | Tłuszcz salamandry            |
| `alch_gland_viper`        | Gruczoł jadowy żmii           |
| `alch_herb_cowparsley`    | Krowi pasternak               |
| `alch_gland_sparrowheart` | Serce wróbla                  |
| `alch_herb_colibrina`     | Ziele kolibrzycy              |
| `alch_mineral_quartz`     | Kryształ kwarcu               |
| `alch_clay_deep`          | Glina z Głębinowych Kopalni   |
| `alch_oil_stone`          | Olej kamienny                 |
| `alch_herb_deathcap`      | Śmiertelna czapeczka          |
| `alch_blood_unholy`       | Krew nieświęta                |
| `alch_mineral_ashbone`    | Proch z kości                 |
| `alch_blood_witch`        | Krew wiedźmy                  |
| `alch_shroom_shadow`      | Grzyb Cienia                  |
| `alch_dust_rune`          | Pył z rozgniecionej runy      |

### Rezultaty (resrefy itemów wytwarzanych)

| Resref                | Przepis                        |
|-----------------------|--------------------------------|
| `alch_pot_heal_s`     | Eliksir Uzdrowienia            |
| `alch_pot_heal_l`     | Wielki Eliksir Uzdrowienia     |
| `alch_pot_antidote`   | Antidotum                      |
| `alch_oil_shadow`     | Olej Cienia                    |
| `alch_pot_fireres`    | Napar z Ognistego Korzenia     |
| `alch_oil_poison`     | Trucizna Ostrza                |
| `alch_pot_speed`      | Esencja Przyspieszenia         |
| `alch_pot_stone`      | Wywar z Kamiennej Skóry        |
| `alch_pot_death`      | Nektar Umarłych                |
| `alch_pot_witch`      | Krew Czarownicy                |

Wszystkie itemy składnikowe i wynikowe muszą posiadać tagi identyczne z resrefami
(lub resrefy muszą być dostępne przez `CreateItemOnObject`). Rekomendowane:
stworzenie itemów w toolsecie z tymi resrefami i dodanie ich do HAK-u.

## Baza danych

Używa SQLite campaign database `"alchemy"` (plik `alchemy.sqlite` w katalogu serwera).
Tabela `alch_known` jest tworzona automatycznie przy `sys_on_load`.
Brak zależności od NWNX — używa wyłącznie natywnych funkcji `SqlPrepareQueryCampaign`.

## NWNX

Brak wymagań NWNX. Moduł działa na czystym NWN:EE.

## Jak nauczyć gracza przepisu z zewnętrznego skryptu

```nss
#include "sql_alch"
AlchLearnRecipe(oPC, ALCH_RCP_HEAL_MINOR);   // lub dowolne ID z lib_alch_def
```

## Celowo pominięto

- Grafika tła okna (brak `alch_bg` w bindach) — łatwo dodać DrawList jak w Mailbox.
- Poziomy umiejętności alchemii (można dodać sprawdzenie GetSkillRank w AlchBrew).
- Receptury dynamiczne / definiowane przez DM w runtime (wymagałoby dodatkowej tabeli SQL).
- System jakości (szansa na wytworzenie wersji wyższej/niższej jakości).
