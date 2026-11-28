# Primal Marks — Integracja

## Opis

System zbierania esencji z zabitych istot i tymczasowych transformacji. Pięć rodzajów esencji (Bestia, Nieumarły, Żywioł, Piekielny, Mroczna Feja). Po zdobyciu 100 pkt gracz może aktywować 3-minutową transformację z efektami bojowymi i wizualnymi. Po osiągnięciu 500 pkt łącznych dla danego typu pojawia się trwałe Piętno.

## Wymagania

- **NWN:EE 8193+** (NUI, SqlPrepareQueryCampaign)
- Brak wymagań NWNX.

## Hooki do podpięcia

### 1. OnModuleLoad

```
// W istniejącym handlerze OnModuleLoad:
ExecuteScript("sys_on_load", OBJECT_SELF);
```

### 2. OnClientEnter

```
// W istniejącym handlerze OnClientEnter:
ExecuteScript("sys_on_enter", GetEnteringObject());
```

### 3. OnCreatureDeath (WAŻNE)

```
// W istniejącym handlerze OnCreatureDeath NPC-ów:
ExecuteScript("sys_on_death", OBJECT_SELF);
```

Alternatywnie: ustaw `sys_on_death` jako skrypt OnDeath bezpośrednio na stworzeniach (w toolsecie).

### 4. Placeable testowy

Ustaw `test_mrk` jako skrypt OnUsed dowolnego placeable — użycie go otworzy okno Piętn.

Możesz też wywołać `MrkOpenWindow(oPC)` bezpośrednio z własnych skryptów konwersacji/GUI.

## Typy esencji i efekty transformacji

| Typ | Rasa NWN | Efekty transformacji (3 min) | Piętno trwałe |
|---|---|---|---|
| Bestia | ANIMAL, BEAST, MAGICAL_BEAST | +2 atak, +5 Search/Spot, Regen 1/6s | +1 STR |
| Nieumarły | UNDEAD | +2 AC (nat.), Aura Strachu, Imm. na Strach | +1 CON |
| Żywioł | ELEMENTAL | Odp. Ogień/Zimno/Elektr. 10, +1 caster level | Odp. Ogień 5 |
| Piekielny | OUTSIDER (evil) | +2 STR, +1d6 obrażeń ogniowych, +4 Intimidate | +1 CHA |
| Mroczna Feja | FEY, OUTSIDER (non-evil) | +4 DEX, 20% concealment, +2 SR | +1 DEX |

## Baza danych

Plik kampanii: `mrk` → tabela `mrk_data` z osobnym wierszem per UUID postaci.

## Co celowo pominięto

- Animacje polimorfizmu (PolymorPhObject) — zbyt inwazyjne bez HAK-a z własnymi modelami.
- UI z timerem (odliczanie CD) — NWN NUI nie ma natywnych timerów; CD wygasa przez DelayCommand, okno odświeża się przy ponownym otwarciu.
- Esencja z PvP — zbieranie esencji gracza mogłoby być używane do griefu.
