# Scrying Mirror — Zwierciadlo Dalekowzrocznosci

System magicznych zwierciadeł nastrojonych na konkretne lokacje.
Gracze wpatruja sie w zwierciadlo, widzac kto aktualnie przebywa
w danym obszarze, kosztem reagentu; obserwowani moga wyczuc spojrzenie.

## Wymagania

- NWN:EE 8193.35+
- Brak zaleznosci od NWNX
- SQLite (wbudowany w NWN:EE) — baza `scrying`

## Hooki modulu

| Zdarzenie modulu | Skrypt                        | Co dodac                    |
|-----------------|-------------------------------|-----------------------------|
| OnModuleLoad    | `sys_on_load.nss`             | `ScryCreateTables()`        |

Wywolaj `ScryCreateTables()` raz przy starcie modulu.
Brak hooka OnClientEnter — sledzenie lokacji odbywa sie w czasie
rzeczywistym przez `GetArea(oPC)`.

## Placeable testowy

1. Utwórz placeable "Krysztalne Zrodlo" w obszarze testowym.
2. Skrypt OnUsed: `test_scry`.
3. Gracze i DM uzywaja go, by otworzyc okno systemu.

## Itemy (HAK / Toolset)

Nalezy stworzyc dwa blueprinty przedmiotow:

| Tag             | Nazwa                | Opis                                          |
|----------------|----------------------|-----------------------------------------------|
| `scry_tear`    | Lza Jasnowidza       | Stackowalny, 1 zu zycia / wpatrzenie           |
| `scry_crystal` | Kamien Krysztalowy   | 1 szt. / nastrojenie (nie DM)                 |

Przedmioty moga byc craftowane, znajdowane w skarbach lub sprzedawane
przez NPC — decyzja nalezaca do DM.

## Mechanika wpatrzenia

1. Gracz otwiera okno (placeable lub komenda DM).
2. Wybiera zwierciadlo z listy — widzi liczbe obecnosci w obszarze
   (darmowe, bez reagentu).
3. Klika **Wpatrz sie** — zuzywana jest 1 Lza Jasnowidza.
4. Wynik pokazuje imiona i stan zdrowia obserwowanych graczy.
5. Kazdy obserwowany gracz wykonuje automatycznie rzut na Czujnosc:
   - DC = 15 + modyfikator INT jasnowidza
   - Sukces: gracz widzi floating text "Czujesz na sobie obce spojrzenie..."
   - Wynik >= 25: gracz widzi imie obserwatora

## Nastrojenie nowego zwierciadla

- DM: zawsze mozliwe (bez kosztow).
- Gracz: musi posiadac Kamien Krysztalowy (zuzywany przy nastrojeniu).
- Nastrojenie rejestruje obszar, w ktorym stoi postac w chwili klikniecia.
- Limit: 20 aktywnych zwierciatel (stala `SCRY_MAX_MIRRORS`).

## Wygaszanie

Wlasciciel zwierciadla lub DM moze je wygasic przyciskiem **Wygasz**.
Wpis jest oznaczany jako nieaktywny (`is_active = 0`) — nie jest usuwany,
co pozwala na audyt historii.

## Co celowo pominieto

- Brak wizualnej minigry (widok krysztalu to tekst, nie render obszaru).
- Brak trybu "blokowania" lustra przez obserwowanego — mechanika
  kontrskrywingu ograniczona do ostrzezenia i ujawnienia twarzy.
- Brak timera wygasniecia nastrojenia — zwierciadla trwaja do wygaszenia
  przez wlasciciela lub DM.
- Brak persystencji "ostatnio obserwowany przez X" — mozliwe
  rozszerzenie w przyszlosci.
