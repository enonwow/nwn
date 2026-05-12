# Czarne Targowisko — Integracja

## Zależności skryptowe

Moduł wymaga `lib_nui.nss` i `lib_nui_utility.nss` (dostarczone w module **Mailbox** lub dowolnym innym module korzystającym z NUI helpers). Dodaj te pliki do modułu jeśli jeszcze tam nie są.

## Hooki modułu

| Zdarzenie modułu | Skrypt           | Co robi                                     |
|------------------|------------------|---------------------------------------------|
| OnModuleLoad     | `sys_on_load`    | Tworzy tabele SQLite, seeduje katalog, rotuje stock |
| OnClientEnter    | `sys_on_enter`   | Rejestruje gracza, opada gorąco, sprawdza strażników |
| OnPlayerTarget   | `sys_on_target`  | Obsługuje wybranie przedmiotu do sprzedaży  |

Każdy skrypt może być wywołany z istniejącego hooka:
```nss
// W twoim sys_on_load.nss:
ExecuteScript("sys_on_load", GetModule());   // lub #include + wywołanie funkcji
```

## Placeable do testu

1. W toolsecie utwórz `Placeable` (np. drzwi / skrzynię).
2. Ustaw skrypt `OnUsed` na `test_bmt`.
3. Umieść placeable w obszarze.

Gracz klika placeable → otwiera się okno Czarnego Targowiska.

## Baza danych SQLite

Dane globalne (stock, katalog, gracze) trzymane w kampanii o nazwie `blackmarket`.  
Plik SQLite: `<server_data>/campaign_blackmarket.sqlite`.

Schemat jest idempotentny — `CREATE TABLE IF NOT EXISTS` — bezpieczny przy restarcie.

## Dodawanie własnych przedmiotów do katalogu

Metoda 1 — SQL ręczny (DM/admin):
```sql
INSERT INTO bmt_catalog (resref, item_name, flavor, base_gold, max_stack)
VALUES ('moj_resref', 'Nazwa dla gracza', 'Klimatyczny opis.', 300, 2);
```

Metoda 2 — edycja `BmtSeedCatalog()` w `sql_bmt.nss` przed pierwszym uruchomieniem (przed seedem).

Aby wymusić odświeżenie stocku (np. po dodaniu nowych itemów):
```sql
DELETE FROM bmt_stock;
```
Przy kolejnym wejściu gracza/restarcie moduł dobierze nowy losowy zestaw.

## Flagi wystawione dla innych systemów

| Zmienna lokalna na PC | Typ | Znaczenie                          |
|-----------------------|-----|------------------------------------|
| `BMT_WANTED`          | int | 1 = gracz jest aktywnie śledzony   |

Inne systemy (straże, NPC, sklepy) mogą sprawdzać `GetLocalInt(oPC, "BMT_WANTED")`.

## Konfiguracja (lib_bmt_def.nss)

| Stała              | Domyślnie | Opis                               |
|--------------------|-----------|------------------------------------|
| `BMT_REFRESH_SECS` | 21600     | Rotacja stocku (sekundy; 6h)       |
| `BMT_STOCK_COUNT`  | 8         | Liczba slotów w rotującym stocku   |
| `BMT_FENCE_RATE`   | 40        | % wartości wypłacane przy sprzedaży |
| `BMT_HEAT_PER_BUY` | 6         | Gorąco za zakup                    |
| `BMT_HEAT_PER_SELL`| 4         | Gorąco za sprzedaż                 |
| `BMT_HEAT_WARN`    | 70        | Próg dla efektów strażniczych      |
| `BMT_HEAT_DECAY_HOUR`| 2       | Utrata gorąca na realną godzinę    |

## Co celowo pominięto

- **Spawn strażników jako NPC** — wymaga resrefa z haka; zamiast tego system wystawia flagę `BMT_WANTED` i efekt VFX jako placeholder; integracja z AI straży należy do twórcy modułu.
- **Okno historii transakcji** — tabela `bmt_transactions` i widok historii nie zostały dodane, żeby nie komplikować UI; można dołożyć jako rozszerzenie.
- **Limit zakupów na postać** — stock jest globalny (wszyscy gracze dzielą ten sam pool qty); per-PC limit można dodać przez tabelę `bmt_purchase_log`.
- **Animacja NPC Passura** — flirt/dialog z NPC wymaga skryptu konwersacji; `test_bmt.nss` otwiera okno bezpośrednio z placeable.
