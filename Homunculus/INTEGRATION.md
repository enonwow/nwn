# Homunculus — Integracja z modułem NWN

## Co to robi

System alchemicznego towarzysza. Gracz zbiera 3 reagenty alchemiczne i wytwarza
homunkulus — małą istotę, która towarzyszy mu w podróży (manifestuje się jako
orbita VFX wokół postaci). Więź rośnie z każdym karmieniem i odblokowuje kolejne
zdolności dobowe. Niekarmiony homunkulus traci więź; jej zanik do 0 permanentnie
go zabija. Przy więzi 10 gracz może dokonać Poświęcenia — zniszczyć towarzysza
w zamian za jednorazowy, potężny efekt.

## Skrypty do podpięcia

| Zdarzenie modułu      | Skrypt              |
|-----------------------|---------------------|
| OnModuleLoad          | `sys_on_load.nss`   |
| OnClientEnter         | `sys_on_enter.nss`  |

Panel otwierany jest przez umieszczony w świecie **Placeable** (np. stół alchemiczny)
z podpiętym skryptem `test_hom.nss` jako OnUsed.

## Wymagania — NWNX

Brak. Moduł działa wyłącznie w oparciu o NWScript + NUI + wbudowaną bazę danych
SQLite (SqlPrepareQueryCampaign z nazwą kampanii `"homunculus"`).

## Wymagania — Hak

Brak. Wszystkie VFX i resrefy to standardowe assety NWN:EE.

Jeśli chcesz podmienić VFX towarzysza (domyślnie `VFX_DUR_IOUNSTONE_BLUE`),
zmień stałą `HOM_VFX` w `lib_hom_def.nss`.

## Przedmioty testowe (do dodania ręcznie lub przez skrypt)

| Tag                | Rola                                                         |
|--------------------|--------------------------------------------------------------|
| `hom_reagent`      | Reagent do stworzenia homunkulus (potrzeba 3 sztuk)          |
| `hom_feed`         | Pokarm — 1 sztuka zużywana przy każdym karmieniu             |

W środowisku testowym możesz użyć dowolnych istniejących itemów i tymczasowo
zmienić ich tagi na powyższe w Toolset, lub rozdać graczowi przez konsolę DM.

## Szybki test

1. Dodaj `sys_on_load.nss` do zdarzenia OnModuleLoad.
2. Dodaj `sys_on_enter.nss` do zdarzenia OnClientEnter.
3. Umieść placeable z `test_hom.nss` na mapie.
4. Wejdź do modułu, dodaj sobie 3 itemy z tagiem `hom_reagent`.
5. Użyj placeable — otwórz panel, kliknij „Stwórz Homunkulus".
6. Dodaj item z tagiem `hom_feed` i kliknij „Nakarm".
7. Sprawdź VFX, zdolności i dziennik.

## Celowo pominięto

- Fizyczne stworzenie poruszające się po mapie — wymaga NWNX Creature lub
  dedykowanego skryptu AI heartbeat; pominięto, by moduł był standalone.
- Wiele rodzajów homunkulus (ziemny, ognisty itp.) — rozszerzenie możliwe przez
  dodanie kolumny `type` do tabeli i wariantów VFX/zdolności.
- Śmierć homunkulus w walce (aktualnie tylko przez głód lub poświęcenie) —
  można dodać przez hook OnCreatureDeath jeśli dodano fizycznego NPC.
- Limit 1 homunkulus na gracza jest zamierzony (klimat mroczny — wyjątkowa więź).
