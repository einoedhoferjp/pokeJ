# Datenquellen

Stand der Recherche: Phase 0. Alle Angaben wurden aus den offiziellen
Dokumentationen entnommen (siehe Quellen unten). Nichts ist erfunden.

---

## 1. TCGdex — Stammdaten (Primärquelle)

- **Zweck:** Kartendaten (Name, Set, Nummer, Seltenheit, Illustrator, Varianten,
  Bild-URLs) und **Preise** (siehe §3).
- **Basis-URL:** `https://api.tcgdex.net/v2/{lang}/...`
  - Einzelkarte: `GET /v2/{lang}/cards/{id}` (z. B. `swsh3-136`)
  - Suche: `GET /v2/{lang}/cards?...`
  - Sets: `GET /v2/{lang}/sets`, `GET /v2/{lang}/sets/{id}`
  - GraphQL ebenfalls verfügbar.
- **Auth:** **keine** — kein API-Key erforderlich.
- **Rate-Limits:** keine publizierten harten Limits; Doku bittet um
  zurückhaltende Nutzung und **lokales Caching**.
- **Sprachen:** en, fr, es, de, it, pt-br, ja, zh-tw, id, th (im Aufbau:
  pt, nl, pl, ru, ko, zh-cn). Completeness je Sprache unterschiedlich.
- **Lizenz:** Die **Datenbank** steht unter der **MIT License** (kein
  Nintendo-/Pokémon-Endorsement).
- **Wichtige Felder:** `id`, `localId`, `name`, `category`, `illustrator`,
  `rarity`, `set{id,name,symbol,cardCount{official,total}}`, `image`,
  `variants{normal,reverse,holo,firstEdition,wPromo}`, `updated`, `pricing`.

### Bilder
- URL-Schema: `https://assets.tcgdex.net/{lang}/{serie}/{set}/{localId}/{quality}.{ext}`
  z. B. `.../high.webp` oder `.../low.png`.
- ⚠️ **Recht:** Die Datenbank ist MIT-lizenziert, die **Kartenbilder** sind es
  nicht. Pokémon-Kartenbilder und -inhalte sind urheberrechtlich geschützt
  (The Pokémon Company). Eine rechtliche Bewertung der Darstellung in der App
  steht aus.

### Bekannte Einschränkungen (aus TCGdex-FAQ)
- Nicht jede Karte hat Preise (alte EX/Full-Art, sehr neue oder regionale Karten).
- **Varianten-zu-Preis-Zuordnung ist fehlerhaft:** Regular und Special
  Illustration Rare können denselben Preis zeigen.
- Einige Cardmarket-/TCGPlayer-IDs sind falsch.
- Ein Feld `variants_detailed` mit **expliziten Marktplatz-IDs pro Variante**
  ist in Entwicklung und soll diese Probleme beheben.

---

## 2. Cardmarket — offizielle API (NICHT genutzt)

- **OAuth 1.0** (HMAC-SHA1-signierte Requests).
- **Zugang:** nur für **professionelle Verkäufer**, **manuelles
  Genehmigungsverfahren**; 3rd-Party-Apps nur für kommerzielle Accounts.
- Domainwechsel: `api.cardmarket.com` → `apiv2.cardmarket.com` bis Mai 2026.
- Das frühere `Product List` (gzip-CSV) ist **deprecated**.
- **Konsequenz:** Für diese App **nicht** nutzbar. Es wird **kein Scraping**
  und keine inoffizielle API eingesetzt.

---

## 3. Preise — über TCGdex (`pricing.cardmarket`)

- TCGdex liefert Cardmarket-Preise **eingebettet** im Card-Objekt:
  `pricing.cardmarket` mit
  `updated, unit, avg, low, trend, avg1, avg7, avg30`
  sowie Holo-Varianten `avg-holo, low-holo, trend-holo, avg1/7/30-holo`.
- Aktualisierung: **Cardmarket täglich**, TCGPlayer stündlich. Zusätzlich
  `pricing.tcgplayer` (USD) mit low/mid/high/market/directLow.

### Kennzahlen (Auswahl)
| Feld | Bedeutung |
|---|---|
| `avg` | Durchschnittspreis (non-foil) |
| `low` | günstigstes Angebot (non-foil) |
| `trend` | Trendpreis aus Charts |
| `avg1/7/30` | Durchschnitt 1/7/30 Tage |
| `avg-holo` etc. | gleiche Kennzahlen für Foil |

### Regeln für die Anzeige (verbindlich)
- Immer **Quelle** anzeigen: „Cardmarket-Preis, geliefert über TCGdex".
- Immer die **verwendete Kennzahl** benennen (avg/low/trend/…).
- Immer den **Zeitstempel** (`updated`) und die Währung anzeigen.
- Der Preis ist **produktbezogen**: keine Sprache-, Zustands- oder
  Exemplar-Granularität. Nicht als „exakter Marktwert dieses Exemplars"
  darstellen.
- Fehlt ein zuverlässiger Preis: **Hinweis anzeigen**, keinen Preis erfinden.
- Unsichere Zuordnung → `matchQuality` markieren.

---

## 4. Nicht genutzte / geprüfte Alternativen

- **TCGPlayer:** über TCGdex verfügbar (USD). Für eine primär deutschsprachige
  Sammlung sekundär. Optional als zusätzliche Kennzahl.
- **Scraping / inoffizielle APIs:** **nicht** verwenden.

---

## Quellen

- TCGdex API: https://tcgdex.dev/ · https://tcgdex.dev/rest/card
- TCGdex FAQ & Preise: https://tcgdex.dev/faq · https://tcgdex.dev/markets-prices
- TCGdex DB (MIT): https://github.com/tcgdex/cards-database
- Cardmarket/MKM API: https://apiv2.cardmarket.com/ws/documentation
